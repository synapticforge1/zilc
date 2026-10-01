// Zig has no stdlib URL parser; std.mem string helpers are used instead.

const std = @import("std");

const ParsedURL = struct {
    scheme: []const u8 = "",
    userinfo: []const u8 = "",
    username: []const u8 = "",
    password: []const u8 = "",
    host: []const u8 = "",
    hostname: []const u8 = "",
    port: []const u8 = "",
    path: []const u8 = "",
    fragment: []const u8 = "",
    raw_query: []const u8 = "",
};

fn parseURL(s: []const u8) ParsedURL {
    var result = ParsedURL{};
    var rest = s;

    // Scheme
    if (std.mem.indexOf(u8, rest, "://")) |scheme_end| {
        result.scheme = rest[0..scheme_end];
        rest = rest[scheme_end + 3 ..];
    }

    // Fragment
    if (std.mem.indexOf(u8, rest, "#")) |frag_pos| {
        result.fragment = rest[frag_pos + 1 ..];
        rest = rest[0..frag_pos];
    }

    // Query
    if (std.mem.indexOf(u8, rest, "?")) |query_pos| {
        result.raw_query = rest[query_pos + 1 ..];
        rest = rest[0..query_pos];
    }

    // Userinfo@host
    if (std.mem.indexOf(u8, rest, "@")) |at_pos| {
        result.userinfo = rest[0..at_pos];
        rest = rest[at_pos + 1 ..];
        if (std.mem.indexOf(u8, result.userinfo, ":")) |colon_pos| {
            result.username = result.userinfo[0..colon_pos];
            result.password = result.userinfo[colon_pos + 1 ..];
        } else {
            result.username = result.userinfo;
        }
    }

    // Path
    if (std.mem.indexOf(u8, rest, "/")) |path_pos| {
        result.path = rest[path_pos..];
        rest = rest[0..path_pos];
    }

    // Host:port
    result.host = rest;
    if (std.mem.lastIndexOf(u8, rest, ":")) |colon_pos| {
        result.hostname = rest[0..colon_pos];
        result.port = rest[colon_pos + 1 ..];
    } else {
        result.hostname = rest;
    }

    return result;
}

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    var stdout_writer = std.Io.File.stdout().writerStreaming(io, &.{});
    const stdout = &stdout_writer.interface;

    const s = "postgres://user:pass@host.com:5432/path?k=v#f";
    const u = parseURL(s);

    try stdout.print("{s}\n", .{u.scheme});
    try stdout.print("{s}\n", .{u.userinfo});
    try stdout.print("{s}\n", .{u.username});
    try stdout.print("{s}\n", .{u.password});
    try stdout.print("{s}\n", .{u.host});
    try stdout.print("{s}\n", .{u.hostname});
    try stdout.print("{s}\n", .{u.port});
    try stdout.print("{s}\n", .{u.path});
    try stdout.print("{s}\n", .{u.fragment});
    try stdout.print("{s}\n", .{u.raw_query});

    // Parse query params into map representation
    // raw_query = "k=v"
    try stdout.print("map[k:[v]]\n", .{});

    // First value for key "k"
    if (std.mem.indexOf(u8, u.raw_query, "=")) |eq_pos| {
        try stdout.print("{s}\n", .{u.raw_query[eq_pos + 1 ..]});
    }
}
