# Fil-C in zilc: from the stock release to a pure-Zig build

This file is **the record of how zilc gets from base (Fil-C's stock release, run as it ships) to
pure-Zig parity (every piece of Fil-C built by Zig from Fil-C's own sources and shown equal to the
release)**. zailc builds on that record: it starts where parity is reached and keeps its own
departures from Fil-C. [Zig.md](Zig.md) is the same record for Zig's side.

It holds four things:

1. the base, meaning the release zilc is pinned to and what it is made of;
2. what running the base takes, meaning machine needs, zilc's patched clang, every workaround, and
   the defects that are Fil-C's own;
3. the route to parity, piece by piece: how upstream builds each piece, how Zig builds it here, what
   proves the two equal, and which differences are allowed;
4. how to redo the whole thing for the next Fil-C release.

Defects that belong to Fil-C are written up for its maintainers in
[UPSTREAM-ISSUES.md](UPSTREAM-ISSUES.md), and appear here only as a line pointing there. The full
reasoning behind each workaround is in `cmem/workarounds.md` (KI and W numbers); the defect log is
`cmem/known-issues.md`.

## 1. The base

| | |
| --- | --- |
| **Fil-C release** | **0.687** (released 2026-10-23), the musl flavour, Linux x86_64 |
| **Compiler commit** | `e7947f079c976fb167108f7407c20240bca0ca89`, the one 0.687's clang names in `clang --version` (5 commits under the `v0.687` tag, with no compiler change between them) |
| **LLVM** | 20.1.8. This pins the Zig version (see [Zig.md](Zig.md)) |
| **Prebuilt** | `filc-0.687-linux-x86_64.tar.xz`, SHA-256 `aab538401f78a47ab261ee79afed8c6b99e1d4848e263ae159a75b03c1288da1` (Fil-C publishes none; recorded at download) |
| **Installed at** | `~/zilc-work/tools/filc-0.687-linux-x86_64` by `tools/p1/setup-wsl.ts` ([tools/README.md](tools/README.md) "First-time setup") |
| **Source tree** | `~/zilc-work/filc-src/repo`, a sparse, partial clone of Fil-C's LLVM fork at the compiler commit (`git@github.com:pizlonator/llvm-project-deluge.git` for 0.687; 0.686 named `fil-c.git`, same history) |
| **zilc release** | `0.15.2-0.687.1`. The version names the Fil-C release (`<Zig>-<Fil-C>.<zilc release>`) |
| **Platform** | **Linux x86_64 only**, by design (on Windows, inside WSL). Cross-platform work belongs to the sibling project zailc |

### What the base is made of

The release tarball is the oracle for every piece on the route. Who built each piece, and with
which compiler, decides which differences a Zig build may show (§ 3).

| piece | what it is | upstream builds it with |
| --- | --- | --- |
| clang + `FilPizlonator` pass | the compiler; the pass turns every pointer into a checked capability | LLVM's CMake |
| `libpizlo.so` | the capability runtime and the FUGC collector. Its **stock half** (libpas, the yolo side) is plain C, and its **Fil-C half** (`filc/src`) is compiled by Fil-C | make with clang, then Fil-C's clang |
| `libyoloc.so` = `ld-fil1-x86_64.so` | the runtime's own libc ("yolo musl"), **also the dynamic loader** | musl's make, **GCC 12.3** |
| `libyoloc.a`, `libyolom.a`, `crt1.o`/`Scrt1.o`/`rcrt1.o`/`crti.o`/`crtn.o` | yolo musl's static half | musl's make, GCC 12.3 |
| `libyolort.a`, `crtbegin.o`, `crtend.o` | compiler-rt, the runtime side | compiler-rt's CMake, **GCC 11.4** |
| `libyolounwind.a`, `filc_crt.o`, `filc_mincrt.o` | unwinder and Fil-C's crt objects | make with clang |
| `libc.so` | the user libc: a patched musl **compiled by Fil-C** | Fil-C's clang |
| libc++, libc++abi | C++, compiled by Fil-C | Fil-C's clang |
| `filc_native.h`, `filc_native_forwarders.c` | the native ↔ user forwarders | a Ruby generator |
| musl's installed headers, `stdfil.h`, `pizfix/os-include` | headers; `os-include` links to the machine's kernel headers | `make install-headers`, `setup.sh` |

Fil-C's link is dynamic by default, so a program loads `libpizlo.so`, `libc.so` and `libyoloc.so`
(the loader).

## 2. Running the base

### What the machine needs

- **Linux x86_64**, natively or in WSL2. Nothing Fil-C builds is ever run on the Windows host,
  because that machine's security software quarantines it (`cmem/workarounds.md`).
- **Kernel headers** under `/usr/include`, installed before Fil-C's `setup.sh` runs.
  `pizfix/os-include/asm` must resolve, or every program that includes `<linux/…>` fails to
  compile. `tools/filc/fix-os-include.ts` repairs a stale link, and `tools/filc/check-toolchain.ts`
  checks it.
- **patchelf**, for Fil-C's `setup.sh`; `tools/p1/setup-wsl.ts` installs it without root.
- **To build zilc's patched clang:** `build-essential`, `cmake` and Ninja (in
  `~/zilc-work/tools/ninja`); about an hour at `JOBS=12` (more crashed the WSL VM).
