// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//! `zilc-gen`: the generators Fil-C's runtime build needs, in Zig (the pure-Zig track, Z1;
//! cmem/roadmap.md). Brought from zailc on 2026-10-27 (owner: zailc's build up to a pure-Zig
//! implementation on Linux lives in zilc), faithful to the Fil-C release in `signatures.zig`.
//!
//!   zilc-gen header <out.h>                      write filc_native.h
//!   zilc-gen forwarders <out.c>                  write filc_native_forwarders.c
//!   zilc-gen <path>                              as upstream's Ruby invocation: the path decides
//!                                                 by its basename
//!   zilc-gen musl-headers <musl-src> <out-dir> [arch]
//!                                                 musl's `make install-headers` (yolo-include)
//!   zilc-gen musl-genh <musl-src> <out-dir> [arch]  only musl's generated bits/alltypes.h and
//!                                                 bits/syscall.h (its build's obj/include)
//!   zilc-gen --version                           zilc's version (build.zig.zon), the Zig that
//!                                                 built it, and the Fil-C release its tables are from
const std = @import("std");
const builtin = @import("builtin");
const build_options = @import("build_options");
const forwarders = @import("forwarders.zig");
const musl_headers = @import("musl_headers.zig");
const signatures = @import("signatures.zig");

const usage =
    \\usage: zilc-gen header <out.h>
    \\       zilc-gen forwarders <out.c>
    \\       zilc-gen <path ending in filc_native.h or filc_native_forwarders.c>
    \\       zilc-gen musl-headers <musl-src> <out-dir> [arch=x86_64]
    \\       zilc-gen musl-genh <musl-src> <out-dir> [arch=x86_64]
    \\       zilc-gen --version
    \\
;

/// The first line is exactly `zilc-gen <version>`, the version from build.zig.zon.
const version_text = std.fmt.comptimePrint(
    \\zilc-gen {s}
    \\  built by Zig {s}
    \\  forwarder tables from Fil-C {s} ({s})
    \\
, .{ build_options.version, builtin.zig_version_string, signatures.filc_version, signatures.filc_commit });

const Kind = enum { header, forwarders };

pub fn main() !void {
    const gpa = std.heap.page_allocator;
    const args = try std.process.argsAlloc(gpa);
    if (args.len == 2 and std.mem.eql(u8, args[1], "--version")) {
        try std.fs.File.stdout().writeAll(version_text);
        return;
    }
    if (args.len >= 4 and std.mem.eql(u8, args[1], "musl-headers")) {
        const arch = if (args.len >= 5) args[4] else "x86_64";
        return musl_headers.install(gpa, args[2], args[3], arch);
    }
    if (args.len >= 4 and std.mem.eql(u8, args[1], "musl-genh")) {
        const arch = if (args.len >= 5) args[4] else "x86_64";
        return musl_headers.installGenerated(gpa, args[2], args[3], arch);
    }
    var kind: ?Kind = null;
    var path: []const u8 = "";
    if (args.len == 3) {
        if (std.mem.eql(u8, args[1], "header")) kind = .header;
        if (std.mem.eql(u8, args[1], "forwarders")) kind = .forwarders;
        path = args[2];
    } else if (args.len == 2) {
        if (std.mem.endsWith(u8, args[1], "filc_native.h")) kind = .header;
        if (std.mem.endsWith(u8, args[1], "filc_native_forwarders.c")) kind = .forwarders;
        path = args[1];
    }
    const k = kind orelse {
        std.debug.print(usage, .{});
        std.process.exit(2);
    };
    var out: std.ArrayList(u8) = .empty;
    defer out.deinit(gpa);
    switch (k) {
        .header => try forwarders.writeHeader(&out, gpa),
        .forwarders => try forwarders.writeForwarders(&out, gpa),
    }
    try std.fs.cwd().writeFile(.{ .sub_path = path, .data = out.items });
}
