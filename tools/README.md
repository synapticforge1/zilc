# tools/

Developer tooling for zilc. Build logic stays in `build.zig`; everything else is here.

**Every tool is a Bun script** (`.ts`), not shell, Deno or Python: the owner's preference
(2026-09-18: Deno or Bun, never Python; 2026-10-05: the shell scripts became Deno "so that they are
cross platform"; 2026-10-22: Bun only, Deno is going away, and every tool was ported to Bun). The
tools use Node's APIs (`node:fs/promises`, `process`) and Bun's own (`Bun.spawn`, `Bun.Glob`),
never `Deno.*` or `jsr:` imports. The one exception is `p1/setup-wsl.sh`, which prepares a fresh
Ubuntu (and installs Bun to `~/.bun/bin`) before Bun is there.

## How to run a tool

> 🔒 **Owner, 2026-10-27: Bun runs inside Linux only** — from a WSL shell with `~/.bun/bin/bun` on
> a Windows host, with the machine's own Bun on Linux. **Do not start tools with Windows' Bun.** The
> Windows-side behaviour described below (`linuxOnly()` re-launching into WSL, tools that run
> natively on Windows) still exists in the code but is retired by that rule; removing it is
> pending (`cmem/open-work.md` owner call 3).

```
bun tools/<group>/<tool>.ts [args]
```

The same command works **from Windows and from Linux**:

- Tools whose work needs Linux (anything that runs Fil-C, which exists only there) call
  `linuxOnly()` from `lib/tool.ts` first. On Linux it returns; **on Windows it re-runs the same
  tool inside WSL**, with the same arguments and zilc's environment variables (`ZILC_*`, `JOBS`,
  `MODE`, …), and exits with its status. No more `wsl.exe -e sh /mnt/d/…`.
- Tools that need no Linux (git, Windows' own Zig, pure data) run natively on any OS:
  `upstream/*`, `basics/compile-check.ts`, `basics/size-report.ts`, `basics/zilc-failures.ts`,
  `basics/compare-output.ts`, `filc/patch-*.ts`.

## The groups

| folder | what |
| --- | --- |
| `run-gate.ts` | `zig build gate` where Fil-C lives (`cmem/testing.md`) |
| `basics/` | the `tests/basics` corpus: through zilc in every mode (`zilc-check`, `all-modes`), natively (`run-native`), output comparison, sizes, compile check |
| `filc/` | zilc's patched Fil-C toolchain: patch, build, archive, restore, check; Fil-C's own test suite (`run-filc-tests`); clang comparison; stock Fil-C built from source in cosmo mode (`build-cosmo`, the cosmo evaluation) |
| `upstream/` | the read-only Fil-C reference clone and its monitor |
| `p1/` `p2/` `p3/` | the phase experiments, kept as the record of how each result was measured (each folder has a README) |
| `p6/` | the platforms scope pass: `os-surface.ts` counts the OS functions, raw kernel asm and int-to-pointer functions Zig's std needs per target (`cmem/platforms.md`) |
| `lib/tool.ts` | the shared helper every tool imports |

## Writing a tool

- Import from `lib/tool.ts`: `linuxOnly`, `ARGS` (the tool's arguments), `run` / `must` / `show`
  (programs with argument arrays, no shell), `pool` (parallel), `glob`, paths (`REPO`, `WORK`,
  `ZIG`, `filc()`), small file helpers. Read and write files with `node:fs/promises`.
- Call `linuxOnly(import.meta)` first if the work needs Linux. In a file other tools IMPORT, call it
  only under `if (import.meta.main)`: imports run before the importer, so a top-level call would
  re-launch the wrong script (see `filc/fix-os-include.ts`).
- Keep the header comment: purpose, usage, environment variables, and the WHY of every setting
  (`cmem/INDEX.md`, the workaround rule).
- `sh()` exists for the rare Unix pipeline that is clearer as one (`xz | tar`); prefer `run`.