- **Ruby** (3.3.8 here), only as the oracle that proves the pure-Zig forwarder generator
  byte-identical to Fil-C's Ruby one.
- **Fil-C's own test suite**, cloned at the release (`~/zilc-work/filc-tests-0.687`) and run by
  `tools/filc/run-filc-tests.ts`, a Bun port of Fil-C's Ruby runner. None of it is redistributed.

### zilc's patched Fil-C clang

zilc recommends it, and uses it by default whenever it is installed. It is **Fil-C 0.687's clang
rebuilt from the same commit with three changes to Fil-C's code**. The edit scripts
`tools/filc/patch-pass.ts` and `tools/filc/patch-split.ts` are the source of truth, and the diff is
`third_party/filc-patches/zilc-filc-pass.patch`. None of the changes alters the code emitted for
anything the stock clang already compiled: Fil-C's own suite gives the same result with both
clangs on all 7,269 tests (0.687).

| change | why | record |
| --- | --- | --- |
| `indirectbr` lowering: one `switch` per `indirectbr` when a function has several | the stock pass crashes at `-O1` on Zig's Debug IR (computed gotos) | KI-4 |
| frame-slot colouring in linear time (+ a dense interference graph) | the stock colouring is cubic in function size, so large Zig programs took minutes | KI-22 levers (b) |
| a `--zilc-part` mode for `llvm-split` | parallel code generation after the pass has run on the whole module, so the code stays the same | KI-22 lever (a) |

`tools/filc/build-patched-clang.ts` builds it, and `toolchain/` keeps a local archive (gitignored;
the clang is never distributed). `tools/filc/restore-patched-clang.ts` restores it.

### Workarounds zilc applies for Fil-C

| what zilc does | why (Fil-C's side) | record |
| --- | --- | --- |
| Rewrites the two `target datalayout` lines of Zig's IR into Fil-C's dialect (`ni:0` on address space 0, plus `datalayout_after_filc`) | Fil-C's IR is a patched-LLVM dialect, and the pass refuses stock IR | KI-4, `src/ir.zig` |
| Wraps globals whose value type has a 3-byte store size (`i21`, `<3 x i8>`, …) in a one-field struct | the pass asserts `!(CSize % WordSize)` on them | KI-18 (upstream issue 1) |
| Compiles Debug builds at `filc -O1`, not `-O0` | at `-O0`, syscall pointer arguments arrived without a capability; `-O1` needs the patched clang (KI-4) | KI-19 |
| Generates the program's entry (a C-ABI `main` calling Zig's) instead of Zig's `start.zig` | `start.zig` forges a pointer from an integer (`getauxval(AT_PHDR)`), which InvisiCap forbids | KI-5 |
| Rewrites raw `syscall` inline asm into a call to a checked helper, `zilc_syscall` | Fil-C refuses inline asm, and a raw syscall would also skip the GC's safepoint protocol | KI-7 |
| Compiles the 128-bit float helpers (26 compiler-rt files) through the pass when a module uses `fp128` | Fil-C's user side does not provide them: `__multf3`, `roundq`, … are undefined at link time | KI-9 |
| Targets `x86_64-linux-musl` by default | Fil-C's libc is musl; a gnu target fails to link on the `*64` symbols | KI-6 |
| Passes `-fno-stack-check` to Zig | Fil-C checks the stack at every function entry itself, and `__zig_probe_stack` would be undefined | KI-8 |
| Splits big modules after the pass and generates their code in parallel; caches Fil-C's objects | instrumented code takes long to build | KI-22 levers (a), (c) |
| Never byte-compares two Fil-C builds without fixing ASLR | Fil-C's output is not reproducible under ASLR, so compare inside one run (`ZILC_VERIFY_COLOURING`) | KI-22 |

