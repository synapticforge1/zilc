// SPDX-License-Identifier: MIT
//! Lua patterns exactly as Luau matches them — string.find / match / gmatch / gsub — for the Zig
//! port of sarcasm (cmem/sarcasm-port.md, foundation 3). A port of the matcher in Luau's
//! VM/src/lstrlib.cpp (MIT, Roblox; based on Lua 5.x, MIT, PUC-Rio), as vendored in Fil-C 0.687's
//! projects/lute-1.0.0/extern/luau; each function names its C original. Two C details are kept on
//! purpose: the matcher reads one byte past the end of the pattern and of the subject, where C has
//! a NUL (`$`, `%f[...]` at the end, `%b`), and the classes are the C locale's ASCII <ctype.h> tests.
//! Proven against Luau by tools/sarcasm/check-lua-pattern.ts.

const std = @import("std");

pub const max_captures = 32; // LUA_MAXCAPTURES
const max_ccalls = 200; // LUAI_MAXCCALLS: the matchdepth limit ("pattern too complex")
const cap_unfinished: isize = -1;
const cap_position: isize = -2;

pub const Error = error{PatternError};

pub const Capture = union(enum) {
    str: []const u8,
    /// a position capture `()`: 1-based
    pos: usize,
};

const MatchState = struct {
    matchdepth: i32 = max_ccalls,
    src: []const u8,
    pat: []const u8,
    level: usize = 0,
    capture: [max_captures]struct { init: usize = 0, len: isize = 0 } = undefined,
    /// the message of a raised error (luaL_error), for the caller
    msg: []const u8 = "",

    /// `*p` / `*s`, with C's NUL past the end.
    fn pc(ms: *const MatchState, p: usize) u8 {
        return if (p < ms.pat.len) ms.pat[p] else 0;
    }
    fn sc(ms: *const MatchState, s: usize) u8 {
        return if (s < ms.src.len) ms.src[s] else 0;
    }
    fn fail(ms: *MatchState, msg: []const u8) Error {
        ms.msg = msg;
        return error.PatternError;
    }
};

const L_ESC = '%';
const SPECIALS = "^$*+?.([%-";

// <ctype.h> in the C locale.
fn isalpha(c: u8) bool {
    return std.ascii.isAlphabetic(c);
}
fn match_class(c: u8, cl: u8) bool {
    const res = switch (std.ascii.toLower(cl)) {
        'a' => isalpha(c),
        'c' => std.ascii.isControl(c),
        'd' => std.ascii.isDigit(c),
        'g' => c > 0x20 and c < 0x7f,
        'l' => std.ascii.isLower(c),
        'p' => (c > 0x20 and c < 0x7f) and !std.ascii.isAlphanumeric(c),
        's' => c == ' ' or (c >= '\t' and c <= '\r'),
        'u' => std.ascii.isUpper(c),
        'w' => std.ascii.isAlphanumeric(c),
        'x' => std.ascii.isHex(c),
        'z' => c == 0, // deprecated option
        else => return cl == c,
    };
    return if (std.ascii.isLower(cl)) res else !res;
}

/// check_capture.
fn check_capture(ms: *MatchState, l_in: u8) Error!usize {
    const l = @as(i32, l_in) - '1';
    if (l < 0 or l >= ms.level or ms.capture[@intCast(l)].len == cap_unfinished) return ms.fail("invalid capture index");
    return @intCast(l);
}

/// capture_to_close.
fn capture_to_close(ms: *MatchState) Error!usize {
    var level: isize = @as(isize, @intCast(ms.level)) - 1;
    while (level >= 0) : (level -= 1) if (ms.capture[@intCast(level)].len == cap_unfinished) return @intCast(level);
    return ms.fail("invalid pattern capture");
}

/// classend.
fn classend(ms: *MatchState, p_in: usize) Error!usize {
    var p = p_in;
    const c = ms.pc(p);
    p += 1;
    switch (c) {
        L_ESC => {
            if (p == ms.pat.len) return ms.fail("malformed pattern (ends with '%')");
            return p + 1;
        },
        '[' => {
            if (ms.pc(p) == '^') p += 1;
            while (true) { // look for a `]'
                if (p == ms.pat.len) return ms.fail("malformed pattern (missing ']')");
                const x = ms.pc(p);
                p += 1;
                if (x == L_ESC and p < ms.pat.len) p += 1; // skip escapes (e.g. `%]')
                if (ms.pc(p) == ']') break;
            }
            return p + 1;
        },
        else => return p,
    }
}

