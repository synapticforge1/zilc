// Worker pools distribute jobs across a fixed set of worker threads.

const std = @import("std");

// zilc: 0.16 moved Mutex/Condition from std.Thread to std.Io; they block through an Io,
// so the methods take one (Uncancelable: nothing here cancels, and the originals could not fail).
const JobQueue = struct {
    mutex: std.Io.Mutex = .init,
    cond: std.Io.Condition = .init,
    jobs: [5]i32 = undefined,
    head: usize = 0,
    tail: usize = 0,
    closed: bool = false,

    fn push(self: *JobQueue, io: std.Io, job: i32) void {
        self.mutex.lockUncancelable(io);
        defer self.mutex.unlock(io);
        self.jobs[self.tail] = job;
        self.tail += 1;
        self.cond.signal(io);
    }

    fn close(self: *JobQueue, io: std.Io) void {
        self.mutex.lockUncancelable(io);
        defer self.mutex.unlock(io);
        self.closed = true;
        self.cond.broadcast(io);
    }

    // Returns null when queue is closed and empty.
    fn pop(self: *JobQueue, io: std.Io) ?i32 {
        self.mutex.lockUncancelable(io);
        defer self.mutex.unlock(io);
        while (self.head == self.tail) {
            if (self.closed) return null;
            self.cond.waitUncancelable(io, &self.mutex);
        }
        const job = self.jobs[self.head];
        self.head += 1;
        return job;
    }
};

var jobs = JobQueue{};
var results_mutex: std.Io.Mutex = .init;
var results_count: usize = 0;
var results_cond: std.Io.Condition = .init;

const WorkerArgs = struct { id: usize };

fn worker(io: std.Io, args: WorkerArgs) void {
    while (jobs.pop(io)) |j| {
        std.debug.print("worker {d} started  job {d}\n", .{ args.id, j });
        // zilc: 0.16 removed std.time.sleep / std.Thread.sleep; sleeping goes through Io.sleep.
        io.sleep(.fromNanoseconds(1 * std.time.ns_per_s), .awake) catch {};
        std.debug.print("worker {d} finished job {d}\n", .{ args.id, j });
        results_mutex.lockUncancelable(io);
        results_count += 1;
        results_cond.signal(io);
        results_mutex.unlock(io);
    }
}

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const num_jobs: usize = 5;
    const num_workers: usize = 3;

    var threads: [num_workers]std.Thread = undefined;

    for (&threads, 1..) |*t, i| {
        t.* = try std.Thread.spawn(.{}, worker, .{ io, WorkerArgs{ .id = i } });
    }

    for (1..num_jobs + 1) |j| {
        jobs.push(io, @intCast(j));
    }
    jobs.close(io);

    // Wait until all results are collected.
    results_mutex.lockUncancelable(io);
    while (results_count < num_jobs) {
        results_cond.waitUncancelable(io, &results_mutex);
    }
    results_mutex.unlock(io);

    for (&threads) |*t| {
        t.join();
    }
}