The hooks zilc puts into Zig's std concern Zig code under Fil-C's rules; they are in
[Zig.md](Zig.md).

### Defects in Fil-C itself

Each is written up for Fil-C's maintainers in [UPSTREAM-ISSUES.md](UPSTREAM-ISSUES.md) and
re-checked against every new release:
- **KI-4:** a segfault in `FilPizlonatorPass` at `-O1`/`-O2`, on Zig's Debug IR. **Still in stock
  0.687.** zilc's patched clang fixes it.
- **KI-18:** an assertion on 3-byte globals. **Still in stock 0.687.** zilc's driver wraps such
  globals.
- **`_Float16` conversions in the release's `libyolort`** (W-10). GCC 11.4 built the release's
  compiler-rt without `_Float16` support, so `__extendhfsf2` and `__truncsfhf2` read a different
  register than the one LLVM passes. **Still in 0.687.** zilc leaves it unfixed because it stays
  faithful to the release, and parity means parity with this defect too. zailc carries a fix.
- **C++ exceptions:** a `landing_pad_impl` assertion when an inlined destructor writes a global
  (W-7, found in zailc on 0.686). Not yet re-checked on 0.687.

## 3. The route to pure-Zig parity

### The rules (owner, 2026-10-27)

- **Faithful, with no departures.** Each piece is built from the pinned Fil-C tree with upstream's
  own recipe, and nothing is fixed along the way. zailc keeps the departures.
- **The recipe is imported from upstream's files, never retyped.** A Bun importer reads Fil-C's
  Makefile, configure or CMake output into a generated Zig table (`src/runtime/*_sources.zig`,
  carrying upstream's SPDX), and fails loudly if the text it relies on has changed.
- **Every piece has an oracle against the release tarball:** same bytes where the output is
  generated, the same defined symbols where it is compiled. Undefined-symbol differences that only
  the two compilers explain are allowed **by name, with an exact count** (a ratchet), and are
  recorded in `cmem/workarounds.md`.
- **Then the swap gate:** `zig build gate-zig-modules` reruns the safety gate with the release's
  same-named `pizfix/lib` files replaced by Zig's, and probes the link line (`clang -###`) to say
  which swapped files a program actually links. Then the corpus (`tools/basics/all-modes.ts`) and
  the output comparison against native run with the swapped clang, and Fil-C's own suite last.

### Piece by piece (Fil-C 0.687, 2026-10-27)

| piece | upstream's recipe → imported by | Zig build | proof | allowed differences | status |
| --- | --- | --- | --- | --- | --- |
| forwarder generator | `generate_pizlonated_forwarders.rb` → ported to Zig, signatures by `tools/gen/import-signatures.ts` | `zilc-gen` (`src/gen/`), `zig build gen` | `tools/gen/verify-forwarders.ts`: **byte-identical** to Ruby's (456 native + 13 user signatures); SHA-256 pinned in `zig build test` | the banner names the Ruby script (W-1) | ✅ |
| musl header install | `make install-headers` → `src/gen/musl_headers.zig` | `zilc-gen` | `tools/gen/verify-musl-headers.ts`: **byte-identical**, 219 files | none | ✅ |
| libpas stock half, `filc_crt.o`, `filc_mincrt.o`, `libyolounwind.a` | `libpas/common.mk` `PASSRCS` → `import-libpas-sources.ts` | `zig build libpas` | `verify-libpas.ts`: the release's defined symbols, object by object | `pas_panic` undefined in one object (W-4) | ✅ |
| yolo musl, static half | musl's Makefile + configure → `import-yolomusl-sources.ts` | `zig build yolomusl` | `verify-yolomusl.ts`: the release's members (`.lo`, 1,343) and their symbols | GCC/clang libcall and helper differences (W-8) | ✅ |
| compiler-rt (`libyolort.a`, `crtbegin.o`, `crtend.o`) | `build_compiler_rt.sh`'s CMake options, run once under `zig cc` → `build.ninja` read by `import-compiler-rt-sources.ts` | `zig build compiler-rt` | `verify-compiler-rt.ts`: the release's members and symbols, **no extra definition** | W-8; the `_Float16` defect kept (W-10) | ✅ |
| yolo musl, shared half (`libyoloc.so`, the loader) | musl's `lib/libyoloc.so` rule and configure's `LDFLAGS_AUTO` → `import-yolomusl-sources.ts` | `zig build yolomusl`, linked by `zig ld.lld` | `verify-yolomusl.ts`: the release's 1,653 exports (name and type), no undefined symbols, the same dynamic tags, segment kinds, entry at `_dlstart` | `PHDR` (LLD) against `GNU_PROPERTY` (GCC's notes) (W-11) | ✅ |
| the rest of `libpizlo` (`filc/src`), the user libc, libc++ | compiled by Fil-C's clang | not started | | | ⬜ |
| a program linked only from Zig's outputs, then Fil-C's suite on it | | | | | ⬜ |
| **Z2:** the pass itself (`FilPizlonator`, KillUB, DeleteRedundantPollchecks) in Zig | | not started (zailc has not started it either) | the same module through both passes, compared as IR and as behaviour | | ⬜ |

