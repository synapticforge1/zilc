# tools/

Developer tooling for zilc. Build logic stays in `build.zig`; everything else is here.

**Every tool is a Bun script** (`.ts`), not shell, Deno or Python: the owner's preference
(2026-09-18: Deno or Bun, never Python; 2026-10-05: the shell scripts became Deno; 2026-10-22: Bun
only, Deno is going away, and every tool was ported to Bun). The tools use Node's APIs
(`node:fs/promises`, `process`) and Bun's own (`Bun.spawn`, `Bun.Glob`), never `Deno.*` or `jsr:`
imports. The one exception is `p1/setup-wsl.sh`, which prepares a fresh Ubuntu (and installs Bun to
`~/.bun/bin`) before Bun is there.

## How to run a tool

🔒 **Inside Linux only** (owner, 2026-10-27: zilc is Fil-C on Linux x86_64, and Bun runs inside
Linux — WSL's Bun on a Windows host, the machine's own Bun on Linux). From a WSL or Linux shell, in
the repo:

```
~/.bun/bin/bun tools/<group>/<tool>.ts [args]
```

Every tool imports `lib/tool.ts`, which **refuses to run anywhere but Linux** (exit 2, with the
command to use instead). Until 2026-10-27 a tool started with Windows' Bun re-launched itself inside
WSL; that bridge is retired: refusing, not bridging, so no run can look like a Linux run while
starting elsewhere.

## The groups

| folder | what |
| --- | --- |
| `run-gate.ts` | `zig build gate` where Fil-C lives (`cmem/testing.md`) |
| `basics/` | the `tests/basics` corpus: through zilc in every mode (`zilc-check`, `all-modes`), natively (`run-native`), output comparison, sizes, compile check |
| `filc/` | zilc's patched Fil-C toolchain: patch, build, archive, restore, check; Fil-C's own test suite (`run-filc-tests`); clang comparison; stock Fil-C built from source in cosmo mode (`build-cosmo`, the cosmo evaluation — now zailc's record) |
| `upstream/` | the read-only Fil-C reference clone and its monitor |
| `p1/` `p2/` `p3/` | the phase experiments, kept as the record of how each result was measured (each folder has a README) |
| `p6/` | the platforms scope pass: `os-surface.ts` counts the OS functions, raw kernel asm and int-to-pointer functions Zig's std needs per target (`cmem/platforms.md`; P6 is zailc's since 2026-10-27) |
| `lib/tool.ts` | the shared helper every tool imports, and the Linux-only check |

## Writing a tool

- Import from `lib/tool.ts` (that import is also what makes the tool refuse off Linux): `ARGS`
  (the tool's arguments), `run` / `must` / `show` (programs with argument arrays, no shell),
  `pool` (parallel), `glob`, paths (`REPO`, `WORK`, `ZIG`, `filc()`), small file helpers. Read and
  write files with `node:fs/promises`. A tool that needs nothing from it still imports it:
  `import "../lib/tool.ts";`.
- `linuxOnly(import.meta)` at the top of a tool that needs Fil-C is kept as a marker; it only
  asserts what the import already checked.
- Keep the header comment: purpose, usage, environment variables, and the WHY of every setting
  (`cmem/INDEX.md`, the workaround rule).
- `sh()` exists for the rare Unix pipeline that is clearer as one (`xz | tar`); prefer `run`.
