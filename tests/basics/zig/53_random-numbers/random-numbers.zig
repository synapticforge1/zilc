// Random values will differ on each run (except seed-42 values which are deterministic).

const std = @import("std");

pub fn main() !void {
    var stdout_writer = std.fs.File.stdout().writerStreaming(&.{}); // zilc: streaming, so redirected output appends like the original
    const stdout = &stdout_writer.interface;

    // Default PRNG seeded with time (non-deterministic)
    var prng = std.Random.DefaultPrng.init(@intCast(std.time.nanoTimestamp()));
    const rand = prng.random();

    // Two random ints in [0,100)
    try stdout.print("{d},{d}\n", .{ rand.intRangeLessThan(u32, 0, 100), rand.intRangeLessThan(u32, 0, 100) });

    // Random float64 in [0.0, 1.0)
    try stdout.print("{d}\n", .{rand.float(f64)});

    // Random floats in [5.0, 10.0)
    try stdout.print("{d},{d}\n", .{
        rand.float(f64) * 5.0 + 5.0,
        rand.float(f64) * 5.0 + 5.0,
    });

    // Time-seeded PRNG (r1)
    var prng1 = std.Random.DefaultPrng.init(@intCast(std.time.nanoTimestamp()));
    const r1 = prng1.random();
    try stdout.print("{d},{d}\n", .{ r1.intRangeLessThan(u32, 0, 100), r1.intRangeLessThan(u32, 0, 100) });

    // Seed 42 (r2) - deterministic
    var prng2 = std.Random.DefaultPrng.init(42);
    const r2 = prng2.random();
    try stdout.print("{d},{d}\n", .{ r2.intRangeLessThan(u32, 0, 100), r2.intRangeLessThan(u32, 0, 100) });

    // Seed 42 again (r3) - same sequence as r2
    var prng3 = std.Random.DefaultPrng.init(42);
    const r3 = prng3.random();
    try stdout.print("{d},{d}", .{ r3.intRangeLessThan(u32, 0, 100), r3.intRangeLessThan(u32, 0, 100) });
}
