// Worker pools distribute jobs across a fixed set of worker threads.

const std = @import("std");

const JobQueue = struct {
    mutex: std.Thread.Mutex = .{},
    cond: std.Thread.Condition = .{},
    jobs: [5]i32 = undefined,
    head: usize = 0,
    tail: usize = 0,
    closed: bool = false,

    fn push(self: *JobQueue, job: i32) void {
        self.mutex.lock();
        defer self.mutex.unlock();
        self.jobs[self.tail] = job;
        self.tail += 1;
        self.cond.signal();
    }

    fn close(self: *JobQueue) void {
        self.mutex.lock();
        defer self.mutex.unlock();
        self.closed = true;
        self.cond.broadcast();
    }

    // Returns null when queue is closed and empty.
    fn pop(self: *JobQueue) ?i32 {
        self.mutex.lock();
        defer self.mutex.unlock();
        while (self.head == self.tail) {
            if (self.closed) return null;
            self.cond.wait(&self.mutex);
        }
        const job = self.jobs[self.head];
        self.head += 1;
        return job;
    }
};

var jobs = JobQueue{};
var results_mutex = std.Thread.Mutex{};
var results_count: usize = 0;
var results_cond = std.Thread.Condition{};

const WorkerArgs = struct { id: usize };

fn worker(args: WorkerArgs) void {
    while (jobs.pop()) |j| {
        std.debug.print("worker {d} started  job {d}\n", .{ args.id, j });
        std.Thread.sleep(1 * std.time.ns_per_s);
        std.debug.print("worker {d} finished job {d}\n", .{ args.id, j });
        results_mutex.lock();
        results_count += 1;
        results_cond.signal();
        results_mutex.unlock();
    }
}

pub fn main() !void {
    const num_jobs: usize = 5;
    const num_workers: usize = 3;

    var threads: [num_workers]std.Thread = undefined;

    for (&threads, 1..) |*t, i| {
        t.* = try std.Thread.spawn(.{}, worker, .{WorkerArgs{ .id = i }});
    }

    for (1..num_jobs + 1) |j| {
        jobs.push(@intCast(j));
    }
    jobs.close();

    // Wait until all results are collected.
    results_mutex.lock();
    while (results_count < num_jobs) {
        results_cond.wait(&results_mutex);
    }
    results_mutex.unlock();

    for (&threads) |*t| {
        t.join();
    }
}
