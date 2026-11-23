# workarounds-machine.md — machine setup, and the Windows-host rule (split from workarounds.md 2026-11-23)

## Machine setup — Fil-C's kernel-header links (`os-include`), 2026-10-05

**Symptom.** `fatal error: 'asm/types.h' file not found`, included from
`pizfix/os-include/linux/types.h`, for any C file that includes `<linux/futex.h>`,
`<linux/seccomp.h>` or another kernel header reaching `<asm/types.h>`.

**Class.** System setup (this machine), not a Fil-C or zilc defect.

**Root cause, measured.** Fil-C's prebuilt does not ship kernel headers. Its `setup.sh`, run once
after unpacking, links `pizfix/os-include/{linux,asm,asm-generic}` to the host's `/usr/include`,
choosing `asm` = `/usr/include/x86_64-linux-gnu/asm` **if it exists**, else `/usr/include/asm`.
Here setup.sh ran before `build-essential` (and with it `linux-libc-dev`) was installed, so `asm`
pointed at `/usr/include/asm`, which Ubuntu does not have: a dangling link. zilc's patched tree is a
copy of the prebuilt, so it inherited the link, and so does the archive in `toolchain/`.

**Why the fix is correct.** `tools/filc/fix-os-include.ts` re-applies setup.sh's own rule against
the machine as it is now; nothing else in the tree changes. `build-patched-clang.ts` and
`restore-patched-clang.ts` run it after installing, so a restored archive is repaired on the
machine it lands on; `check-toolchain.ts` reports a dangling link (`BROKEN`).

**How it was found.** Fil-C's own test suite (`tools/filc/run-filc-tests.ts`): 9 tests failed with
BOTH the stock and the patched clang, which pointed away from zilc's patches and at the setup. No
zilc test had hit it: the corpus and gate include no kernel headers.

**Recognising a relative.** A failure shared by the stock and the patched compiler is the
environment, not zilc's patches: look at links and paths outside the compiler first.

---

## Machine setup — building Fil-C from source in cosmo mode, 2026-10-05

**Context.** The cosmo evaluation (owner: "evaluate cosmo mode by first building Fil-C from
source"; `archive/platforms-p6-cosmo-2026-10-08.md`) runs upstream's own `build_base_cosmo.sh`, unmodified, through
`tools/filc/build-cosmo.ts`. Upstream's reference host is its build container
(`Dockerfile-build-env`, Ubuntu 25.04) plus `cosmo.txt`'s aarch64 package list. This machine is
Ubuntu 26.04 in WSL2, so five things differ. None of them changes what Fil-C produces.

1. **`libstdc++-15-dev-arm64-cross` instead of `-13`.** _Why:_ `cosmo.txt` itself says to install
   the libstdc++ cross headers matching the cross GCC's version (it gives GCC 12 → `-12` as the
   example), and 26.04's `gcc-aarch64-linux-gnu` is GCC 15. They are the headers the aarch64
   compiler-rt/libpas cross builds compile against.
2. **`libblake3-dev` 1.8.2 from apt instead of BLAKE3 1.8.7 built into `/usr/local`.** _Why:_ the
   Dockerfile builds it by hand only because its base image lacks the package; it is a
   dependency of Fil-C's BUILD tooling, never compiled into the compiler's output or a user
   program. _Revisit_ if the build fails on a BLAKE3 API newer than 1.8.2: then build 1.8.7 from
   `projects/BLAKE3-1.8.7.tar.gz` as the Dockerfile does. (First run, 2026-10-05: `projeny`, the
   first build step, compiles its OWN bundled BLAKE3 (`projects/projeny/src/blake3`), so it does
   not use this one at all.)
3. **`libcurl4-openssl-dev` added** (not in upstream's Dockerfile, which installs only the `curl`
   program). _Why:_ `projeny` links `-lcurl` and includes `<curl/curl.h>`; the first run stopped
   there (`fatal error: curl/curl.h: No such file or directory`, 2026-10-05). Upstream's image
   presumably gets the headers some other way; the build only needs them to compile its tool.
