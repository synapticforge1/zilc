// SPDX-License-Identifier: MIT
//! Luau's table — the same array part, hash part, main positions, free pointer, rehash and array
//! sizing, so that `for k, v in t` visits keys in EXACTLY Luau's order. sarcasm's output depends on
//! that order for integer-keyed tables (cmem/sarcasm-port.md, foundation 1), so the Zig port of
//! sarcasm keeps such tables in this structure instead of a Zig hash map.
//!
//! A port of Luau's VM/src/ltable.cpp (MIT, Roblox; based on Lua 5.x, MIT, PUC-Rio), as vendored in
//! Fil-C 0.687's projects/lute-1.0.0/extern/luau — the Luau minilute runs upstream's sarcasm on.
//! Each function names its C original. Kept: number, string and boolean keys (sarcasm keys by
//! nothing else where order matters; table-identity keys hash by address, which upstream itself
//! never lets reach its output). Proven against Luau by tools/sarcasm/check-luau-table.ts.

const std = @import("std");

pub const Key = union(enum) {
    num: f64,
    str: []const u8,
    boolean: bool,

    fn eql(a: Key, b: Key) bool {
        return switch (a) {
            .num => |x| b == .num and x == b.num, // luai_numeq: raw ==, so -0 == 0
            .str => |x| b == .str and std.mem.eql(u8, x, b.str),
            .boolean => |x| b == .boolean and x == b.boolean,
        };
    }
};

const MAXBITS = 26;
const MAXSIZE: i32 = 1 << MAXBITS;

/// luai_num2int: a C `(int)d`, which on x86-64 is cvttsd2si: INT_MIN when out of range or NaN.
fn num2int(d: f64) i32 {
    if (!(d > -2147483649.0 and d < 2147483648.0)) return std.math.minInt(i32);
    return @intFromFloat(@trunc(d));
}

/// arrayindex: the key as an array index if it is an integral number, else -1.
fn arrayindex(key: f64) i32 {
    const i = num2int(key);
    return if (@as(f64, @floatFromInt(i)) == key) i else -1;
}

/// ceillog2 (luaO_log2(x - 1) + 1).
fn ceillog2(x: u32) u5 {
    if (x <= 1) return 0;
    return @intCast(32 - @clz(x - 1));
}

/// luaS_hash: Luau's string hash (lstring.cpp).
pub fn stringHash(s: []const u8) u32 {
    var a: u32 = 0;
    var b: u32 = 0;
    var h: u32 = @truncate(s.len);
    var str = s;
    var len = s.len;
    while (len >= 32) {
        const rol = struct {
            fn f(x: u32, n: u5) u32 {
                return std.math.rotr(u32, x, n);
            }
        }.f;
        a +%= std.mem.readInt(u32, str[0..4], .little);
        b +%= std.mem.readInt(u32, str[4..8], .little);
        h +%= std.mem.readInt(u32, str[8..12], .little);
        // mix(14, 11, 25)
        a ^= h;
        a -%= rol(h, 14);
        b ^= a;
        b -%= rol(a, 11);
        h ^= b;
        h -%= rol(b, 25);
        str = str[12..];
        len -= 12;
    }
    var i = len;
    while (i > 0) : (i -= 1) h ^= (h << 5) +% (h >> 2) +% str[i - 1];
    return h;
}

/// hashnum's 32-bit result (MurmurHash64B finalizer over the double's two words, sign masked).
fn hashNum(n: f64) u32 {
    const bits: u64 = @bitCast(n);
    var h1: u32 = @truncate(bits);
    var h2: u32 = @as(u32, @truncate(bits >> 32)) & 0x7fffffff;
    const m: u32 = 0x5bd1e995;
    h1 ^= h2 >> 18;
    h1 *%= m;
    h2 ^= h1 >> 22;
    h2 *%= m;
    h1 ^= h2 >> 17;
    h1 *%= m;
    h2 ^= h1 >> 19;
    h2 *%= m;
    return h2;
}

