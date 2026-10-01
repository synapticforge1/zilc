const std = @import("std");

pub fn main() void {
    // defer statements will NOT run when using std.process.exit,
    // just like Go's os.Exit skips deferred functions.
    defer std.debug.print("!\n", .{}); // this will never be printed

    // Exit with status 3
    std.process.exit(3);
}