4. **Cosmo's APE loader registered with binfmt_misc (WSL only).** _Symptom:_ clang built fine
   (~20 min at 12 jobs), then `build_yolocosmo.sh` failed at once: every cosmo compile ended in
   make's `Error 5` with no message. _Root cause, measured:_ cosmo's build tools (`cocmd`,
   `tlscc`, `compile.ape`, …) are APE binaries starting with `MZqFpD`; WSL's `WSLInterop`
   binfmt_misc entry claims every file starting with `MZ` and runs it as a WINDOWS program, so the
   tools never ran (run directly: nothing; through `build/bootstrap/ape.elf`: they work). Not a
   Fil-C or cosmo defect, and upstream's Linux hosts have no WSLInterop. _Fix (cosmo's documented
   one):_ install cosmo's own loader (`projects/yolocosmo/build/bootstrap/ape.elf`, the version
   Fil-C's tree ships) as `/usr/bin/ape` and register it for `MZqFpD` and `jartsr`;
   binfmt_misc tries the newest entry first, so it wins over WSLInterop. Root-only, so the
   owner runs it; `build-cosmo.ts` detects the missing `APE` entry and prints the commands.
   _Side effect:_ none for Windows `.exe` files (they start `MZ` but not `MZqFpD`). Lost on a WSL
   restart unless `/etc/binfmt.d/cosmo-ape.conf` is written (the tool prints that too).
   _Bears on the evaluation itself:_ a zilc user on WSL would need the same registration to run
   cosmo-mode (APE) programs there.
   ⚠️ **Not reliable on WSL (measured 2026-10-05, ~10 minutes later).** With `APE` registered and
   enabled, cosmo's libc built (18:29); at 18:40 the next step (`make filcapetools`) failed the same
   way: cosmo's Makefile runs EVERY recipe through `SHELL = build/bootstrap/cocmd` (an APE), and
   `cocmd -c 'echo hi'` run directly exited 5 with no output, while `/usr/bin/ape cocmd -c …`
   printed `hi`. So WSLInterop was in front again: WSL evidently re-registers its entry, and
   "newest entry wins" does not hold for long. **The dependable fix is to take WSLInterop out of the
   way:** remove it (`echo -1 > /proc/sys/fs/binfmt_misc/WSLInterop`, until WSL re-adds it) or stop
   WSL creating it (`/etc/wsl.conf`: `[interop]` `enabled=false`, then `wsl --shutdown`), which also
   stops running Windows `.exe` files from inside WSL. Owner's choice.
   ✅ **Owner chose the permanent fix (2026-10-05):** `/etc/wsl.conf` now has `[interop]`
   `enabled=false`; after `wsl --shutdown` the `WSLInterop` entry is gone, the `APE`/`APE-jart`
   entries came back by themselves from `/etc/binfmt.d/cosmo-ape.conf`, and `cocmd` runs directly.
   (A later `echo -1 > …/WSLInterop` fails with "Permission denied": the entry no longer exists, and
   binfmt_misc does not let a new file be created there. Harmless.) Consequence: Windows `.exe`
   files cannot be started from inside WSL on this machine; zilc's tools only go the other way
   (Windows → WSL).
5. **Parallelism capped at 12 jobs** (`JOBS`). _Why:_ upstream uses every core (`NCPU=$(nproc)` in
   `libpas/common.sh`, ninja's default for clang); on this 32-core, 31 GB WSL VM, 32 parallel
   RelWithDebInfo clang compiles crashed the WSL service twice (2026-10-01). _How, without editing
   upstream:_ GNU `nproc` honours `OMP_NUM_THREADS`, and `build_clang.sh`/`build_compiler_rt.sh`
   source an optional `clang-build-overrides.sh` (written by the tool) for `NINJAFLAGS`. The job
   count changes build speed only.

**Also:** the root-only step (apt) is the owner's to run: `sudo` here needs a password, and the
tool prints the exact `apt-get install` line for whatever is missing. ~~Ruby is not installed:
upstream's Ruby test runner is replaced by zilc's Deno port (`run-filc-tests.ts`).~~ **Corrected
2026-10-05: Ruby IS a build dependency.** The runtime's Makefile (`libpas`) runs
`generate_pizlonated_forwarders.rb` and `` `./find_clang_include_dir.rb` `` while compiling; the
build stopped there (`env: 'ruby': No such file or directory`, plus clang errors that were only a
side effect of the empty include-dir result). Only the TEST runner is replaced by the Deno port (a Bun port since 2026-10-22).
This matters for the all-Zig goal: Fil-C's runtime build needs Ruby, so building it from
`zig build` means porting those two generators too.

---

## Nothing built by Fil-C or cosmo is ever EXECUTED on the Windows host (SentinelOne), 2026-10-05 / 2026-10-08

**Symptom.** After the cosmo evaluation on 2026-10-05 the machine's endpoint agent (**SentinelOne**,
`Sentinel Agent 26.1.2.177`; Datto AV also present; Windows Defender is off, so `Get-MpThreat`
shows nothing) raised an incident, the APE copies vanished from the session's scratchpad (only the
`.out`/`.err` logs are left) and Claude Code lost its connection. The owner confirmed it was
SentinelOne (2026-10-08).

**Class.** System limitation (a managed EDR, by design; it will not change). Not a Fil-C, cosmo or
zilc defect.

