# Zig ports: one file per move to a new Zig line

**Purpose (owner, 2026-09-30):** every time zilc moves to a new Zig release, record what changed
and how it was fixed, so the next port reads the notes instead of rediscovering them. With notes
from the `0.16.1-1` port, `0.16.2-1` should go faster. How lines, bases and versions work:
`../releasing.md` "Two kinds of line". The procedure: `../upstream.md` stage B.

**Layout (owner, 2026-09-30):** these files live on **`main`** with the rest of `cmem/`, one per new
line, **named by the line's first release**: `ports/0.16.2-1.md`. Later changes carried to that
line are appended to the same file, each with the release it produced and its new basis.

⚠️ **Every Zig move must re-check zilc's std patch sets** (`src/stdpatch.zig`, KI-11). A patch set is
keyed by exact Zig version and verifies the original text, so a new Zig without a patch set simply
gets **no overlay**. That is correct only if upstream fixed the issue in that version (0.16.0 did for
Z-1). For each new version: check that every patched behaviour is fixed upstream, and if not, write
a patch set for it.

**Per file:** the new line and its **basis**, the Zig versions from → to, each API change with its
fix and the sites it touched, anything that surprised us, and how long it took. Copy the template
below.

The version-sensitive surface is listed in `../design-decisions.md` invariant 4, with a baseline of
about 31 std sites plus `build.zig` (2026-09-30). Re-count it after each port.

---

## 🔭 Scouting, 2026-09-30. NOT a port: zilc stays on 0.15.2 until there is a stable base (owner)

A 0.16.0 trial port was started in a throwaway checkout and **stopped on the owner's word**. The
checkout and its caches were removed. The facts gathered are kept for when the port is due:

| fact | value |
| --- | --- |
| latest Zig release | **0.16.0** (no 0.16.1 yet); master is `0.17.0-dev.2338` (2026-09-29) |
| Zig 0.16.0's LLVM | **clang 21.1.0**, so it is a real two-Zig split: 0.16.0 could build zilc, but user code still needs 0.15.2 |
| Fil-C latest release | **0.685** (2026-09-16), the one in use. **It ships `linux-aarch64` builds too**, which answers a P6 unknown |
| Fil-C `deluge` head | `14a3ce9` (2026-09-30), **still LLVM 20.1.8**. Stage A would change nothing today |
| `build.zig` under 0.16.0 | **compiles unchanged**: the build runner ran |
| first source error | `src/main.zig:56`: `std.process.argsAlloc` is gone. 0.16 passes `main(init: std.process.Init)` and args come from `init.minimal.args.toSlice(arena)` |
| the 0.16 idioms to use | wazmrt's `src/main.zig`: `init.io`, `Io.Dir.cwd().readFileAlloc(io, path, arena, .limited(n))`, `Io.Dir.cwd().writeFile(io, …)`, `std.ArrayList(T) = .empty` |

### What 0.16 changes, from converting 78 example programs to it (2026-09-30)

`tests/basics/zig-0.16.0/` was converted from 0.13/0.14-era code to **0.16.0**, building 78/78 for
Linux and Windows. That gives the list zilc's own 0.15.2 → 0.16 port will meet, with file counts
from that corpus:

| change | files |
| --- | --- |
| **`pub fn main(init: std.process.Init)`**, `const io = init.io` | 64 |
| stdio: `std.Io.File.stdout().writerStreaming(io, &.{})` + `.interface` (stderr and stdin alike) | 54 + 2 + 1 |
| `GeneralPurposeAllocator(.{}){}` → `DebugAllocator(.{}) = .init` | 27 |
| **`io` threaded into helpers and thread entry points**; `Thread.spawn` args carry `io` | 12 / 9 |
| `std.Thread.Mutex`/`Condition` → **`std.Io.Mutex`/`Condition`** (`lockUncancelable(io)`, `unlock(io)`, `waitUncancelable(io, &m)`); `timedWait` → `Io.Event` + `waitTimeout` | 5 / 4 / 1 |
| `std.time.sleep(ns)` → `io.sleep(.fromNanoseconds(ns), .awake)` | 9 |
| clocks → `std.Io.Timestamp.now(io, .real)` (`.nanoseconds`, `.toSeconds()`, `.toMilliseconds()`) | 8 |
| **`std.fs` → `std.Io.Dir`**, and every call takes `io` (`openFile`, `createFile`, `writeFile`, `readFileAlloc(io, p, a, .limited(n))`, `statFile`, `openDir`, `iterate().next(io)`, `deleteTree`, `close(io)`); `makeDir` → `createDir(io, p, .default_dir)`, `makePath` → `createDirPath`; `*Absolute` variants move to `Io.Dir` | 6 |
| `File.read`/`seekTo` → a `File.Reader`; `bufferedReader`/`bufferedWriter` → `reader`/`writerStreaming(io, &buf)`; `sync(io)` | 5 |
| `std.io.fixedBufferStream` → `std.Io.Writer.fixed(&buf)` | 1 |
| **args**: `init.minimal.args.toSlice(arena)`; **env**: `Environ.getAlloc` / `Environ.createMap`; `changeCurDir` → `setCurrentPath(io, …)` | 3 / 2 / 1 |
| `std.fs.path.relative` gains `cwd` + `environ_map` args | 1 |
| **processes**: `std.process.spawn(io, .{ .argv, .stdout = .pipe })` + `wait(io)`; `Term` tags lowercase; `execveZ` gone → `std.c.execve` | 2 |
| **net**: `std.net` → `std.Io.net` (`IpAddress.parse`, `listen(io, …)`, `accept(io)` returns a `Stream`); `http.Server.init(&reader.interface, &writer.interface)`; `http.Client` needs `.io` | 4 |
| `std.mem.trimRight` → `trimEnd` | 3 |
| `std.posix.SIG` is an enum; dropped kernel32 bindings (`SetEnvironmentVariableW`, `SetConsoleCtrlHandler`) → local `extern` | 1 / 2 |

🔑 **For zilc's own port:** the counted version-sensitive sites (`design-decisions.md` invariant 4:
`std.fs` 10, `std.process` 13, `ArrayListUnmanaged` 8) all fall in the rows above, most of them
behind **`io`**. `driver.zig`'s `std.process.Child` use is the "processes" row. Expect `io` to need
threading through `driver.build` and `compileZig`.

⚠️ Zig reports errors in waves as analysis reaches them, so one error is **not** the scope. The
complete list comes from a trial port carried to green: a throwaway checkout of the latest reference
tag, fixed until it builds and passes the tests.

---

## (template) `<new line>-1`, basis `<reference release>` — Zig `<from>` → `<to>`, YYYY-MM-DD

| API change | fix | sites |
| --- | --- | --- |
| | | |

Surprises: …  ·  Time taken: …  ·  Surface re-count: …

---

## Zig 0.16.0 → 0.15.2, 2026-09-18 (before the versioning scheme; a DOWNGRADE, recorded for its API list)

The repo started on 0.16.0 and moved to 0.15.2 to match Fil-C's LLVM 20 (KI-3). No line/basis
existed yet. Its API differences are the list a future 0.15.2 → 0.16 port will run into, **in
reverse**:

| API | 0.16 | 0.15.2 | sites |
| --- | --- | --- | --- |
| `main` and args | `std.process.Init` | `pub fn main() !void` + `std.process.argsAlloc(arena)` | `src/main.zig` |
| stdout / I/O | `std.Io` | `std.fs.File.stdout().writer(&buf)` → `.interface`, flush before return | `src/main.zig` |
| `build.zig` | `.root_module` form | same, **no change needed** | none |
| `build.zig.zon` | | `minimum_zig_version` moved | `build.zig.zon` |

Source: `design-decisions.md` "Zig 0.15.2 API notes" and KI-3. ⚠️ wazmrt (sibling project) is on
0.16 and is the nearest working example of the 0.16 APIs, but its code does not compile on 0.15.2.
