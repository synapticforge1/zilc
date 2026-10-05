# Platforms: the P6 scope pass (pre-publish, ✅ 2026-10-05)

`roadmap.md` P6 asks, per platform, before publishing: confirm the processors; count the OS
functions Zig's std references (the checked-wrapper workload); the libc story; the std code that
builds pointers from integers (KI-5 family); and the host toolchain. This file holds the answers,
measured on Zig 0.15.2 and Fil-C 0.686. The port efforts themselves come after publishing.

## The answer in one table

| platform | processors | what Fil-C 0.686 offers | OS functions (corpus) | new int→ptr std functions | raw kernel asm | verdict |
| --- | --- | --- | --- | --- | --- | --- |
| **Linux** | x86_64 ✅ · **aarch64** | both, prebuilt (`filc-0.686-linux-{x86_64,aarch64}`) | 75 | 0 | 468 sites (x86_64) / 390 (aarch64) | **x86_64 works. aarch64 is close: 4 concrete gaps (below)** |
| **Android** | aarch64 · x86_64 | none (Bionic, not musl) | 72 (13 differ: `*64` variants, `arc4random_buf`, `__errno`) | 0 | 390 | Linux kernel, but needs a checked Bionic-compatible libc layer, or musl-on-Android |
| **macOS** | aarch64 · x86_64 | **cosmo mode** (APE binaries; see below); no native port | 79 (22 differ: `__ulock_*`, `os_unfair_lock_*`, `_dyld_*`, `fcopyfile`, `getcontext`, `$NOCANCEL`) | 3, all stack-trace code (`lookupModuleDyld`, `unwindFrameMachO`) | 0 (libSystem only) | via cosmo: plausible, not yet tried; natively: P3 runtime + libSystem layer |
| **iOS** | aarch64 | none (cosmo does not cover iOS) | 79 (as macOS) | 3 (as macOS) | 0 | macOS's work plus signing/no-exec-mmap; last |
| **Windows** | x86_64 · aarch64 | **cosmo mode, x86_64 only** (verified under Wine upstream; real Windows untested) | 86 (78 differ: kernel32, ntdll, ws2_32, crypt32) | 7: stack walking, `heap.PageAllocator.map/realloc`, DebugAllocator buckets | 0 | via cosmo: x86_64 plausible; aarch64 Windows has no route; natively: the biggest layer |

"OS functions (corpus)" = the external functions (not LLVM intrinsics or compiler-rt) referenced
by the 78 Zig programs of `tests/basics`, union over all programs, in Zig's unoptimized IR (the
module zilc feeds Fil-C). Median per program: Linux 28, macOS 31, Windows 39. All 78 programs
compile for all 9 targets with plain Zig 0.15.2. Tool: `tools/p6/os-surface.ts`.

**Whole std, not just the corpus** (Zig 0.15.2 `lib/std`, `extern "<lib>" fn` declarations):
`c` 554 (of which `c.zig` 313 shared, `c/darwin.zig` 80), `kernel32` 90, `ws2_32` 83, `ntdll` 49,
`mswsock` 12, `advapi32` 6, `crypt32` 3. So a full Windows layer is ~245 functions before libc;
the corpus touches 78 of them. `@ptrFromInt` sites: `os/linux` 221 (vDSO, auxv, syscall
structures), `c.zig` 30, `debug` 32, `heap` 22, `posix.zig` 9, `os/windows` 1 (but `teb()` comes
from a compiler-rt asm helper, `zig_x86_64_windows_teb`, a pointer Fil-C cannot vouch for: KI-5
family).

## 🔑 Finding 1: upstream Fil-C now has a COSMO mode (cross-OS binaries)