**Root cause (the why).** _Measured_, from the Windows Application log (Event IDs 1000/1001):
- 18:38:32–18:38:57: cosmo's build tools `cocmd` and `compile.ape` ran as WINDOWS processes from
  `\\wsl.localhost\Ubuntu\...\filc-cosmo\...` (WSL interop sent them there; see the entry above)
  and crashed with `0xC0000005`, five times.
- 18:59–19:12: the session copied APE programs into Claude's Windows scratchpad
  (`%TEMP%\claude\...\scratchpad\ape\`), renamed them `.exe` (`01_hello-world.exe`,
  `31_timers.exe`, `chello.exe`, `plain.exe`) and ran them on real Windows, seven times. Each died
  as WER event `BEX64` with `P9 = 0000000000000008`: a DEP violation (execute from non-executable
  memory), "faulting module: unknown", no version resource, no signature.
  _Surmised, consistent with how SentinelOne's behavioral engine is documented:_ unsigned, versionless
  binaries in a Temp folder, launched by a `node.exe` process tree (Claude Code), repeatedly faulting
  on execute-from-data, is the profile it classifies as a loader/injector. Its mitigation kills the
  whole process tree (which includes Claude Code) and quarantines the files; the "cut off Claude
  access" was that, or the network-quarantine policy, which we cannot see from here (the agent's
  console is IT's).

**Why the rule is correct.** Nothing in the cosmo evaluation NEEDS the Windows host. The Linux half
of an APE runs in WSL through cosmo's own `ape` binfmt entry; the Windows (PE) half runs under
`wine64` INSIDE WSL, which is also the only way upstream verified it (`cosmo.txt` "Windows retest
checklist": real Windows is untested upstream). With `/etc/wsl.conf` `[interop] enabled=false`
nothing in WSL can reach a Windows process by accident any more, so the only remaining path is a
deliberate copy to the Windows side. **That path is closed: no file produced by Fil-C, cosmo or
zilc is copied to a Windows path and executed there, in any session, and WinDbg on this machine is
not an option.** If real-Windows behaviour ever matters, it is done on a box without a managed EDR,
or with IT's exclusion for a dedicated folder, and from a plain terminal, never from Claude's
process tree.

**Consequence for the evaluation record.** The 2026-10-05 finding "every cosmo program crashes on
real Windows" was measured with SentinelOne's in-process agent injected into those processes and
with DEP enforcement around a loader that maps and jumps into its own image. It may be entirely
EDR-induced. It is therefore recorded as **unverified**, not as an upstream defect, and left to
upstream's "next person with a Windows box".

**Ruled out.** That the Windows _build_ side was involved: nothing from the Windows side compiled or
linked anything; all faulting images are APE files. That WSL itself was flagged: the WSL distro,
work tree, Wine prefix and cosmo `pizfix/` are intact (checked 2026-10-08), and the checklist runs
there without incident.

**Recognising a relative.** Claude Code dies mid-task, no error in the repo, the just-run binaries
are gone from disk, and the Application log shows `Application Error` 1000 / WER `BEX64` for them.
First thing to try: nothing on Windows; move the step into WSL (or Wine in WSL).

**Cost and exit.** No cost to zilc: Windows is not a build host for zilc. Exit: none; the rule stands
while this machine is managed.

**Where.** `archive/platforms-p6-cosmo-2026-10-08.md` "Cosmo evaluation"; `best-practices.md` (the rule in one line);
machine-local memory `no-windows-host-execution`.

---

## Windows build gotchas (dev machine: win32, D: = exFAT)

> 🔁 **Retired 2026-10-27:** zilc is built and run inside Linux only (WSL here; `design-decisions.md`
> top rows), so the first two bullets (Windows' Zig, the NTFS cache) are history; WSL's Zig is
> `~/zilc-work/tools/zig-0.15.2/zig` with the cache in the Linux home. The git notes stay current:
> the checkout is still on the exFAT `D:`.

- **Zig 0.15.2 lives at `C:\zig\0.15.2\zig.exe`** (official zip, SHA-256 verified against
  ziglang.org's `index.json`, installed 2026-09-18). It is **not on PATH**. Bare `zig` is the scoop
  shim, which is **0.16.0**, and wazmrt still needs that. So invoke by full path, or put
  `C:\zig\0.15.2` first on PATH for the session.
- `ZIG_LOCAL_CACHE_DIR=C:\zig-cache\zilc` is required (KI-2).
- The repo lives on exFAT, so git reports _dubious ownership_. ✅ **Fixed on this machine
  2026-09-18**: the owner added the repo path to the global `safe.directory`, so plain `git` works.
  On a new machine or clone location, run
  `git config --global --add safe.directory <path-to-zilc>` once.
- Writing Zig multiline strings (`\\`) through a bash heredoc can drop a backslash. Write Zig
  sources with the file tools instead.