/// matchbracketclass: `p` at the '[', `ec` at the ']'.
fn matchbracketclass(ms: *const MatchState, c: u8, p_in: usize, ec: usize) bool {
    var p = p_in;
    var sig = true;
    if (ms.pc(p + 1) == '^') {
        sig = false;
        p += 1;
    }
    while (true) {
        p += 1;
        if (p >= ec) break;
        if (ms.pc(p) == L_ESC) {
            p += 1;
            if (match_class(c, ms.pc(p))) return sig;
        } else if (ms.pc(p + 1) == '-' and p + 2 < ec) {
            p += 2;
            if (ms.pc(p - 2) <= c and c <= ms.pc(p)) return sig;
        } else if (ms.pc(p) == c) return sig;
    }
    return !sig;
}

/// singlematch.
fn singlematch(ms: *const MatchState, s: usize, p: usize, ep: usize) bool {
    if (s >= ms.src.len) return false;
    const c = ms.src[s];
    return switch (ms.pc(p)) {
        '.' => true,
        L_ESC => match_class(c, ms.pc(p + 1)),
        '[' => matchbracketclass(ms, c, p, ep - 1),
        else => ms.pc(p) == c,
    };
}

/// matchbalance.
fn matchbalance(ms: *MatchState, s_in: usize, p: usize) Error!?usize {
    if (p + 1 >= ms.pat.len) return ms.fail("malformed pattern (missing arguments to '%b')");
    var s = s_in;
    if (ms.sc(s) != ms.pc(p)) return null;
    const b = ms.pc(p);
    const e = ms.pc(p + 1);
    var cont: i32 = 1;
    while (true) {
        s += 1;
        if (s >= ms.src.len) break;
        if (ms.src[s] == e) {
            cont -= 1;
            if (cont == 0) return s + 1;
        } else if (ms.src[s] == b) cont += 1;
    }
    return null;
}

/// max_expand.
fn max_expand(ms: *MatchState, s: usize, p: usize, ep: usize) Error!?usize {
    var i: usize = 0;
    while (singlematch(ms, s + i, p, ep)) i += 1;
    while (true) {
        if (try match(ms, s + i, ep + 1)) |res| return res;
        if (i == 0) return null;
        i -= 1;
    }
}

/// min_expand.
fn min_expand(ms: *MatchState, s_in: usize, p: usize, ep: usize) Error!?usize {
    var s = s_in;
    while (true) {
        if (try match(ms, s, ep + 1)) |res| return res;
        if (singlematch(ms, s, p, ep)) s += 1 else return null;
    }
}

/// start_capture.
fn start_capture(ms: *MatchState, s: usize, p: usize, what: isize) Error!?usize {
    const level = ms.level;
    if (level >= max_captures) return ms.fail("too many captures");
    ms.capture[level] = .{ .init = s, .len = what };
    ms.level = level + 1;
    const res = try match(ms, s, p);
    if (res == null) ms.level -= 1; // undo capture
    return res;
}

/// end_capture.
fn end_capture(ms: *MatchState, s: usize, p: usize) Error!?usize {
    const l = try capture_to_close(ms);
    ms.capture[l].len = @as(isize, @intCast(s)) - @as(isize, @intCast(ms.capture[l].init));
    const res = try match(ms, s, p);
    if (res == null) ms.capture[l].len = cap_unfinished; // undo capture
    return res;
}

/// match_capture.
fn match_capture(ms: *MatchState, s: usize, l_in: u8) Error!?usize {
    const l = try check_capture(ms, l_in);
    const cap = ms.capture[l];
    const len: usize = @intCast(cap.len);
    if (ms.src.len - s >= len and std.mem.eql(u8, ms.src[cap.init..][0..len], ms.src[s..][0..len])) return s + len;
    return null;
}