Fil-C added a third libc flavour, **Cosmopolitan libc**, between 2026-09-20 and 2026-10-04 (in
0.686; `upstream/fil-c/cosmo.txt`, 693 lines). A cosmo-mode link produces an **APE** ("actually
portable executable"): one static file that runs on Linux, macOS and the BSDs (x86_64 + aarch64)
and on **x86_64 Windows**; `--filc-fat-ape` puts both processors in one file. Facts from
`cosmo.txt`:
- The compiler is flavour-blind: the flavour is whatever is installed in `pizfix/` (marker:
  `pizfix/lib/libyolocosmo.a`). **The released 0.686 tarballs are the musl flavour**; cosmo needs
  Fil-C built from source (`build_all_fast_cosmo.sh`, ~1.2 GB cosmo toolchain download).
- Static-only: no `-shared`, no PIE, no `dlopen`. zilc links dynamically today, so its link step
  would change.
- Windows: verified under Wine (threads, stdio, C++); real Windows, GC-heavy programs,
  signals and fork "remain unproven". C/C++ `thread_local` still faults on Windows. No aarch64
  Windows.
- macOS: the APE loader for Apple silicon is compiled on first run and needs the macOS SDK
  (`cc`); not run on real Mac hardware upstream.
- Build host for cosmo mode: x86_64 Linux (`apelink`, `pecheck` are Linux host tools).

**Why it matters for zilc: cosmo's C ABI is Linux x86_64's, as Zig's std expects it.** Checked
in Fil-C's v0.686 tree (`projects/yolocosmo`, 2026-10-05): `O_CREAT` is `#define 0x40` (Linux's
value, not a runtime variable); `ENOENT` 2, `EAGAIN` 11 (Linux's); and `struct stat` has musl
x86_64's exact layout (cosmo's `st_flags` sits in musl's `__pad0`, its `st_birthtim` + `st_gen`
in musl's `__unused[3]`; same 144 bytes). So Zig code compiled for `x86_64-linux-musl` would
pass correct values to cosmo's libc on every OS, and **macOS + x86_64 Windows may be reachable
without writing a Zig runtime per OS**. Open questions (to answer in the port effort, not now):
1. What Fil-C's `syscall()` does in cosmo mode off Linux. zilc routes std's raw syscalls (468 asm
   sites summed over the corpus, x86_64) through it (`zilc_syscall`, KI-7) by LINUX syscall number; on macOS/Windows those numbers mean
   nothing unless cosmo translates them.
2. aarch64: cosmo's ABI is the same on both processors, but Zig's `aarch64-linux-musl` uses
   aarch64 Linux's own `struct stat` layout, which differs. The x86_64 half is the safe start.
3. Zig's `-lc` Linux build assumes dynamic musl (`libc.so`); cosmo is static, non-PIE.

## Finding 2: Linux aarch64, measured (2026-10-05)

`zilc build --target aarch64-linux-musl` on `01_hello-world`, x86_64 host: Zig's IR is produced
and the Fil-C pass RUNS; then clang aborts (`Target-incompatible DataLayout`). Four gaps, each
concrete:
1. **zilc's patched clang has no AArch64 backend.** `build-patched-clang.ts` configures
   `-DLLVM_TARGETS_TO_BUILD=X86`; upstream's `configure_llvm.sh` builds `X86;AArch64` on an
   x86_64 host, and the stock 0.686 clang lists both. (A departure from upstream: fix it on the
   next rebuild; it changes nothing for x86_64.) Without it, clang compiled the aarch64 module
   AS x86_64, hence the layout abort.
2. **zilc derives the data layouts from Zig's, but Fil-C's LLVM fork adds `p270/p271/p272` to
   its aarch64 layout too** (Zig's stock-LLVM aarch64 layout has none). With Fil-C's own aarch64
   layouts written into the module by hand, the **stock 0.686 clang compiled it to an ARM64 ELF
   object** (`--target=aarch64-unknown-linux-musl -O1`). Fix: take the layout from Fil-C's clang
   for the target instead of deriving it from Zig's (`src/ir.zig`).
3. **The KI-7 syscall rewrite is x86_64-only** (`ir.zig` matches `asm sideeffect "syscall"` and
   `@os.linux.x86_64.syscallN`); aarch64 std uses `svc #0` in `os.linux.aarch64.syscallN`. Four
   `svc #0` sites were left in hello-world's module. The C helper (`zilc_syscall`) is portable:
   it uses the headers' `SYS_*` numbers.
4. **Linking and running need Fil-C's aarch64 tree** (`filc-0.686-linux-aarch64.tar.xz`, 72 MB,
   not downloaded) and `qemu-aarch64` on this x86_64 machine (or real ARM64 hardware).

Plus: Zig passes aarch64 CPU features LLVM 20 does not know (`+ete`, `+fuse-aes`, …):
"not a recognized feature, ignoring". Harmless, but noisy; probably `-mcpu=generic` or
filtering.

## Finding 3: the host toolchain

- **Fil-C's clang ships for Linux x86_64 and Linux aarch64 hosts only** (0.686 release assets:
  `filc-0.686-linux-{x86_64,aarch64}`, `optfil-…` the same). zilc on Windows already works
  through WSL2. zilc's own code is portable Zig.
- The Fil-C pass has **no OS conditionals**: it branches on processor only (x86_64, aarch64:
  page size, stack-check asm, store fences; `FilPizlonator.cpp`), and has no ELF/Mach-O/COFF
  code. The OS lives in the runtime (`libpas`, `filc/src`) and the libc. So a clang for another
  HOST is an LLVM build question; the RUNTIME is the real per-OS cost.
- Cosmo mode keeps the host on x86_64 Linux (its link tools are Linux binaries) while the
  TARGETS become cross-OS. For a Windows or macOS developer that means WSL2 / a Linux VM or
  container, as today.

## What this changes in the plan (proposals, owner to decide after publish)

- **Linux aarch64 first** (already tier 1, first in `roadmap.md`'s order): the four gaps above,
  all small. Fidelity check: Fil-C's own aarch64 tree and its test suite under qemu.
- **Evaluate cosmo mode before writing any macOS/Windows runtime.** If question 1 (syscalls)
  has a good answer, x86_64 macOS/Windows/BSD may come from Fil-C itself, which also serves the
  FIDELITY FIRST goal (upstream's own runtime, not a new one). The native per-OS runtime (P3)
  stays the route for aarch64 Windows, iOS and Android, which cosmo does not cover.
