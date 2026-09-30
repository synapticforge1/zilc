# tests/basics — a corpus of correct programs, in C and in Zig

156 small programs, the same 78 lessons written once in C and once in Zig ("hello world" through
threads, JSON, files, processes, HTTP and signals). The safety gate proves that **bugs trap**. This
corpus proves the opposite: **correct programs build and run under zilc without false traps**, and
it gives size and speed numbers against plain Zig.

| folder | contents | builds with |
| --- | --- | --- |
| `c/` | the C lessons | `zig cc -lc` (Zig 0.15.2), and zilc |
| `zig/` | the Zig lessons, **converted to Zig 0.15.2** | Zig 0.15.2 with `-lc`, and zilc |
| `zig-0.16.2/` | the Zig lessons, being converted to **Zig 0.16.0** (the folder will be renamed `zig-0.16.0`) | Zig 0.16.0, for the future 0.16 line |

## Where they come from, and the licence

Copied 2026-09-30 from the owner's repositories, source files only:

| | repository | commit |
| --- | --- | --- |
| C | https://github.com/jrmarcum/BasicsOfCodingC | `0503871a87ef7d5f80f1ade1e5d653fe7bae1299` |
| Zig | https://github.com/jrmarcum/BasicsOfCodingZig | `d85cc5f7ac19232b240bf890dcd1b915449de789` |

The lesson code derives, via "Basics of Coding Go", from **"Go by Example" by Mark McGranaghan**,
licensed **CC BY 3.0**. See `c/NOTICE` and `zig/NOTICE`, copied verbatim, which carry the
attribution. The owner's own contributions are CC0 (`LICENSE`). Ledger entry:
`third_party/LICENSES.md`. These files are **tests only**; nothing here is linked into zilc or into
programs it builds.

## What was changed, and why

Every non-obvious change carries a `zilc:` comment in the file.

**C: 5 files, all portability bugs** in branches that had never been built on Linux (each has a
`_WIN32` branch that did build). The Windows builds still compile.

| file | fix |
| --- | --- |
| `28_channels`, `29_select`, `30_timeouts` | the Win32 branch defines a one-argument `sem_init(s)` and the POSIX branch didn't match it. Added a matching wrapper: not shared between processes, initial count 0, as the Win32 `CreateSemaphore` |
| `63_temporary-files-and-directories` | `#include <unistd.h>` for `rmdir` |
| `76_signals` | `#include <time.h>` for `nanosleep`, and `<windows.h>` for `Sleep` on Windows |

**Zig → 0.15.2: 60 of 78 files.** The originals were written for Zig 0.13/0.14.

| change | files |
| --- | --- |
| `std.io.getStdOut().writer()` → `std.fs.File.stdout().writer(&.{})` + `.interface` (**unbuffered**, as before, so no flush is needed) | 54 |
| same for `getStdErr` | 2 |
| `std.time.sleep` → `std.Thread.sleep` | 9 |
| `std.ArrayList(T).init(a)` → `std.array_list.Managed(T).init(a)` (keeps the managed API) | 7 |
| `@typeInfo` tags lowercased (`.Pointer` → `.pointer`) | 1 |
| `std.rand` → `std.Random`; `std.fmt.fmtSliceHexLower` → `bytesToHex` / `{x}`; `allocPrintZ` → `allocPrintSentinel`; `callconv(.C)` → `.c`; `json.stringifyAlloc` → `json.Stringify.valueAlloc` | 1–2 each |
| signed `%` → `@mod` (`year` is `i32`) | 3 |
| a named `Entry` type (each `struct {…}` literal is now a distinct type) | 1 |
| `std.c.setenv` → an `extern "c"` declaration | 1 |
| maps serialised through `std.json.ArrayHashMap` | 1 |
| readers/writers with caller-supplied buffers: `58_reading-files` (`peek`), `59_writing-files` (**`writerStreaming`**, which appends as the original did; plain `writer()` would overwrite from offset 0), `60_line-filters`, `75_spawning-processes` | 4 |
| HTTP: `http.Client` → `request`/`sendBodiless`/`receiveHead` (compression off, so the body stays text); `http.Server` over a stream reader/writer pair | 3 |

## Tools

| script | what it does |
| --- | --- |
| `tools/basics/compile-check.sh` | compile + link every example for `x86_64-linux-musl` with plain Zig 0.15.2 and `-lc` (Git Bash on Windows) |
| `tools/basics/run-native.sh` | build and **run** every example on Linux with plain Zig (WSL): the behaviour baseline |
| `tools/basics/size-compare.sh` | Zig ReleaseSmall vs ReleaseSafe vs zilc: binary sizes, and whether zilc's build runs like the plain one |

**Examples that don't exit 0 by design:** `42_panic` (aborts, 134), `66_command-line-subcommands`
(exits 1 without a subcommand argument), `77_exit` (exits 3). Servers `70`–`72` wait for connections,
and `76_signals` waits for a signal; the runners time them out.