/// match: the matcher, with its `goto init` tail calls as a loop.
fn match(ms: *MatchState, s_in: usize, p_in: usize) Error!?usize {
    if (ms.matchdepth == 0) return ms.fail("pattern too complex");
    ms.matchdepth -= 1;
    defer ms.matchdepth += 1;
    var s: ?usize = s_in;
    var p = p_in;
    while (true) {
        if (p == ms.pat.len) return s;
        const si = s.?;
        switch (ms.pc(p)) {
            '(' => return if (ms.pc(p + 1) == ')') try start_capture(ms, si, p + 2, cap_position) else try start_capture(ms, si, p + 1, cap_unfinished),
            ')' => return try end_capture(ms, si, p + 1),
            '$' => if (p + 1 == ms.pat.len) return if (si == ms.src.len) si else null,
            L_ESC => switch (ms.pc(p + 1)) {
                'b' => {
                    s = try matchbalance(ms, si, p + 2);
                    if (s == null) return null;
                    p += 4;
                    continue;
                },
                'f' => {
                    p += 2;
                    if (ms.pc(p) != '[') return ms.fail("missing '[' after '%f' in pattern");
                    const ep = try classend(ms, p);
                    const previous: u8 = if (si == 0) 0 else ms.src[si - 1];
                    if (!matchbracketclass(ms, previous, p, ep - 1) and matchbracketclass(ms, ms.sc(si), p, ep - 1)) {
                        p = ep;
                        continue;
                    }
                    return null;
                },
                '0'...'9' => {
                    s = try match_capture(ms, si, ms.pc(p + 1));
                    if (s == null) return null;
                    p += 2;
                    continue;
                },
                else => {},
            },
            else => {},
        }
        // dflt: a pattern class plus an optional suffix
        const ep = try classend(ms, p);
        const epc = ms.pc(ep);
        if (!singlematch(ms, si, p, ep)) {
            if (epc == '*' or epc == '?' or epc == '-') {
                p = ep + 1;
                continue;
            }
            return null;
        }
        switch (epc) {
            '?' => {
                if (try match(ms, si + 1, ep + 1)) |res| return res;
                p = ep + 1;
                continue;
            },
            '+' => return try max_expand(ms, si + 1, p, ep),
            '*' => return try max_expand(ms, si, p, ep),
            '-' => return try min_expand(ms, si, p, ep),
            else => {
                s = si + 1;
                p = ep;
                continue;
            },
        }
    }
}

/// lmemfind.
fn lmemfind(s1: []const u8, s2: []const u8) ?usize {
    if (s2.len == 0) return 0;
    if (s2.len > s1.len) return null;
    return std.mem.indexOf(u8, s1, s2);
}

/// nospecials: no special character before each NUL (the pattern may contain NULs).
fn nospecials(p: []const u8) bool {
    var it = std.mem.splitScalar(u8, p, 0);
    while (it.next()) |part| if (std.mem.indexOfAny(u8, part, SPECIALS) != null) return false;
    return true;
}

/// posrelat.
fn posrelat(pos: i64, len: usize) i64 {
    if (pos >= 0) return pos;
    if (-pos > @as(i64, @intCast(len))) return 0;
    return @as(i64, @intCast(len)) + pos + 1;
}

pub const Result = struct {
    /// string.find's 1-based start and end (inclusive); string.match leaves them 0
    start: usize = 0,
    end: usize = 0,
    caps: []Capture,
};

/// The captures of a match from `s` to `e` (push_captures): the whole match when there are none.
fn captures(alloc: std.mem.Allocator, ms: *MatchState, s: ?usize, e: usize) ![]Capture {
    const n = if (ms.level == 0 and s != null) 1 else ms.level;
    const out = try alloc.alloc(Capture, n);
    for (out, 0..) |*c, i| c.* = try onecapture(ms, i, s orelse 0, e);
    return out;
}

/// push_onecapture.
fn onecapture(ms: *MatchState, i: usize, s: usize, e: usize) !Capture {
    if (i >= ms.level) {
        if (i == 0) return .{ .str = ms.src[s..e] };
        return ms.fail("invalid capture index");
    }
    const l = ms.capture[i].len;
    if (l == cap_unfinished) return ms.fail("unfinished capture");
    if (l == cap_position) return .{ .pos = ms.capture[i].init + 1 };
    return .{ .str = ms.src[ms.capture[i].init..][0..@intCast(l)] };
}

/// str_find_aux: string.find (find = true) and string.match. `init` is Lua's 1-based (default 1).
fn findAux(alloc: std.mem.Allocator, s: []const u8, p_in: []const u8, init_in: i64, plain: bool, find_: bool, msg: *[]const u8) !?Result {
    var init = posrelat(init_in, s.len);
    if (init < 1) init = 1 else if (init > @as(i64, @intCast(s.len)) + 1) return null;
    const start: usize = @intCast(init - 1);
    if (find_ and (plain or nospecials(p_in))) {
        if (lmemfind(s[start..], p_in)) |off| return .{ .start = start + off + 1, .end = start + off + p_in.len, .caps = &.{} };
        return null;
    }
    var p = p_in;
    const anchor = p.len > 0 and p[0] == '^';
    if (anchor) p = p[1..];
    var ms: MatchState = .{ .src = s, .pat = p };
    var s1 = start;
    while (true) {
        ms.level = 0;
        const res = match(&ms, s1, 0) catch |err| {
            msg.* = ms.msg;
            return err;
        };
        if (res) |e| {
            if (find_) return .{ .start = s1 + 1, .end = e, .caps = try captures(alloc, &ms, null, 0) };
            return .{ .caps = try captures(alloc, &ms, s1, e) };
        }
        const more = s1 < s.len;
        s1 += 1;
        if (!more or anchor) break;
    }
    return null;
}

