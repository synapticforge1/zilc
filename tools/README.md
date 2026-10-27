# tools/

Developer tooling for zilc. Build logic stays in `build.zig`; everything else is here.

**Every tool is a Bun script** (`.ts`), not shell, Deno or Python: the owner's preference
(2026-09-18: Deno or Bun, never Python; 2026-10-05: the shell scripts became Deno; 2026-10-22: Bun
only, Deno is going away, and every tool was ported to Bun). The tools use Node's APIs
(`node:fs/promises`, `process`) and Bun's own (`Bun.spawn`, `Bun.Glob`), never `Deno.*` or `jsr:`
imports. No shell scripts are committed: the one that installed Bun (`p1/setup-wsl.sh`) became the
documented step below plus `p1/setup-wsl.ts` (2026-10-27), since Bun cannot install itself.

## First-time setup (a fresh WSL or Linux home)

Run in a WSL or Linux shell (x86_64). No root is needed; everything goes under `~`.

1. **Install Bun** (once). Taken from npm's `@oven/bun-linux-x64` because that is a `.tgz`: Bun's
   own installer needs `unzip`, which a fresh Ubuntu lacks and installing needs root. The SHA-256 is
   the file's as downloaded on 2026-10-22 (its SHA-1 matched the registry's `dist.shasum`,
   `2f13abdede6651ab4c393e7754cbe64981dd325d`); `sha256sum -c` must print `OK`.

   ```sh
   mkdir -p ~/zilc-work/dl/bun ~/.bun/bin
   curl -fsSL https://registry.npmjs.org/@oven/bun-linux-x64/-/bun-linux-x64-1.4.3.tgz -o ~/zilc-work/dl/bun-1.4.3.tgz
   echo "efd069d474e6addceede0dc9c0981b4421cf35ceb3348e4b83462053a177281f  $HOME/zilc-work/dl/bun-1.4.3.tgz" | sha256sum -c
   tar -xzf ~/zilc-work/dl/bun-1.4.3.tgz -C ~/zilc-work/dl/bun
   cp ~/zilc-work/dl/bun/package/bin/bun ~/.bun/bin/bun
   chmod +x ~/.bun/bin/bun
   ~/.bun/bin/bun --version
   ```

   Then put it on `PATH`, so plain `bun` works: append this block to `~/.profile` (login shells)
   and to `~/.bashrc` (interactive shells); the `case` keeps it from being added twice when
   `~/.profile` sources `~/.bashrc`. Open a new shell, and `bun --version` prints `1.4.3`.

   ```sh
   if [ -d "$HOME/.bun/bin" ]; then
       case ":$PATH:" in
           *":$HOME/.bun/bin:"*) ;;
           *) PATH="$HOME/.bun/bin:$PATH" ;;
       esac
   fi
   ```

2. **Install the rest** — Zig 0.15.2, Fil-C's release, patchelf, and Fil-C's own `setup.sh`; each
   download is checked against a recorded SHA-256 and the tool is idempotent:

   ```sh
   ~/.bun/bin/bun tools/p1/setup-wsl.ts
   ```

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
