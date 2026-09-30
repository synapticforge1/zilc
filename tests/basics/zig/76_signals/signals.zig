const std = @import("std");
const builtin = @import("builtin");

var signal_received = std.atomic.Value(bool).init(false);
var received_sigint = std.atomic.Value(bool).init(false);

pub fn main() !void {
    var stdout_writer = std.fs.File.stdout().writer(&.{});
    const stdout = &stdout_writer.interface;

    try stdout.print("awaiting signal\n", .{});

    if (builtin.os.tag == .windows) {
        // Windows: use SetConsoleCtrlHandler for Ctrl-C/Ctrl-Break handling
        const Handler = struct {
            fn handler(ctrl_type: std.os.windows.DWORD) callconv(.c) std.os.windows.BOOL {
                _ = ctrl_type;
                signal_received.store(true, .release);
                received_sigint.store(true, .release);
                return std.os.windows.TRUE;
            }
        };
        _ = std.os.windows.kernel32.SetConsoleCtrlHandler(Handler.handler, std.os.windows.TRUE);

        while (!signal_received.load(.acquire)) {
            std.Thread.sleep(100_000_000);
        }

        try stdout.print("\n", .{});
        try stdout.print("interrupt\n", .{});
        try stdout.print("exiting\n", .{});
    } else {
        // Unix: use sigaction to catch SIGINT and SIGTERM
        var sa = std.posix.Sigaction{
            .handler = .{ .handler = handleSignal },
            .mask = std.posix.sigemptyset(),
            .flags = 0,
        };
        std.posix.sigaction(std.posix.SIG.INT, &sa, null);
        std.posix.sigaction(std.posix.SIG.TERM, &sa, null);

        // Wait for a signal
        while (!signal_received.load(.acquire)) {
            std.Thread.sleep(100_000_000); // 100ms
        }

        try stdout.print("\n", .{});
        const sig_name = if (received_sigint.load(.acquire)) "interrupt" else "terminated";
        try stdout.print("{s}\n", .{sig_name});
        try stdout.print("exiting\n", .{});
    }
}

fn handleSignal(sig: c_int) callconv(.c) void {
    if (sig == std.posix.SIG.INT) {
        received_sigint.store(true, .release);
    }
    signal_received.store(true, .release);
}