/// string.find(s, p [, init [, plain]]).
pub fn find(alloc: std.mem.Allocator, s: []const u8, p: []const u8, init: i64, plain: bool) !?Result {
    var msg: []const u8 = "";
    return findAux(alloc, s, p, init, plain, true, &msg);
}

/// string.match(s, p [, init]).
pub fn matchStr(alloc: std.mem.Allocator, s: []const u8, p: []const u8, init: i64) !?[]Capture {
    var msg: []const u8 = "";
    const r = try findAux(alloc, s, p, init, false, false, &msg) orelse return null;
    return r.caps;
}

/// string.gmatch(s, p): the iterator (gmatch_aux).
pub const Gmatch = struct {
    alloc: std.mem.Allocator,
    s: []const u8,
    p: []const u8,
    pos: usize = 0,
    pub fn next(g: *Gmatch) !?[]Capture {
        var ms: MatchState = .{ .src = g.s, .pat = g.p };
        var src = g.pos;
        while (src <= g.s.len) : (src += 1) {
            ms.level = 0;
            if (try match(&ms, src, 0)) |e| {
                g.pos = if (e == src) e + 1 else e;
                return try captures(g.alloc, &ms, src, e);
            }
        }
        g.pos = g.s.len + 1;
        return null;
    }
};
pub fn gmatch(alloc: std.mem.Allocator, s: []const u8, p: []const u8) Gmatch {
    return .{ .alloc = alloc, .s = s, .p = p };
}

/// string.gsub's replacement: a string (with %0-%9 and %%), or a function of the captures that
/// returns the replacement (null keeps the original text).
pub const Repl = union(enum) {
    str: []const u8,
    func: struct { ctx: *anyopaque, f: *const fn (*anyopaque, []const Capture) anyerror!?[]const u8 },
};

/// add_s.
fn addS(out: *std.ArrayList(u8), alloc: std.mem.Allocator, ms: *MatchState, s: usize, e: usize, news: []const u8) !void {
    var i: usize = 0;
    while (i < news.len) : (i += 1) {
        if (news[i] != L_ESC) {
            try out.append(alloc, news[i]);
            continue;
        }
        i += 1; // skip ESC
        const c: u8 = if (i < news.len) news[i] else 0;
        if (!std.ascii.isDigit(c)) {
            if (c != L_ESC) return ms.fail("invalid use of '%' in replacement string");
            try out.append(alloc, c);
        } else if (c == '0') {
            try out.appendSlice(alloc, ms.src[s..e]);
        } else {
            switch (try onecapture(ms, c - '1', s, e)) {
                .str => |x| try out.appendSlice(alloc, x),
                .pos => |n| try out.print(alloc, "{d}", .{n}),
            }
        }
    }
}

pub const GsubResult = struct { text: []u8, n: usize };

/// string.gsub(s, p, repl [, max]) (str_gsub).
pub fn gsub(alloc: std.mem.Allocator, src_in: []const u8, p_in: []const u8, repl: Repl, max: ?usize) !GsubResult {
    var p = p_in;
    const anchor = p.len > 0 and p[0] == '^';
    if (anchor) p = p[1..];
    var ms: MatchState = .{ .src = src_in, .pat = p };
    const max_s = max orelse src_in.len + 1;
    var out: std.ArrayList(u8) = .empty;
    var src: usize = 0;
    var n: usize = 0;
    while (n < max_s) {
        ms.level = 0;
        const e = try match(&ms, src, 0);
        if (e) |end| {
            n += 1;
            switch (repl) {
                .str => |news| try addS(&out, alloc, &ms, src, end, news),
                .func => |fr| {
                    const caps = try captures(alloc, &ms, src, end);
                    if (try fr.f(fr.ctx, caps)) |r| try out.appendSlice(alloc, r) else try out.appendSlice(alloc, src_in[src..end]);
                },
            }
        }
        if (e != null and e.? > src) {
            src = e.?;
        } else if (src < src_in.len) {
            try out.append(alloc, src_in[src]);
            src += 1;
        } else break;
        if (anchor) break;
    }
    try out.appendSlice(alloc, src_in[src..]);
    return .{ .text = out.items, .n = n };
}
