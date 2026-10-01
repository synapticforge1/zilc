const std = @import("std");
const builtin = @import("builtin");

var signal_received = std.atomic.Value(bool).init(false);
var received_sigint = std.atomic.Value(bool).init(false);

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    var stdout_writer = std.Io.File.stdout().writerStreaming(io, &.{});
    const stdout = &stdout_writer.interface;

    try stdout.print("awaiting signal\n", .{});

    if (builtin.os.tag == .windows) {
        // Windows: use SetConsoleCtrlHandler for Ctrl-C/Ctrl-Break handling
        // zilc: callconv(.C) is spelled .c since 0.14; 0.16 sleeps through Io.sleep, dropped
        // kernel32.SetConsoleCtrlHandler (declared here instead), and made windows.BOOL an enum
        // whose TRUE is BOOL.TRUE.
        const Handler = struct {
            fn handler(ctrl_type: std.os.windows.DWORD) callconv(.c) std.os.windows.BOOL {
                _ = ctrl_type;
                signal_received.store(true, .release);
                received_sigint.store(true, .release);
                return .TRUE;
            }
            extern "kernel32" fn SetConsoleCtrlHandler(
                routine: ?*const fn (std.os.windows.DWORD) callconv(.c) std.os.windows.BOOL,
                add: std.os.windows.BOOL,
            ) callconv(.winapi) std.os.windows.BOOL;
        };
        _ = Handler.SetConsoleCtrlHandler(Handler.handler, .TRUE);

        while (!signal_received.load(.acquire)) {
            try io.sleep(.fromNanoseconds(100_000_000), .awake);
        }

        try stdout.print("\n", .{});
        try stdout.print("interrupt\n", .{});
        try stdout.print("exiting\n", .{});
    } else {
        // Unix: use sigaction to catch SIGINT and SIGTERM
        // zilc: posix.empty_sigset became sigemptyset() and sigaction() stopped returning an
        // error (0.15); 0.16 makes SIG an enum, so handlers take a SIG and compare against .INT.
        var sa = std.posix.Sigaction{
            .handler = .{ .handler = handleSignal },
            .mask = std.posix.sigemptyset(),
            .flags = 0,
        };
        std.posix.sigaction(.INT, &sa, null);
        std.posix.sigaction(.TERM, &sa, null);

        // Wait for a signal
        while (!signal_received.load(.acquire)) {
            try io.sleep(.fromNanoseconds(100_000_000), .awake); // 100ms
        }

        try stdout.print("\n", .{});
        const sig_name = if (received_sigint.load(.acquire)) "interrupt" else "terminated";
        try stdout.print("{s}\n", .{sig_name});
        try stdout.print("exiting\n", .{});
    }
}

fn handleSignal(sig: std.posix.SIG) callconv(.c) void {
    if (sig == .INT) {
        received_sigint.store(true, .release);
    }
    signal_received.store(true, .release);
}
