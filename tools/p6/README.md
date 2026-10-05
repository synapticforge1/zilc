# tools/p6: platforms (roadmap.md P6)

| tool | what it measures |
| --- | --- |
| `os-surface.ts` | For each target (Linux musl/Android, macOS, iOS, Windows; x86_64 and aarch64), compiles every `tests/basics` Zig program with plain Zig 0.15.2 to its unoptimized IR and counts the external OS functions, raw `syscall`/`svc` asm sites, and functions that build a pointer from a runtime integer. Results: `cmem/platforms.md` |

Run from Windows or Linux: `deno run -A tools/p6/os-surface.ts` (it runs inside WSL; ~10 minutes
for 9 targets × 78 programs at `JOBS=12`). `TARGETS="x86_64-linux-musl aarch64-macos"` narrows it.
Writes `$WORK/p6/os-surface.json`.

The Linux aarch64 probe of 2026-10-05 (zilc on `01_hello-world` for `aarch64-linux-musl`, then
the same module with Fil-C's own aarch64 layouts through the stock 0.686 clang) was run by hand;
its steps and results are in `cmem/platforms.md` "Finding 2".
