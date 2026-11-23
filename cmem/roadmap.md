# Roadmap

The pure-Zig track, the one open line of work. P0–P6 (done, or moved to zailc) moved on
2026-11-23 to `archive/roadmap-p0-p6-to-2026-10-27.md` (letter H38 step 4).

> 🔒 **2026-10-27 (owner), as settled by the end of the day:** P0–P2 are done; P4, P5 and P6
> moved to zailc and are abandoned here, and so is P3 _as a different runtime_. **Open in zilc:
> the pure-Zig track below** — zailc's build up to a pure-Zig implementation running in Linux
> (owner: _"all of zailc's build to the point of pure zig implemenation running in linux should be
> in zilc"_). Alongside it, zilc's standing role (`design-decisions.md`, top rows): track Fil-C,
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
      two members). Found on the way: F-2, F-3, F-4, C-13. ✅ C-13's yolomusl check, done
      2026-11-06 (owner: "proceed with C-13"): no `__FILE__` strings there at all; the
      `./` spelling differed only in DWARF line tables, fixed in `buildYoloMusl` (the
      generated include dirs keep their cache path, debug info only; toolchain-quirks C-13).
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
    - [ ] **sarcasm, Fil-C's assembler, in ZIG** (owner, 2026-11-06: "Port sarcasm to Zig";
      `design-decisions.md` top row). What it is (measured 2026-11-06): `projects/sarcasm`,
      28 Luau modules, 34,398 lines (x86_64: parse 2,669, isa 2,032, codegen 1,693, fp
      1,693, frame 8,934, glue 724, render 954; shared: transform 5,243, sarcasm 1,873,
      localcall 965, tailcall 744, ptrflow 696, regalloc 639, lift 293, sig 236, detect 169,
      frame 134, numlabel 108, emit 97, build 88, err 87, prof 51; arm64 six modules 4,276 —
      NOT ported: zilc is Linux x86_64 only), plus DESIGN.md (200 KB), README, ABI notes.
      Run by Fil-C's clang for every `.s` input as `pizfix/bin/sarcasm [--x86_64|--arm64]
          [-g] IN.s -o OUT.o` (a Luau script under minilute, which then runs `as`); `-S` writes
      the rewritten assembly instead — the oracle. Corpus: Fil-C's own `filc/tests`, 1,431
      `.s` files (`sarcasm-*-att`, `-int`, a few `-arm`). Plan: (S0) the oracle,
      `tools/sarcasm/compare-sarcasm.ts`: upstream's `sarcasm -S` against the port's on every
      corpus file, output, diagnostics and exit code byte for byte; upstream against itself
      first (determinism); (S1) the port, module by module in dependency order, each stage
      checked against upstream's by a Luau harness under minilute that dumps the stage's
      result canonically for every corpus file, the Zig side dumping the same; (S2) `zig
          build sarcasm` → `pizfix/bin/sarcasm`, then MODE=zig drops minilute and upstream's
      sarcasm, Fil-C's suite (which runs those tests end to end) and compare-chains 14/14.
      Until S2 is proven, upstream's sarcasm on minilute stays (built by upstream's scripts).
      **S0 measured 2026-11-06** (a one-off run, upstream's `sarcasm -S` twice over the 1,431
      files, 16 at a time): **deterministic** — 0 files differ between the two runs in output,
      diagnostics or exit code; 939 accepted, 492 rejected (the rejection tests check the
      diagnostics, so those must match too); 303 are arm64 inputs; ~0.56 s per file under
      minilute. Fil-C's x86_64 driver always passes `--x86_64`, so the oracle runs the corpus
      that way, as the driver does (an arm64 file is then a rejection on both sides).
      ✅ S0's oracle committed-to-be: `tools/sarcasm/compare-sarcasm.ts` (self-check 1,431 /
      0 differ). ✅ Foundation 1 (Luau's table, the iteration order the output depends on):
      `src/sarcasm/luau_table.zig`, proven against Luau by `check-luau-table.ts` (32,912
      traversals equal, inverted). The porting map, foundations and progress live in
      `cmem/sarcasm-port.md`. ✅ Foundations 2 (number formatting, 211,424 doubles equal) and 3
      (Lua patterns, sarcasm's 189 literal patterns × 601 corpus subjects equal), each proven
      against Luau and inverted. ✅ Foundation 4 (tonumber, musl's strtod incl. its hexfloat in
      f80). ✅ Modules err, sig, detect, numlabel and the parser (parseString), each proven
      against upstream's own Luau module by `tools/sarcasm/check-stages.ts` (detect 1,431
      files, sig 487 annotations, parse 61,518 statement dumps: 0 differ; each inverted).
      ✅ (2026-11-07) x86_64_fp and x86_64_isa: stages isa (39,257 corpus dumps), isasyn
      (398,810 synthetic instructions), fplookup (12,169 names), 0 differ; ten planted faults
      all caught. ✅ (2026-11-07) prof, frame, lift, ptrflow, regalloc: stages lift (68,705
      lines) and framecalls (every frame-context call of the real policy replayed, 25,230
      lines), 0 differ, inverted. Next: x86_64_frame, x86_64_codegen, transform; the `.byte`
      decoder when compile needs it. Progress: `sarcasm-port.md`.
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

> 🔁 _Superseded 2026-10-27 (the roadmap is closed for zilc, above)._ **Updated 2026-09-30.** P3 has a plan (Linux first, the Zig runtime checked against Fil-C, the
> `--runtime` switch already in the CLI), and a proposed **P6 — other platforms**. Next step: the
> `zsys_write` spike, or P4, whichever the owner picks.

> **Updated 2026-09-23 (twice — read the P2 section).** WSL arrived, P1 ran, and its step-3 verdict
> ("the wrapper-driver route is dead") was **REVERSED by P2 the same afternoon**. ✅ **THE P1
> MILESTONE IS MET:** a Zig object and a C caller, both through Fil-C's pass, panic correctly with
> the fault located **inside the Zig source**. No Zig fork and no LLVM build were needed.

## The toolchain (P1's ✅ Step 1 — environment, 2026-09-23, WSL2 Ubuntu 26.04; kept live 2026-11-23)

Everything lives in the WSL home, **nothing installed system-wide, no root used**:

- Fil-C **0.685** — `~/zilc-work/tools/filc-0.685-linux-x86_64`
  - note: prebuilt release; `setup.sh` run; `build/bin/clang` reports `clang 20.1.8 (Fil-C 0.685 …bb0d0a64)`
- Zig **0.15.2** — `~/zilc-work/tools/zig-0.15.2`
  - note: official tarball, SHA-256 verified; `zig cc` = clang 20.1.2
- patchelf 0.19.1 — `~/zilc-work/tools/bin`
  - note: `setup.sh` needs it; `sudo` needs a password, so it was installed from the upstream prebuilt tarball instead
- Deno 2.9.7 — `~/.deno/bin`
  - note: pre-existing; ran zilc's tools 2026-10-05 → 2026-10-22, no longer used
- Bun 1.4.4 — `~/.bun/bin`
  - note: 1.4.3 from 2026-10-22, from npm's `@oven/bun-linux-x64` tarball (no `unzip`/root needed),
    SHA-256 checked (by `tools/p1/setup-wsl.sh` until 2026-10-27; since then the documented step in
    `tools/README.md` "First-time setup"). **1.4.4 since 2026-11-07** (updated on the machine; pin
    moved, owner): the installed binary is byte-identical to npm's 1.4.4 tarball's, whose SHA-512
    equals the registry's `dist.integrity`; every stage and gate re-run under it. Runs zilc's tools

⚠️ `sudo` on this WSL requires an interactive password, so **an agent cannot apt-install anything.**
Prefer no-root prebuilt binaries.