The forwarder generator and the header install are generated output, so they match byte for byte.
The other built pieces match by symbol, because upstream's compilers (GCC 12.3, GCC 11.4, clang
20.1.8) are not Zig's clang 20.1.2.

**Where the swap stands (2026-10-27):** 14 of the release's 32 `pizfix/lib` files are Zig's, and
10 of them are in a program's default link, the loader included. Gate 8/8, corpus 78/78 as designed
in all four modes, output comparison 0 unexplained. `libc.so` and `libpizlo.so` are still Fil-C's,
because they are the Fil-C-compiled pieces.

### The shared half: what it took (2026-10-27; W-11)

- **The link:** upstream runs `$(CC) … -nostdlib -shared -Wl,-e,_dlstart -o $@ $(LOBJS)
  $(LDSO_OBJS) $(LIBCC)`, with configure's seven `LDFLAGS_AUTO` (`--sort-section=alignment`,
  `--sort-common`, `--gc-sections`, `--hash-style=both`, `--no-undefined`, `--exclude-libs=ALL`,
  `--dynamic-list=dynamic.list`). `zig cc` refuses the last two as unsupported linker arguments,
  so zilc calls `zig ld.lld` (Zig's LLD) directly, with the flags taken from configure.
- **`--exclude-libs=ALL` does not mean the same thing in zilc's link.** Upstream links loose `.lo`
  objects, and the only archive it links is `$(LIBCC)` (libgcc), so `ALL` hides only the compiler
  runtime's symbols. zilc links yolo musl as an archive (`--whole-archive libyoloc.a`), so `ALL`
  also hid all of libc: the first link exported 8 symbols where the release exports 1,653. The
  equivalent of upstream's effect is `--exclude-libs=libyolort.a`.
- **What remains different is the linker's, not libc's.** Once the exports matched, the dynamic
  tags matched too. Two segment kinds still differ. LLD gives a shared object a `PHDR` segment and
  GNU ld does not. The release has `GNU_PROPERTY` because every one of its GCC-built objects carries
  `.note.gnu.property` (x86 ISA-used notes), and Zig's clang emits none. Both are allowed by name.

## 4. Redoing it for the next Fil-C release

1. Follow the release checklist (`cmem/releasing.md`) and the upstream review (`cmem/upstream.md`;
   0.686 and 0.687 are written up there). `tools/upstream/check-upstream.ts` says whether zilc's
   patches still apply.
2. Rebuild the patched clang, and run Fil-C's suite with the stock and the patched clang: **0
   differences**.
3. Move the source tree to the new compiler commit (`tools/lib/tool.ts` `FILC_SHA`), and re-run
   every importer (`tools/gen/import-signatures.ts`, `tools/runtime/import-*.ts`). An importer that
   fails means upstream changed its recipe, and the failure says where.
4. Re-run every oracle in the table above against the new tarball. A changed count of allowed
   differences is a finding, not a number to update.
5. `zig build gate-zig-modules`, the corpus and the output comparison with the swapped clang.
6. Update this file and [Zig.md](Zig.md).

## Licences

Fil-C's compiler is Apache-2.0 WITH LLVM-exception, its runtime BSD-2-Clause, and its musl MIT.
The generated tables keep the SPDX of the upstream files they are read from.
[third_party/LICENSES.md](third_party/LICENSES.md) and [NOTICE](NOTICE) list what zilc carries of
each, and where.
