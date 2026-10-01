const std = @import("std");

const ServerState = enum {
    Idle,
    Connected,
    Error,
    Retrying,

    fn toString(self: ServerState) []const u8 {
        return switch (self) {
            .Idle => "idle",
            .Connected => "connected",
            .Error => "error",
            .Retrying => "retrying",
        };
    }
};

fn transition(s: ServerState) ServerState {
    return switch (s) {
        .Idle => .Connected,
        .Connected, .Retrying => .Idle,
        .Error => .Error,
    };
}

pub fn main() void {
    const ns = transition(.Idle);
    std.debug.print("{s}\n", .{ns.toString()});

    const ns2 = transition(ns);
    std.debug.print("{s}\n", .{ns2.toString()});
}
