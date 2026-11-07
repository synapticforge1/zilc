# Roadmap

> 🔒 **2026-10-27 (owner), as settled by the end of the day:** P0–P2 are done; P4, P5 and P6
> moved to zailc and are abandoned here, and so is P3 *as a different runtime*. **Open in zilc:
> the pure-Zig track below** — zailc's build up to a pure-Zig implementation running in Linux
> (owner: *"all of zailc's build to the point of pure zig implemenation running in linux should be
> in zilc"*). Alongside it, zilc's standing role (`design-decisions.md`, top rows): track Fil-C,
> follow the matching Zig, keep Zig and C correct on x86_64 Linux, be the corpus of truth.

## The pure-Zig track (owner, 2026-10-27) — Fil-C, built and then implemented in Zig, on Linux

Faithful to each Fil-C release, no departures (zailc keeps those). Every item is checked against
the release it is built from — same bytes where generated, same symbols and behaviour where
compiled — and then by `zig build gate-zig-modules` (`testing.md`), the corpus and Fil-C's suite.
Brought from zailc's step 2 / step 3 by reading zailc's code (nothing is written there), adapted to
zilc, and re-verified against zilc's Fil-C release (0.686 work moves to 0.687 on the way).

- **Z1 — the runtime from Fil-C's sources by `zig build`** (zailc step 2, mostly done there for
  0.686): the forwarder generator (byte-identical to Ruby; 0.687 adds 3 signatures) and musl's
  header install; libpas's stock half, `filc_crt.o`, `filc_mincrt.o`, `libyolounwind.a`; yolo musl's
  static half; compiler-rt — then what zailc has not done: yolo musl's shared half (`libyoloc.so`,
  `ld-fil1-x86_64.so`), the three Fil-C-compiled pieces (`filc/src`, the user libc, libc++), a
  program linked entirely from `zig build`'s outputs, Fil-C's suite against it.
  - [x] **The generators, in zilc, on 0.687** (2026-10-27): `zilc-gen` (`src/gen/`, `zig build gen`)
        — the forwarder generator's output is **byte-identical to Ruby's for 0.687** (456 native +
        13 user signatures; `filc_native.h` 45,695 B, `filc_native_forwarders.c` 983,629 B;
        SHA-256 pinned in `zig build test`, inverted: one changed hex digit fails exactly that
        test) and musl's header install is **byte-identical to `make install-headers`** (219
        files). Oracles: `tools/gen/verify-forwarders.ts`, `verify-musl-headers.ts`.
  - [x] **libpas's stock half, `filc_crt.o`, `filc_mincrt.o`, `libyolounwind.a`; yolo musl's
        static half; compiler-rt** (2026-10-27): `zig build libpas | yolomusl | compiler-rt |
        pure-zig -Dfilc-src=…` (`build/pure_zig.zig`), tables regenerated for 0.687; every object
        and member defines exactly the 0.687 release's symbols (`testing.md`), compiler-rt without
        zailc's W-10 departure. Then `zig build gate-zig-modules` on them (`testing.md`).
  - [x] **yolo musl's shared half** (`libyoloc.so`, which is also the loader `ld-fil1-x86_64.so`;
        2026-10-27): `zig build yolomusl` links it with `zig ld.lld` (W-11). It exports the
        release's 1,653 symbols, with dynamic tags equal; then `gate-zig-modules` ran with 10 linked,
        gate 8/8, corpus 78/78 as designed and comparison 0 unexplained (`testing.md`).
  - [ ] the three Fil-C-compiled pieces (`filc/src` → the rest of `libpizlo`, the user libc,
        libc++). **Started 2026-11-06** (owner: "then we can start on the pure-Zig track").
    - [x] `filc/src` → the rest of libpizlo: done 2026-10-30 as part of libpas whole
          (`buildLibpizlo`, W-12; Fil-C's clang from `zig build`, linked by `zig ld.lld`).
    - [x] **the user libc — BUILT AND VERIFIED 2026-11-06** (all four steps below; step 4: MODE=zig
          builds it with `zig build` instead of `build_usermusl.sh`, and `compare-chains.ts` is
          14/14, `testing.md` item 8):
          `zig build usermusl -Dfilc-clang=…` (also in `pure-zig` with -Dfilc-clang);
          `verify-usermusl.ts` OK against the release: `libc.a` 1,333 members in upstream's order,
          defined and undefined symbols equal (but F-4: 2 members, the patched clang's own),
          1,330 compile-unit names equal, `__FILE__` strings equal in 1,322 members (11 not
          comparable, F-3); `libc.so` 4,511 exports and 281 undefined equal, NEEDED and tag kinds
          equal (RUNPATH: the install's); the eight empty archives; 219 headers byte-identical.
          Inverted (two table entries swapped: it still builds, the oracle fails on exactly those
          two members). Found on the way: F-2, F-3, F-4, C-13. ⚠️ C-13 says yolomusl's headers'
          `__FILE__` likely read `src/internal/…` where upstream's read `./src/internal/…`
          (`verify-yolomusl.ts`'s form rule accepts both): check with the set comparison and fix
          as `buildUserMusl` does.
    - (the plan, as written before the build:) **the user libc** (`projects/usermusl` → `pizfix/lib/libc.a`, `libc.so`, the eight empty
          `libm.a` … `libdl.a`, and `pizfix/include`). Measured from upstream's own run
          (2026-11-06, `build_usermusl.sh` under MODE=zig): musl's configure with `CC = <Fil-C
          clang> -yolo-assembler`; 1,333 compiles, ALL C (no x86_64 assembly in user musl);
          the Makefile is yolomusl's but for: no `-g` in CFLAGS_ALL, no `-fPIE` on LIBC_OBJS, no
          crt or ldso objects, and `libc.so` linked through the DRIVER as `$(CC) $(CFLAGS_ALL)
          $(LDFLAGS_ALL) -shared -o lib/libc.so $(LOBJS) -lyolort -nodefaultlibs`, to which
          Fil-C's driver still adds `crti.o crtbegin.o -L<pizfix>/lib -rpath <pizfix>/lib …
          -lpizlo -lyolort -lyoloc -lyolom -lyolort -lyolounwind crtend.o crtn.o`
          (`clang -###`). Plan, the yolomusl pattern: (1)
          `tools/runtime/import-usermusl-sources.ts` → `src/runtime/usermusl_sources.zig`
          (configure with Fil-C's clang in a scratch copy; the Makefile rules asserted); (2)
          `buildUserMusl` in `build/pure_zig.zig`: GENH and version.h as for yolomusl, each
          object a Fil-C-clang step (as `buildLibpizlo`'s), `libc.a` with upstream's member
          names, `libc.so` by `zig ld.lld` with the driver's additions and LDFLAGS_AUTO
          (`--exclude-libs` naming the archives upstream's line has, W-11 part 2), headers by
          `zilc-gen musl-headers` on the usermusl tree; (3) `tools/runtime/verify-usermusl.ts`
          against the release (symbols and exports, never bytes: F-1); (4) MODE=zig takes it
          instead of `build_usermusl.sh`, then `compare-chains.ts` 14/14.
    - [x] **libc++ / libc++abi — BUILT AND VERIFIED 2026-11-06** (steps 1–3 done; step 4 wired,
          its compare-chains run recorded in `testing.md` item 8): `zig build libcxx
          -Dfilc-clang=…` (also in `pure-zig`); `verify-libcxx.ts` OK against the release — the
          three archives 54 / 18 / 5 members in order, defined and undefined symbols equal with NO
          allowance, 76 compile-unit names and the `__FILE__` strings of all 77 members equal
          (each build's location stripped); `libc++.so.1.0` 5,601 and `libc++abi.so.1.0` 682
          exports equal, undefined, NEEDED, SONAME, tag kinds equal; the script, the links and
          all 2,084 headers byte-identical. Inverted (two archive members swapped: it builds,
          fails on exactly #0 and #1). Found on the way: B-11 (the sparse FILC_SRC changes
          libc++'s CMake), F-2's C++ half. MODE=zig now runs only `fix_clang.sh` (what
          build_cxx.sh ran besides building), minilute and sarcasm from upstream's scripts.
    - (the measurements and plan, as written before the build:) **libc++ / libc++abi** (`build_cxx.sh`: CMake + Ninja over LLVM's
          `runtimes/` with Fil-C's clang/clang++, then `install-cxx-linux.sh`). Measured from
          upstream's run (MODE=zig tree, `runtimes-build/build.ninja`): 149 C++ compiles —
          `cxx_static` 54, `cxx_shared` 54 (the same sources, + `-fPIC`), `cxxabi_static_objects`
          18, `cxxabi_shared_objects` 18, `cxx_experimental` 5 — one DEFINES/FLAGS/INCLUDES set per
          target; links `libc++abi.so.1.0` and `libc++.so.1.0` (`-shared -Wl,-z,defs -Wl,-z,nodelete
          -nostdlib++`, soname `libc++.so.1`, against `libc++abi.so.1.0 -lpthread -lc`, a build-tree
          rpath); archives `libc++.a`, `libc++abi.a`, `libc++experimental.a`; `libc++.so` is the
          script `INPUT(libc++.so.1 -lc++abi)`, plus the `.so.1`/`.so` links. Headers: 2,083 in
          `build/include/c++/v1` (2,079 copies of `libcxx/include`; `__assertion_handler`,
          `__cxxabi_config.h`, `cxxabi.h`, `libcxx.imp` from elsewhere) and the configured
          `build/include/x86_64-unknown-linux-gnu/c++/v1/__config_site` — exactly what the release
          ships (2,083 + 1); the 131 module files upstream's script copies to `build/modules` are
          NOT in the release, so not built. Plan, the compiler-rt pattern: (1)
          `tools/runtime/import-libcxx-sources.ts` runs upstream's CMake configure (options
          asserted against `build_cxx.sh`) from the fetched package into a scratch dir, plus the
          header targets only, and reads `build.ninja` → `src/runtime/libcxx_sources.zig`; (2)
          `buildLibcxx` in `build/pure_zig.zig` (Fil-C clang++ per object with depfiles, the
          archives with CMake's member names, the two links by `zig ld.lld` with what Fil-C's
          clang++ driver adds, the header tree); (3) `verify-libcxx.ts` against the release; (4)
          MODE=zig without `build_cxx.sh`, compare-chains 14/14. (minilute and sarcasm, Fil-C's
          Luau tools, are built by upstream's scripts too; decide after libc++.)
- **Z2 — the pass in Zig** (zailc step 3, not started there): an LLVM IR model in Zig, the pass
  (`FilPizlonator.cpp`), the analyses it needs, KillUB and DeleteRedundantPollchecks; oracle: the
  same module through Fil-C's pass and through zilc's, compared as IR and as behaviour.
- 🗓️ Owner calls on the way: the order (Z1 first, as zailc did); whether zailc's tooling layout
  (`tools/package.json`, `tsconfig.json`, its typecheck tool) comes too.

> 🔒 **2026-10-27 (owner): zilc stays Fil-C on Linux x86_64 only, worked in WSL or Linux; the
> cross-platform part is zailc's** (`design-decisions.md`, top row). **P6 below no longer applies
> to zilc** beyond Linux x86_64 (Linux aarch64 included); it is kept as the record zailc started from.

> 🔁 *Superseded 2026-10-27 (the roadmap is closed for zilc, above).* **Updated 2026-09-30.** P3 has a plan (Linux first, the Zig runtime checked against Fil-C, the
> `--runtime` switch already in the CLI), and a proposed **P6 — other platforms**. Next step: the
> `zsys_write` spike, or P4, whichever the owner picks.

> **Updated 2026-09-23 (twice — read the P2 section).** WSL arrived, P1 ran, and its step-3 verdict
> ("the wrapper-driver route is dead") was **REVERSED by P2 the same afternoon**. ✅ **THE P1
> MILESTONE IS MET:** a Zig object and a C caller, both through Fil-C's pass, panic correctly with
> the fault located **inside the Zig source**. No Zig fork and no LLVM build were needed.

## ✅ P0 — Scaffold (`0.1.0`, 2026-09-18)

Repo layout, dual license + staged upstream licenses, compliance ledger, `cmem/`, build graph with
`test` / `capi-smoke` / `baseline`, two bug examples.

## ✅ P1 — The feasibility milestone. **MET 2026-09-23** (see P2 below for how; step 3's verdict was reversed).

> **Milestone:** a Zig program plus a C library, compiled through Fil-C's *existing* pass and
> runtime, panics correctly on out-of-bounds and use-after-free. ✅ **Reached** — via the
> ReleaseSafe/Small/Fast path, with Zig exporting a C-ABI function and C owning `main`.

### ✅ Step 1 — environment (2026-09-23, WSL2 Ubuntu 26.04)

Everything lives in the WSL home, **nothing installed system-wide, no root used**:

| item | location | note |
| --- | --- | --- |
| Fil-C **0.685** | `~/zilc-work/tools/filc-0.685-linux-x86_64` | prebuilt release; `setup.sh` run; `build/bin/clang` reports `clang 20.1.8 (Fil-C 0.685 …bb0d0a64)` |
| Zig **0.15.2** | `~/zilc-work/tools/zig-0.15.2` | official tarball, SHA-256 verified; `zig cc` = clang 20.1.2 |
| patchelf 0.19.1 | `~/zilc-work/tools/bin` | `setup.sh` needs it; `sudo` needs a password, so it was installed from the upstream prebuilt tarball instead |
| Deno 2.9.7 | `~/.deno/bin` | pre-existing; ran zilc's tools 2026-10-05 → 2026-10-22, no longer used |
| Bun 1.4.3 | `~/.bun/bin` | 2026-10-22, from npm's `@oven/bun-linux-x64` tarball (no `unzip`/root needed), SHA-256 checked (by `tools/p1/setup-wsl.sh` until 2026-10-27; since then the documented step in `tools/README.md` "First-time setup"); runs zilc's tools |

⚠️ `sudo` on this WSL requires an interactive password, so **an agent cannot apt-install anything.**
Prefer no-root prebuilt binaries.

### ✅ Step 2 — Fil-C's reference behavior on our examples (the gate's expected output)

Both compile with `build/bin/clang -O2 -g` and **panic correctly, exit 133** (SIGTRAP):

```
oob_write.c:15 → filc safety error: cannot write pointer with ptr >= upper.
                 expected 4 writable bytes.
use_after_free.c:13 → filc safety error: cannot access pointer to free object.
                 expected valid capability.
both → [pid] filc panic: thwarted a futile attempt to violate memory safety.
```

The panic names the **source file, line and column**, so the future gate can assert the fault kind
*and* its location, not just a non-zero exit (`testing.md`).

### ⚠️ Step 3 — "Zig IR does NOT go through Fil-C's clang" — **WRONG, and corrected below in P2.**

> Everything in this step is reported as it happened. Every run used Zig's **default Debug mode**,
> and that — not "Zig IR" — is what crashes the pass. Read it as the cautionary tale it is; the
> corrected picture is in P2 and `known-issues.md` KI-4's reversal.

What was tried, in order, and what each attempt proved:

| attempt | result |
| --- | --- |
| `zig build-exe -femit-llvm-ir` (musl and gnu targets) → `filc clang prog.ll` | ❌ assert: `DLBefore.isNonIntegralAddressSpace(TargetAS)` (`FilPizlonator.cpp:16043`) |
| Same, with Zig's datalayout replaced by Fil-C's *printed* one | ❌ same assert — the printed layout is not the one the pass wants |
| **Fil-C's own `-emit-llvm` output fed back into Fil-C** | ❌ **same assert.** Its `.ll` is POST-pass (`pizlonated_` symbols) and it cannot re-consume its own output |
| `-ni:0` appended to Zig's datalayout + a `datalayout_after_filc` line | assert passed, then **SIGSEGV inside the pass** |
| `-ni:0` in the **exact position** Fil-C uses (`e-m:e-ni:0-p270:…`) | assert passed, **SIGSEGV** again, on both a tiny module and a std-using one |
| Zig **bitcode** (`-femit-llvm-bc`) via `-flto` | ❌ same assert (bitcode carries Zig's datalayout) |

🔑 **The two facts that decide the architecture:**

1. **Fil-C's "before" data layout marks address space 0 NON-INTEGRAL** —
   `e-m:e-ni:0-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128` — and the
   module also carries a Fil-C-only directive, **`target datalayout_after_filc`** (read by their
   added `Module::getDataLayoutAfterFilC()`), holding the same layout *without* `ni:0`. `ni:0` is
   not expressible in stock LLVM, which forbids a non-integral AS 0; this is a **patched-LLVM
   dialect**, not standard IR. The exact string was recovered from a backend error message, and
   position matters: LLVM compares layout strings textually.
2. **Externally produced IR is not an entry point.** Fil-C's clang cannot even re-consume its own
   `-emit-llvm` output. The frontend, not the text IR, is what establishes the dialect the pass
   requires. Getting past the assert by hand-patching the layout only reaches a segfault, because
   the layout string is a symptom of the dialect, not the whole of it.

**What was concluded (and is wrong):** that options (b) and (c) were both impossible. The dialect
facts are right; the inference from them was not. ▶️ **P2 varied the one variable nobody had varied.**

## ◐ P2 — Integrate the pass with Zig. **Started 2026-09-23. The cheap route WORKS.**

### 🔑 Experiment 1 — the segfault was Zig's DEBUG mode, not Zig IR

| input to the pass | result |
| --- | --- |
| **hand-written** `.ll` with both layout lines, no Fil-C frontend involved | ✅ accepted (`-O0` and `-O1`) |
| Zig IR, layouts patched — **ReleaseSmall** (37 lines) / **ReleaseFast** (161) / **ReleaseSafe** (4,007) | ✅ **all accepted** |
| Zig IR, layouts patched — **Debug** (189,740 lines, 1,110 functions, **114 inline-asm blocks**) | ❌ segfault |

**So the whole integration is:** stock Zig emits IR → rewrite two `target datalayout` lines →
Fil-C's clang. **No Zig fork. No LLVM build.** `tools/p2/` has the scripts.

### ✅ Experiment 2 — THE MILESTONE. Zig object + C caller, both instrumented

`tiny.zig` (ReleaseSafe) → IR → layout rewrite → `filc clang -c`, linked with `c_caller.c` which
`malloc`s 4 ints and calls Zig's `zig_add(a, 4, 99)` — one past the end. Exit **133**:

```
in bounds ok, sum=6
filc safety error: cannot write pointer with ptr >= upper.   expected 4 writable bytes.
semantic origin:
    (prog1) tiny.zig:4:6: zig_add          <-- the fault is located IN THE ZIG SOURCE
check scheduled at:
    (prog1) tiny.zig:4:6: zig_add
    (prog1) c_caller.c:15:5: main
```

🎯 **This is the P1 milestone**: C allocates, Zig overflows, Fil-C traps, and the panic names the
Zig file, line and column. Cross-language capability enforcement, working today.

### ◐ Experiment 3 — a WHOLE Zig program links and runs, then traps in Zig's start code

With `-target x86_64-linux-musl` (KI-6) all three Release modes **link and run**. They panic before
`main`, inside `start.zig:547 expandStackSize`, which walks off the end of `envp` to find the ELF
aux vector — three separate capabilities under Fil-C, one flat array under Zig's assumption (KI-5).

▶️ **So zilc's first shipping shape is clear:** Zig exports C-ABI functions, C owns `main`.
Whole-Zig-program startup needs `start.zig` work, which is what "a zilc *target*" will eventually mean.

### ✅ Experiment 4 — **the `zilc` driver exists** (2026-09-23). One command, not a script

```
$ zilc build c_caller.c bounds.zig -o interop      # ZILC_ZIG / ZILC_FILC point at the tools
$ ./interop
in bounds ok, sum=6
filc safety error: cannot write pointer with ptr >= upper.
semantic origin:  bounds.zig:13:6: zig_add   ←  c_caller.c:26:5: main      exit 133
```

- `src/ir.zig` — the rewrite, **unit-tested** (9/9 green). Idempotent, and derives *both* layouts
  from the plain one. ⚠️ Two bugs the tests caught before any Linux run: a double `-ni:0` on
  re-rewrite, and a stray trailing newline.
- `src/driver.zig` — `.zig` → `zig build-obj -femit-llvm-ir` → rewrite → `filc clang -c`; `.c/.cpp/.o/.a`
  straight to Fil-C; then one link. `--keep-temps` leaves every intermediate.
- `src/main.zig` — `zilc build`, with the guardrails as first-class behavior: **Debug is refused
  with an explanation** rather than passed through to a compiler segfault, and a non-musl target
  warns (KI-4, KI-6).
- `examples/interop/` — the milestone as a real example, not a scratch file.

### ▶️ P2 remaining work
2. ✅ **Debug mode — DONE 2026-09-23.** Not inline asm (exonerated); it is an **optimizer × pass**
   interaction, since the same IR compiles at `filc -O0`. The driver now supports `-O Debug` by
   compiling the instrumented IR at `-O0` and passing `-fno-stack-check`, at a **108× size cost**
   (13.8 MB vs 127 KB). ▶️ Remaining: reduce the crash with `tools/p2/llreduce.ts` and report it
   upstream — a compiler segfault on valid input is Fil-C's bug, not ours. Detail: KI-4.
3. ✅ **Startup — DONE 2026-09-23.** Whole Zig programs run: the driver generates a C-ABI entry shim
   (`zilc_entry.zig` as root module, user file as `user`), so `start.zig` never enters the build.
   The real cause was **`@ptrFromInt(getauxval(AT_PHDR))`** — a pointer forged from an integer, which
   InvisiCap forbids outright — not the aux-vector walk first written down. Detail: KI-5.
4. ✅ **The safety gate — DONE 2026-09-23.** `zig build gate` builds all four examples with the
   driver and asserts each traps at the right file:line, with the right fault kind, on SIGTRAP.
   **4/4 green, and inversion-tested.** Skips with guidance where Fil-C is absent. Detail:
   `testing.md`.
5. **Only if the above hit a wall:** build Zig against Fil-C's LLVM (the heavy route, now clearly
   *not* the first thing to try).

### ▶️ What P2 has left

- **Upstream report** for the Debug/-O1 crash — drafted at `tools/p2/repro/UPSTREAM-REPORT.md`,
  **owner will file it** (owner, 2026-09-23).
- ~~`std.os.environ` is unset by the entry shim (KI-5)~~ ✅ set since 2026-10-02 (gate case 5).
- Then **P4**: Zig language fidelity, where `@ptrFromInt` across `std` is the interesting problem.

## P3 — `zilc_runtime` in Zig. Plan set 2026-09-30 · 🔁 **MOVED TO zailc, ABANDONED IN zilc 2026-10-27 (owner)**

🔒 Not zilc work (`design-decisions.md`, top row). Kept as the record zailc inherits.

Replace the C runtime with Zig, piece by piece, behind the same ABI the pass emits calls to.
**Exit criterion:** P2's gate still passes with no Fil-C C code linked.

**Method (owner, 2026-09-30).** Keep Fil-C's pass and its checked musl fixed and swap only the
runtime. The Zig runtime is linked **ahead of** `libpizlo`, so each function it defines replaces
Fil-C's and the rest still come from Fil-C. Every gate case is built under both runtimes and must
match on output, exit code, fault kind and fault file:line. The measured contract (294 `filc_*`, 1,032
allocator/GC, 335 `zsys_*`) is in `architecture.md` "The runtime contract".

🎯 **Two phases (owner, 2026-09-30): fidelity first, then streamline.**

1. **Fidelity.** Match upstream exactly before improving anything:
   - **User-program binaries byte-identical** under both runtimes. Same pass, same objects, same
     link line; only the runtime library differs. Check it with a hash comparison in the
     side-by-side gate. That also proves `--runtime zig` changed nothing but the runtime.
   - **The runtime held to identical observable results:** output, exit code, fault kind and
     file:line on every gate case and every `tests/basics` program. The runtime library itself
     cannot be byte-identical (new code, new compiler).
   - No optimisation, cleverness or "improvement" is allowed in this phase, even an obvious one.
     Record it as a candidate for phase 2.
   - 🔑 **The acceptance test (owner, 2026-09-30):** compile `hello.zig` with zilc against Fil-C's
     runtime, and again against the Zig port. **The two output binaries must be byte-identical.**
     Then the same check for every gate case and every `tests/basics` program.
   - ⚠️ **Found 2026-10-01 (KI-22): Fil-C's pass is NOT reproducible under ASLR.** The same
     prebuilt clang on the same IR gives different objects run to run, because the pass iterates
     hash tables keyed by pointer addresses. So every byte-identity check here must compile with
     ASLR off (`setarch -R`), use the **same compiler binary** for both sides, and still be
     re-checked for reproducibility first (two runs, same side). The acceptance test above is
     unaffected in principle (the two sides differ only in the runtime, not the compiler), but
     run naively it would fail for reasons unrelated to the runtime. Details:
     `workarounds.md` KI-22.
   - ⚠️ **Consequence for how the Zig runtime is linked:** a program embeds its runtime's soname
     (`NEEDED libpizlo.so`), the RUNPATH and the loader path (`filc-abi.md` §5). An *extra*
     `libzilc_rt.so` ahead of `-lpizlo`, as first planned, adds a `NEEDED` entry and breaks
     byte-identity. **So the Zig runtime must be a drop-in `libpizlo.so`: the same soname, the same
     exported symbols, the same install path.** `--runtime` then selects which `libpizlo.so` is
     installed at that path, not what is on the link line. ⚠️ Also: exported **data** symbols must
     keep their sizes, or the linker's copy relocations will differ.
2. **Streamline**, only after phase 1 is proven. Go beyond upstream, **smaller binaries** first.
   Binaries may then differ from Fil-C's freely, provided **the safety-guarantee results stay
   identical** (the same gate, the same traps, the same corpus results). Byte-identity with Fil-C
   stops mattering; the gate's results are what count.

**Switch:** `zilc build --runtime filc|zig` ✅ **exists 2026-09-30**. `zig` is reserved and refused
until ready. To be added: a gate option `-Druntime=filc|zig|both`, where `both` is the
side-by-side comparison, and a line from `--runtime zig` saying how many entry points are native,
so a mixed run is never mistaken for a fully native one.

🔭 **Scoping, 2026-09-30 (`filc-abi.md`, `tools/p3/`). It REORDERS the plan below.** Fil-C's
calling convention was decoded from post-pass IR. `pizlonated_X` is a *getter* that returns a
capability to a **function object**, and calls go through a fast or a generic entry using the
thread's cc buffers. So even one `zsys_*` replacement needs the **object-header format**,
**function objects** and the **generic calling convention**. **That shared layer is step 0.**
Linking looks straightforward: a `libzilc_rt.so` ahead of `-lpizlo` should override Fil-C's symbols
under standard ELF lookup, but that is not yet run. Open: whether a blocking system call must tell
the GC it is leaving managed code.

**Revised order (2026-09-30):**

0. **The ABI core:** object header, capability checks, function objects, the generic calling
   convention, the thread's frame push/pop. No `libpizlo` symbol is replaced yet. Tested by building
   a function object in Zig that Fil-C-compiled C code can call and get checked results from.
1. **The `zsys_*` OS boundary, one function at a time**, now on top of step 0. Each can be swapped and checked on its own,
   and it is the per-OS layer that P6 needs. ⚠️ To verify: whether Fil-C's exported checking helpers
   (`filc_check_*`, `filc_native_*`) are enough for a Zig wrapper.
2. **The pass → runtime entry points (`filc_*`):** check failures, reporting, calling-convention
   checks. Mostly stateless.
3. **The allocator + GC, all at once**, because it holds global state. The only check against Fil-C
   is whole-program (the gate plus side-by-side runs), with `lib_gcverify` as a GC reference.

✅ **Design docs read 2026-09-30** (`invisicap.txt`, `gimso_semantics.md`, `Manifesto.md`), which
closed most gaps in `filc-abi.md`. The header is `{size, aux}`; the aux array holds lowers or atomic
boxes; the exact checks; `inttoptr`'s capability rule; and the **FUGC protocol**: pollchecks, soft
handshakes, a store barrier, and **exit/enter around anything that blocks**. So step 0 also needs
the **thread state machine and pollcheck callbacks**; even a blocking `write()` touches the GC.

✅ **Probed 2026-09-30:** the pollcheck flag is a byte at **thread + 8**, masked `0x0E` → `filc_pollcheck_slow`, and blocking calls do **`filc_exit` → syscall → `filc_enter`** (`filc-abi.md` §3, §5b). ▶️ **Next:** the spike below, **re-aimed at step 0**. The ABI is now observed enough to start, once
open question #3 is settled (2026-10-01: new Zig code, licence-compliant, Fil-C source may be read).

▶️ **The spike, waiting for the owner's go-ahead:** the **`zsys_write` spike**. Override
`pizlonated_zsys_write` from a Zig static library in one gate case, confirm our version is the one
called, and require the gate to pass 4/4 under both runtimes. It answers two questions that decide
the link line: **(a) Fil-C's internal calling convention** (the `pizlonated_*` functions are not
normal C calls; `filc_cc_args_check_failure` is part of it), and **(b) linking**: Fil-C links its
libc as a shared library, so a replacement in a static archive may not get pulled in without
`--whole-archive` or passing object files directly.

⚠️ **Prerequisites:** open question #3 (✅ settled 2026-10-01: comply, do not avoid) had to be settled before runtime
code, and the Zig runtime must match Fil-C 0.685's object layout exactly (`design-decisions.md`).

## P4 — Zig language fidelity · 🔁 **MOVED TO zailc, ABANDONED IN zilc 2026-10-27 (owner)**

🔒 Not zilc work. zilc still keeps Zig compiling and running correctly under Fil-C on x86_64 Linux
(its role, item 3), but the mapping of Zig's pointer kinds onto capabilities is zailc's.

P1 tests whether Zig IR survives the pass at all. P4 makes it *right*. Define how Zig's pointer
kinds (slices, many-pointers, optionals, `allowzero`, `@ptrCast`, `@intFromPtr`/`@ptrFromInt`) map
onto capabilities, and how Zig's own safety checks interact with GIMSO. **Exit criterion:** a
Zig ⇄ C program where C overflows a Zig-owned slice and panics, across the full Zig test corpus.

## P5 — C++ and polish · 🔁 **MOVED TO zailc, ABANDONED IN zilc 2026-10-27 (owner)**

🔒 Not zilc work (`design-decisions.md`, top row).

libc++/libc++abi under the target, exceptions/unwinding, threads with atomic capability updates,
performance measurement against Fil-C.

## P6 — Platforms. ✅ ADOPTED 2026-09-30 (owner) · 🔁 **MOVED TO zailc 2026-10-27 (owner)**

🔒 zilc is Linux x86_64 only, worked in WSL or Linux (`design-decisions.md`, top row). The plan
below is the record zailc inherits; no row but Linux x86_64 is zilc work — not even Linux aarch64.

**Goal: Linux, macOS and Windows, on every currently prevalent processor; then iOS; Android
later.** ✅ Processors: **x86_64 + aarch64** per OS (owner). riscv64 is out of scope for now: a low-interest later candidate for the Linux row only, once the Zig runtime exists. Reasoning and limits
are in `design-decisions.md` open question #4.

| tier | platform | processors | what it depends on |
| --- | --- | --- | --- |
| 1 | **Linux** | x86_64 ✅ working · aarch64 | Fil-C ships both (`filc-<ver>-linux-aarch64`), so aarch64 needs only zilc's target handling; checkable against Fil-C |
| 1 | **macOS** | aarch64 (Apple silicon) · x86_64 (Intel) | **Fil-C has no macOS.** Needs the Zig runtime (P3), plus a checked OS layer over libSystem (macOS has no stable syscall ABI), Mach-O linking, and a Fil-C clang built for macOS hosts or cross-compiling |
| 1 | **Windows** | x86_64 · aarch64 | **Fil-C has no Windows.** The Zig runtime (P3), plus a checked layer over ntdll/kernel32, PE/COFF, SEH unwinding, LLP64, and std's TEB access via asm (a KI-5-style problem) |
| 2 | **iOS** | aarch64 | macOS's work plus code signing, no JIT/`mmap` exec, sandboxing |
| 3 | **Android** | aarch64 · x86_64 | Linux kernel, but **Bionic** instead of musl, so a checked libc layer over Bionic |

**Sequencing:** the scope pass below happens **before publishing `v0.15.2-3`**. The port efforts
come after publishing (`design-decisions.md`). Every non-Linux row depends on **P3**, the
runtime, because Fil-C's own runtime and libc exist only for Linux.

**✅ Scope pass DONE 2026-10-05 → `platforms.md`** (Linux aarch64: 4 small gaps, measured; upstream Fil-C now has a COSMO mode whose binaries run on macOS and x86_64 Windows, with a Linux-x86_64-compatible C ABI: evaluate it before writing any macOS/Windows runtime).

**Scope pass (pre-publish), per platform:** confirm the processor list; count the OS functions Zig's
std references (the size of the checked-wrapper layer); identify the libc story (C on that OS needs
a checked libc); find the std code that builds pointers from integers (KI-5 family); and work out the
host-toolchain question (which hosts can run the Fil-C pass).

The original order (still valid inside tier 1):

1. **Linux ARM64.** Fil-C supports it upstream. zilc hard-codes x86_64 as the default target
   (`driver.zig` `Options.target`, `main.zig`), and the IR tests only use an x86 triple. The `ni:0`
   insertion goes after the `m:` part of the layout, so it should carry over, but that is unverified.
   Also unverified: whether Fil-C publishes an ARM64 release.
2. **P3 finished on Linux**, since a portable runtime is what makes any other OS reachable.
3. **Count the OS functions Zig's std references** for `x86_64-windows` and `aarch64-macos`. That
   count is the wrapper workload, and it should be known before committing to either target.
4. **The first non-Linux target, Zig code only.** Expect KI-5-style traps wherever std's OS layer
   builds pointers from integers.

**Host side (separate from targets):** zilc's own code is portable Zig, but it needs Fil-C's clang,
which only ships for Linux. Running zilc on other hosts needs Fil-C's clang built for those hosts
(clang is already a cross-compiler), or P2 route (a), linking Zig against Fil-C's LLVM.
