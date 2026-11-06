// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//! n-body: the Benchmarks Game's algorithm (upstream Fil-C runs it as filc/benchmarks/n-body*.c),
//! written in plain Zig for zilc's Zig path. Prints the system's energy before and after N steps.
//!   nbody [N=5000000]

const std = @import("std");

const pi = 3.141592653589793;
const solar_mass = 4.0 * pi * pi;
const days_per_year = 365.24;

const Body = struct { x: f64, y: f64, z: f64, vx: f64, vy: f64, vz: f64, mass: f64 };

fn initialBodies() [5]Body {
    return .{
        .{ .x = 0, .y = 0, .z = 0, .vx = 0, .vy = 0, .vz = 0, .mass = solar_mass }, // sun
        .{ .x = 4.84143144246472090e+00, .y = -1.16032004402742839e+00, .z = -1.03622044471123109e-01, .vx = 1.66007664274403694e-03 * days_per_year, .vy = 7.69901118419740425e-03 * days_per_year, .vz = -6.90460016972063023e-05 * days_per_year, .mass = 9.54791938424326609e-04 * solar_mass }, // jupiter
        .{ .x = 8.34336671824457987e+00, .y = 4.12479856412430479e+00, .z = -4.03523417114321381e-01, .vx = -2.76742510726862411e-03 * days_per_year, .vy = 4.99852801234917238e-03 * days_per_year, .vz = 2.30417297573763929e-05 * days_per_year, .mass = 2.85885980666130812e-04 * solar_mass }, // saturn
        .{ .x = 1.28943695621391310e+01, .y = -1.51111514016986312e+01, .z = -2.23307578892655734e-01, .vx = 2.96460137564761618e-03 * days_per_year, .vy = 2.37847173959480950e-03 * days_per_year, .vz = -2.96589568540237556e-05 * days_per_year, .mass = 4.36624404335156298e-05 * solar_mass }, // uranus
        .{ .x = 1.53796971148509165e+01, .y = -2.59193146099879641e+01, .z = 1.79258772950371181e-01, .vx = 2.68067772490389322e-03 * days_per_year, .vy = 1.62824170038242295e-03 * days_per_year, .vz = -9.51592254519715870e-05 * days_per_year, .mass = 5.15138902046611451e-05 * solar_mass }, // neptune
    };
}

fn offsetMomentum(bodies: []Body) void {
    var px: f64 = 0;
    var py: f64 = 0;
    var pz: f64 = 0;
    for (bodies) |b| {
        px += b.vx * b.mass;
        py += b.vy * b.mass;
        pz += b.vz * b.mass;
    }
    bodies[0].vx = -px / solar_mass;
    bodies[0].vy = -py / solar_mass;
    bodies[0].vz = -pz / solar_mass;
}

fn energy(bodies: []const Body) f64 {
    var e: f64 = 0;
    for (bodies, 0..) |b, i| {
        e += 0.5 * b.mass * (b.vx * b.vx + b.vy * b.vy + b.vz * b.vz);
        for (bodies[i + 1 ..]) |o| {
            const dx = b.x - o.x;
            const dy = b.y - o.y;
            const dz = b.z - o.z;
            e -= b.mass * o.mass / @sqrt(dx * dx + dy * dy + dz * dz);
        }
    }
    return e;
}

fn advance(bodies: []Body, dt: f64) void {
    for (bodies, 0..) |*b, i| {
        for (bodies[i + 1 ..]) |*o| {
            const dx = b.x - o.x;
            const dy = b.y - o.y;
            const dz = b.z - o.z;
            const d2 = dx * dx + dy * dy + dz * dz;
            const mag = dt / (d2 * @sqrt(d2));
            b.vx -= dx * o.mass * mag;
            b.vy -= dy * o.mass * mag;
            b.vz -= dz * o.mass * mag;
            o.vx += dx * b.mass * mag;
            o.vy += dy * b.mass * mag;
            o.vz += dz * b.mass * mag;
        }
    }
    for (bodies) |*b| {
        b.x += dt * b.vx;
        b.y += dt * b.vy;
        b.z += dt * b.vz;
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const args = try std.process.argsAlloc(gpa.allocator());
    defer std.process.argsFree(gpa.allocator(), args);
    const n = if (args.len > 1) try std.fmt.parseInt(u64, args[1], 10) else 5_000_000;

    var out_w = std.fs.File.stdout().writerStreaming(&.{});
    const out = &out_w.interface;
    var bodies = initialBodies();
    offsetMomentum(&bodies);
    try out.print("{d:.9}\n", .{energy(&bodies)});
    var i: u64 = 0;
    while (i < n) : (i += 1) advance(&bodies, 0.01);
    try out.print("{d:.9}\n", .{energy(&bodies)});
}