pub fn Table(comptime V: type) type {
    return struct {
        const Self = @This();
        const Node = struct { key: ?Key = null, val: ?V = null, next: i32 = 0 };

        alloc: std.mem.Allocator,
        array: []?V = &.{},
        /// The hash part; empty means Luau's shared `dummynode` (one nil node, sizenode 1).
        node: []Node = &.{},
        lsizenode: u5 = 0,
        /// The union { lastfree; aboundary } of LuaTable: a free position is before `lastfree`,
        /// and a negative value is a cached array boundary (negated).
        lastfree: i32 = 0,

        /// luaH_new(narray, nhash).
        pub fn init(alloc: std.mem.Allocator, narray: i32, nhash: i32) !Self {
            var t: Self = .{ .alloc = alloc };
            if (narray > 0) try t.setarrayvector(narray);
            if (nhash > 0) try t.setnodevector(nhash);
            return t;
        }

        pub fn deinit(t: *Self) void {
            t.alloc.free(t.array);
            if (t.node.len != 0) t.alloc.free(t.node);
        }

        fn isDummy(t: *const Self) bool {
            return t.node.len == 0;
        }
        fn sizenode(t: *const Self) i32 {
            return @as(i32, 1) << t.lsizenode;
        }
        fn sizearray(t: *const Self) i32 {
            return @intCast(t.array.len);
        }
        /// The node at index i (the dummy for an empty hash part).
        fn gnode(t: *Self, i: i32) *Node {
            if (t.isDummy()) return &dummy;
            return &t.node[@intCast(i)];
        }
        var dummy: Node = .{};

        fn mainposition(t: *Self, key: Key) i32 {
            const h: u32 = switch (key) {
                .num => |n| hashNum(n),
                .str => |s| stringHash(s),
                .boolean => |b| @intFromBool(b),
            };
            return @intCast(h & @as(u32, @intCast(t.sizenode() - 1)));
        }

        fn setarrayvector(t: *Self, size: i32) !void {
            if (size > MAXSIZE) return error.TableOverflow;
            const old = t.array.len;
            t.array = try t.alloc.realloc(t.array, @intCast(size));
            for (t.array[old..]) |*v| v.* = null;
        }

        fn setnodevector(t: *Self, size_in: i32) !void {
            if (size_in == 0) {
                t.node = &.{};
                t.lsizenode = 0;
                t.lastfree = 0;
                return;
            }
            const lsize = ceillog2(@intCast(size_in));
            if (lsize > MAXBITS) return error.TableOverflow;
            const size = @as(usize, 1) << lsize;
            t.node = try t.alloc.alloc(Node, size);
            for (t.node) |*n| n.* = .{};
            t.lsizenode = lsize;
            t.lastfree = @intCast(size); // all positions are free
        }

        /// countint / numusearray / numusehash / computesizes (the rehash census).
        fn countint(key: f64, nums: *[MAXBITS + 1]i32) i32 {
            const k = arrayindex(key);
            if (0 < k and k <= MAXSIZE) {
                nums[ceillog2(@intCast(k))] += 1;
                return 1;
            }
            return 0;
        }

        fn numusearray(t: *Self, nums: *[MAXBITS + 1]i32) i32 {
            var ause: i32 = 0;
            var i: i32 = 1;
            var lg: u5 = 0;
            var ttlg: i32 = 1;
            while (lg <= MAXBITS) : ({
                lg += 1;
                ttlg *= 2;
            }) {
                var lc: i32 = 0;
                var lim = ttlg;
                if (lim > t.sizearray()) {
                    lim = t.sizearray();
                    if (i > lim) break;
                }
                while (i <= lim) : (i += 1) {
                    if (t.array[@intCast(i - 1)] != null) lc += 1;
                }
                nums[lg] += lc;
                ause += lc;
                if (lg == MAXBITS) break;
            }
            return ause;
        }

        fn numusehash(t: *Self, nums: *[MAXBITS + 1]i32, pnasize: *i32) i32 {
            var totaluse: i32 = 0;
            var ause: i32 = 0;
            var i = t.sizenode();
            while (i > 0) {
                i -= 1;
                const n = t.gnode(i);
                if (n.val != null) {
                    if (n.key.? == .num) ause += countint(n.key.?.num, nums);
                    totaluse += 1;
                }
            }
            pnasize.* += ause;
            return totaluse;
        }

        fn computesizes(nums: *[MAXBITS + 1]i32, narray: *i32) i32 {
            var a: i32 = 0;
            var na: i32 = 0;
            var n: i32 = 0;
            var i: usize = 0;
            var twotoi: i32 = 1;
            while (@divTrunc(twotoi, 2) < narray.*) : ({
                i += 1;
                twotoi *= 2;
            }) {
                if (nums[i] > 0) {
                    a += nums[i];
                    if (a > @divTrunc(twotoi, 2)) {
                        n = twotoi;
                        na = a;
                    }
                }
                if (a == narray.*) break;
            }
            narray.* = n;
            return na;
        }

        /// arrayornewkey.
        fn arrayornewkey(t: *Self, key: Key) !*?V {
            if (key == .num) {
                const k = num2int(key.num);
                if (@as(f64, @floatFromInt(k)) == key.num and @as(u32, @bitCast(k)) -% 1 < @as(u32, @intCast(t.sizearray()))) return &t.array[@intCast(k - 1)];
            }
            return t.newkey(key);
        }

        /// resize(nasize, nhsize).
        fn resize(t: *Self, nasize: i32, nhsize: i32) !void {
            if (nasize > MAXSIZE or nhsize > MAXSIZE) return error.TableOverflow;
            const oldasize = t.sizearray();
            const oldnode = t.node;
            const olddummy = t.isDummy();
            const oldhsize: i32 = if (olddummy) 1 else @intCast(oldnode.len);
            if (nasize > oldasize) try t.setarrayvector(nasize);
            try t.setnodevector(nhsize);
            if (nasize < oldasize) {
                // shrink: re-insert the vanishing slice
                const keep = t.array;
                t.array = keep[0..@intCast(nasize)];
                var i = nasize;
                while (i < oldasize) : (i += 1) {
                    if (keep[@intCast(i)]) |v| (try t.newkey(.{ .num = @floatFromInt(i + 1) })).* = v;
                }
                t.array = try t.alloc.realloc(keep, @intCast(nasize));
            }
            var i = oldhsize - 1;
            while (i >= 0) : (i -= 1) {
                if (olddummy) break;
                const old = oldnode[@intCast(i)];
                if (old.val) |v| (try t.arrayornewkey(old.key.?)).* = v;
            }
            if (!olddummy) t.alloc.free(oldnode);
        }

        /// adjustasize.
        fn adjustasize(t: *Self, size_in: i32, ek: ?Key) i32 {
            var size = size_in;
            const tbound = !t.isDummy() or size < t.sizearray();
            const ekindex: i32 = if (ek) |k| (if (k == .num) arrayindex(k.num) else -1) else -1;
            while (size + 1 == ekindex or (tbound and t.getnum(size + 1) != null)) size += 1;
            return size;
        }

        /// rehash(ek).
        fn rehash(t: *Self, ek: Key) !void {
            var nums = [_]i32{0} ** (MAXBITS + 1);
            var nasize = t.numusearray(&nums);
            var totaluse = nasize;
            totaluse += t.numusehash(&nums, &nasize);
            if (ek == .num) nasize += countint(ek.num, &nums);
            totaluse += 1;
            const na = computesizes(&nums, &nasize);
            var nh = totaluse - na;
            const nadjusted = t.adjustasize(nasize, ek);
            const aextra = nadjusted - nasize;
            if (aextra != 0) {
                nh -= aextra;
                nasize = nadjusted + aextra;
                nasize = t.adjustasize(nasize, ek);
            }
            try t.resize(nasize, nh);
        }

        /// getfreepos.
        fn getfreepos(t: *Self) ?i32 {
            while (t.lastfree > 0) {
                t.lastfree -= 1;
                if (t.gnode(t.lastfree).key == null) return t.lastfree;
            }
            return null;
        }

        /// newkey: Brent's variation, as Luau has it.
        fn newkey(t: *Self, key: Key) error{ OutOfMemory, TableOverflow }!*?V {
            // enforce the boundary invariant
            if (key == .num and key.num == @as(f64, @floatFromInt(t.sizearray() + 1))) {
                try t.rehash(key);
                return t.arrayornewkey(key);
            }
            var mp = t.mainposition(key);
            if (t.gnode(mp).val != null or t.isDummy()) {
                const n = t.getfreepos() orelse {
                    try t.rehash(key);
                    return t.arrayornewkey(key);
                };
                const mk = t.gnode(mp).key.?;
                var othern = t.mainposition(mk);
                if (othern != mp) {
                    // the colliding node is out of its main position: move it to the free one
                    while (othern + t.gnode(othern).next != mp) othern += t.gnode(othern).next;
                    t.gnode(othern).next = n - othern;
                    t.gnode(n).* = t.gnode(mp).*;
                    if (t.gnode(mp).next != 0) {
                        t.gnode(n).next += mp - n;
                        t.gnode(mp).next = 0;
                    }
                    t.gnode(mp).val = null;
                } else {
                    // the colliding node is in its own main position: the new key goes to the free one
                    if (t.gnode(mp).next != 0) t.gnode(n).next = (mp + t.gnode(mp).next) - n;
                    t.gnode(mp).next = n - mp;
                    mp = n;
                }
            }
            t.gnode(mp).key = key;
            return &t.gnode(mp).val;
        }

        /// luaH_getnum.
        pub fn getnum(t: *Self, key: i32) ?V {
            if (@as(u32, @bitCast(key)) -% 1 < @as(u32, @intCast(t.sizearray()))) return t.array[@intCast(key - 1)];
            if (t.isDummy()) return null;
            const nk: f64 = @floatFromInt(key);
            return t.find(.{ .num = nk });
        }

        fn find(t: *Self, key: Key) ?V {
            if (t.findSlot(key)) |s| return s.*;
            return null;
        }

        fn findSlot(t: *Self, key: Key) ?*?V {
            if (key == .num) {
                const k = num2int(key.num);
                if (@as(f64, @floatFromInt(k)) == key.num and @as(u32, @bitCast(k)) -% 1 < @as(u32, @intCast(t.sizearray()))) return &t.array[@intCast(k - 1)];
            }
            if (t.isDummy()) return null;
            var n = t.mainposition(key);
            while (true) {
                const nd = t.gnode(n);
                if (nd.key) |k| if (Key.eql(k, key)) return &nd.val;
                if (nd.next == 0) return null;
                n += nd.next;
            }
        }

        /// luaH_get.
        pub fn get(t: *Self, key: Key) ?V {
            return t.find(key);
        }

        /// `t[key] = v` (v null: `t[key] = nil`): luaH_set, then the store — which, as in Luau's
        /// VM, creates the key even when the value stored is nil.
        pub fn set(t: *Self, key: Key, v: ?V) !void {
            if (key == .num and std.math.isNan(key.num)) return error.NanIndex;
            const slot = t.findSlot(key) orelse try t.newkey(key);
            slot.* = v;
        }

        /// luaH_setnum then a store (lua_rawseti).
        pub fn setnum(t: *Self, key: i32, v: ?V) !void {
            if (@as(u32, @bitCast(key)) -% 1 < @as(u32, @intCast(t.sizearray()))) {
                t.array[@intCast(key - 1)] = v;
                return;
            }
            const slot = t.findSlot(.{ .num = @floatFromInt(key) }) orelse try t.newkey(.{ .num = @floatFromInt(key) });
            slot.* = v;
        }

        // ---- the length operator (luaH_getn), with its cached boundary in the lastfree union
        fn maybesetaboundary(t: *Self, boundary: i32) void {
            if (t.lastfree <= 0) t.lastfree = -boundary;
        }
        fn getaboundary(t: *Self) i32 {
            return if (t.lastfree < 0) -t.lastfree else t.sizearray();
        }
        fn updateaboundary(t: *Self, boundary: i32) i32 {
            const sa = t.sizearray();
            if (boundary < sa and t.array[@intCast(boundary - 1)] == null) {
                if (boundary >= 2 and t.array[@intCast(boundary - 2)] != null) {
                    t.maybesetaboundary(boundary - 1);
                    return boundary - 1;
                }
            } else if (boundary + 1 < sa and t.array[@intCast(boundary)] != null and t.array[@intCast(boundary + 1)] == null) {
                t.maybesetaboundary(boundary + 1);
                return boundary + 1;
            }
            return 0;
        }

        /// luaH_getn: `#t`.
        pub fn len(t: *Self) i32 {
            const sa = t.sizearray();
            const boundary = t.getaboundary();
            if (boundary > 0) {
                if (t.array[@intCast(sa - 1)] != null and t.isDummy()) return sa;
                if (boundary < sa and t.array[@intCast(boundary - 1)] != null and t.array[@intCast(boundary)] == null) return boundary;
                const found = t.updateaboundary(boundary);
                if (found > 0) return found;
            }
            const j = sa;
            if (j > 0 and t.array[@intCast(j - 1)] == null) {
                var base: i32 = 0;
                var rest = j;
                while (true) {
                    const half = rest >> 1;
                    if (half == 0) break;
                    if (t.array[@intCast(base + half)] != null) base += half;
                    rest -= half;
                }
                const b = @as(i32, @intFromBool(t.array[@intCast(base)] != null)) + base;
                t.maybesetaboundary(b);
                return b;
            }
            return j;
        }

        // ---- table library (ltablib.cpp), the parts sarcasm uses
        /// table.insert(t, v).
        pub fn append(t: *Self, v: V) !void {
            try t.setnum(t.len() + 1, v);
        }

        /// moveelements (ltablib.cpp) within one table: (f..e) to (to..). All inside the array
        /// part: direct copies; else lua_rawgeti / lua_rawseti one by one, whose stores can
        /// rehash, so the direction is upstream's: increasing when `to > e or to <= f`.
        fn moveelements(t: *Self, f: i32, e: i32, to: i32) !void {
            const n = e - f + 1;
            const sa: u32 = @intCast(t.sizearray());
            const u = struct {
                fn cast(x: i32) u32 {
                    return @bitCast(x);
                }
            }.cast;
            const increasing = to > e or to <= f;
            if (u(f) -% 1 < sa and u(to) -% 1 < sa and u(f) -% 1 +% u(n) <= sa and u(to) -% 1 +% u(n) <= sa) {
                if (increasing) {
                    var i: i32 = 0;
                    while (i < n) : (i += 1) t.array[@intCast(to + i - 1)] = t.array[@intCast(f + i - 1)];
                } else {
                    var i = n - 1;
                    while (i >= 0) : (i -= 1) t.array[@intCast(to + i - 1)] = t.array[@intCast(f + i - 1)];
                }
                return;
            }
            if (increasing) {
                var i: i32 = 0;
                while (i < n) : (i += 1) try t.setnum(to + i, t.getnum(f + i));
            } else {
                var i = n - 1;
                while (i >= 0) : (i -= 1) try t.setnum(to + i, t.getnum(f + i));
            }
        }

        /// table.insert(t, pos, v) (tinsert's 3-argument case).
        pub fn insertAt(t: *Self, pos: i32, v: V) !void {
            const n = t.len();
            if (1 <= pos and pos <= n) try t.moveelements(pos, n, pos + 1);
            try t.setnum(pos, v);
        }

        /// table.remove(t [, pos]) (tremove): nothing outside 1..n; else t[pos], the move down,
        /// and t[n] = nil.
        pub fn remove(t: *Self, pos_in: ?i32) !?V {
            const n = t.len();
            const pos = pos_in orelse n;
            if (!(1 <= pos and pos <= n)) return null;
            const v = t.getnum(pos);
            try t.moveelements(pos + 1, n, pos);
            try t.setnum(n, null);
            return v;
        }

        // ---- traversal in luaH_next's order: the array part, then the hash nodes by index
        pub const Entry = struct { key: Key, val: V };
        pub const Iterator = struct {
            t: *Self,
            i: i32 = 0,
            pub fn next(it: *Iterator) ?Entry {
                const sa = it.t.sizearray();
                while (it.i < sa) {
                    const i = it.i;
                    it.i += 1;
                    if (it.t.array[@intCast(i)]) |v| return .{ .key = .{ .num = @floatFromInt(i + 1) }, .val = v };
                }
                while (it.i - sa < it.t.sizenode()) {
                    const n = it.t.gnode(it.i - sa);
                    it.i += 1;
                    if (n.val) |v| return .{ .key = n.key.?, .val = v };
                }
                return null;
            }
        };
        pub fn iterator(t: *Self) Iterator {
            return .{ .t = t };
        }
    };
}
