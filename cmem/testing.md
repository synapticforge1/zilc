# Testing

The gates, their commands and dated counts. Split on 2026-11-23 (letter H38 step 5):
[testing-corpus.md](testing-corpus.md) (`tests/basics`, the output comparison, the benchmark suite)
and [testing-filc-suite.md](testing-filc-suite.md) (Fil-C's own suite against zilc's clang).

## 🎯 `zig build gate` — THE SAFETY GATE (new 2026-09-23). **10/10 green** (2026-11-23: + interop in two steps, f128 in a -c object; 2026-10-02: + KI-5 environ, 3 library-mode cases)

Builds every example with the zilc driver and asserts each one **traps at the right source line**.
This is the gate the whole project exists to keep green.

| #   | case                                     | traps at              | fault          |
| --- | ---------------------------------------- | --------------------- | -------------- |
| 1   | interop: C allocates, Zig overflows      | `bounds.zig:13:6`     | `ptr >= upper` |
| 2   | whole Zig program (generated entry shim) | `hello.zig:25:6`      | `ptr >= upper` |
| 3   | C out-of-bounds write                    | `oob_write.c:15`      | `ptr >= upper` |
| 4   | C use-after-free                         | `use_after_free.c:13` | `free object`  |

**Each case asserts four things**, because any one alone is fakeable: the process died on **SIGTRAP**;
the output contains `filc safety error`; the `semantic origin` names **that file:line**; and the
violation is of the expected **kind**. ⚠️ _Exit status alone accepts a crash for the wrong reason —
and a `-O0` link failure earlier in this very session produced an equally non-zero exit for a
completely unrelated reason (a missing stack probe)._

✅ **Inversion-tested 2026-09-23:** with one expected origin changed to a line that does not exist,
the gate **failed** and printed the real panic. A gate that cannot fail proves nothing.

```sh
bun tools/run-gate.ts            # from a WSL or Linux shell (the tools run inside Linux only)
ZILC_FILC=…/build/bin/clang ZILC_ZIG=…/zig zig build gate    # the same, by hand
```

⚠️ **Where Fil-C is absent the gate SKIPS and exits 0**, printing what to set. A build that never had
a chance to pass must not read as a failure — but that also means _a green `zig build gate` on
Windows means nothing_. Read the first line.

## 📌 Experiment inputs that live outside the repo (record, owner 2026-10-05)

The phase experiments (`tools/p1`–`p3`) read some inputs from the Linux work area, not the repo.
All are committed sources EXCEPT three generated Zig IR files in `$WORK/p1` (≈12 MB each). Their
exact Zig 0.15.2 commands were recovered on 2026-10-05 and verified to reproduce the originals
(same code; only 3 debug-info lines differ: the build directory, and the hash of Zig's cache folder
for `builtin.zig`):

- `$WORK/p1/tiny.ll` — `tools/p1/tiny.zig`
  - how: `zig build-obj -target x86_64-linux-gnu -femit-llvm-ir=tiny.ll -fno-emit-bin tiny.zig` (in `$WORK/p1`)
- `$WORK/p1/zig_oob-x86_64-linux-gnu.ll` — `tools/p1/zig_oob.zig`
  - how: `zig build-exe -target x86_64-linux-gnu -lc -femit-llvm-ir=zig_oob-x86_64-linux-gnu.ll -fno-emit-bin zig_oob.zig`
- **`tiny-ni2.ll`** (`$WORK/p1`, copied to `$WORK/p2`) — `tiny.ll`
  - how: `bun tools/p1/zig-ir-spike.ts`; read by `tools/p2/dialect-probe.ts` part C. **The one input with no committed source of its own**

The full notes are in `tools/p1/README.md` and `tools/p2/README.md` ("Record: tiny-ni2.ll") and in
both tools' headers. Found during the Deno conversion: two experiment scripts used to copy inputs
from a session scratchpad that no longer existed and silently ran on leftovers; they now use the
committed copies.

## Current gates (re-run 2026-10-27 in WSL on Fil-C 0.687, commit `b33b6eb`: gate 8/8, tests 29/29, capi-smoke and baseline exit 0, `zilc --version` ok/ok; the same on 0.686 that morning)

**Every gate runs locally; CI runs none** (owner, 2026-11-17, letter H37 (e); since 2026-11-19).
`tools/release/release.ts` runs them before it pushes: the review gate first, `bump.ts --check`,
the privacy gate, `zig fmt --check`, Biome, `zig build test`, `bun test tools/release/ tools/lib/` (2026-11-23:
**132 pass, 1 skip** — the live GitHub render test, opt-in with `ZILC_LIVE_RENDER=1`; 27 against a
mock GitHub API, the rest the release guards in `guards.test.ts`), and the Fil-C gate below
(`release.md` § "What runs where"). From 2026-11-12 to 2026-11-19 CI ran the no-Fil-C half
(first run 43295657634 on `bba102f`).

- `zig build gate` — Every bug example traps at the right line; the library-mode example runs (needs Fil-C)
  - State: **10/10** (2026-11-23 on Fil-C 0.687; 2026-10-05 on Fil-C 0.686; 2026-10-02, KI-5 environ and library mode added; earlier 4/4 with the parallel code generation of KI-22 lever (a))
- `zig build test` — Runtime module + CLI module + the IR rewrites (incl. the KI-18
  three-byte-global wrap) + the std-overlay patches (incl. the KI-21 guards) + the runtime values
  (`filc` only; `zig` refused 2026-09-30, removed 2026-10-27) + the version round-trip + the object
  cache key and `--clean-cache` (KI-22 lever c)
  - State: **29/29** pass (2026-10-05, incl. `--clean-cache`, the KI-20 note, the version facts and the `0.15.2-0.686.1` scheme)
- `zig build capi-smoke` — `tests/capi_smoke.c` links `zilc_runtime` via `zilc.h` and calls it
  - State: pass
- `zig build baseline` — Builds `examples/*.c` with plain `zig cc`
  - State: builds. `baseline_oob_write` prints `a[3] = 3`, exit 0: **the undetected bug**

All gates were re-verified on **Zig 0.15.2** after the toolchain move (2026-09-18). Run them with
that Zig, not the `zig` on PATH, **inside Linux** (a WSL shell here; owner, 2026-10-27), with the
cache in the Linux home because the repo is on exFAT (KI-2, KI-3):

```sh
export ZIG_LOCAL_CACHE_DIR=~/.cache/zilc-zig
Z=~/zilc-work/tools/zig-0.15.2/zig
~/.bun/bin/bun tools/run-gate.ts
$Z build test --summary all
$Z build capi-smoke
$Z build baseline
```

Re-run 2026-10-27 this way, before and after the Linux-only tools change: gate 8/8, tests 29/29,
capi-smoke and baseline exit 0, every line of the gate's output identical. (Until 2026-10-27 the
commands ran with Windows' Zig, `C:\zig\0.15.2\zig.exe`, and the cache `C:\zig-cache\zilc`.)

## 🎯 THE EXPECTED OUTPUT IS RECORDED (2026-09-23) — Fil-C 0.685 on our two examples

Measured in WSL with `build/bin/clang -O2 -g` (`roadmap.md` P1 step 2). **Both exit 133** (SIGTRAP):

| example                  | fault line                        | Fil-C's message                                                          |
| ------------------------ | --------------------------------- | ------------------------------------------------------------------------ |
| `oob_write.c:15:14`      | store one past a 4-int allocation | `cannot write pointer with ptr >= upper.` / `expected 4 writable bytes.` |
| `use_after_free.c:13:20` | read after `free`                 | `cannot access pointer to free object.` / `expected valid capability.`   |

Both end with `filc panic: thwarted a futile attempt to violate memory safety.` and print a
`semantic origin` with **file:line:column** plus a stack of `check scheduled at:` frames.

🔑 **The gate should assert the fault KIND and the file:line, not the exit code.** Fil-C gives both,
and 133 alone would accept a crash for the wrong reason.

### ✅ The Zig ⇄ C gate, measured 2026-09-23 (`tools/p2/milestone.ts`)

`c_caller.c` allocates 4 ints and calls Zig's `zig_add(a, 4, 99)`. Exit **133**:

```
in bounds ok, sum=6
filc safety error: cannot write pointer with ptr >= upper.   expected 4 writable bytes.
semantic origin:      tiny.zig:4:6: zig_add
check scheduled at:   tiny.zig:4:6: zig_add  ←  c_caller.c:15:5: main
```

🎯 **The fault is attributed to the Zig line, from a C call site.** That two-frame trace is the real
assertion for the interop gate — it proves the capability crossed the language boundary intact.

⚠️ **Gate-building constraints, all load-bearing (see `known-issues.md`):** target **musl** (KI-6);
let **C own `main`** (KI-5); **Debug works but costs ~108× in size** (KI-4), so gates should run
ReleaseSafe by default and Debug only where the size is acceptable.

| optimize mode                           | binary       | same panic?          |
| --------------------------------------- | ------------ | -------------------- |
| ReleaseSafe                             | 127,424 B    | ✅ `bounds.zig:13:6` |
| Debug (`filc -O0` + `-fno-stack-check`) | 13,766,024 B | ✅ identical         |

⚠️ **When scripting a gate, capture the exit status before piping.** `./prog | sed …` reports
_sed's_ status, and the exit code is half of what these tests assert. (Cost us one confusing
"run exit=0" on a run that had clearly trapped.)

## The pure-Zig track's oracles (2026-10-27)

Byte for byte against Fil-C's own build, for the release zilc is on (`roadmap.md` Z1), in WSL:

- forwarder generator = Ruby's `generate_pizlonated_forwarders.rb` — `bun tools/gen/verify-forwarders.ts`
  - 0.687 result: both files SAME (45,695 B, 983,629 B)
- musl header install = `make install-headers` — `bun tools/gen/verify-musl-headers.ts`
  - 0.687 result: 219 files identical
- the same bytes, pinned — `zig build test` (`src/gen/forwarders.zig`)
  - 0.687 result: SHA-256 + size; **unit tests 40/40** (29 + the generators' 11)
- libpas's stock half, `filc_crt.o`, `filc_mincrt.o`, `libyolounwind.a` = the release tarball's — `bun tools/runtime/verify-libpas.ts`
  - 0.687 result: **178/178 objects define exactly upstream's global symbols**; 1 known undefined
    difference (W-4); 16 assert-presence differences (budget 16); source paths in upstream's form;
    the three small pieces SAME
- yolo musl's static half = the release's — `bun tools/runtime/verify-yolomusl.ts`
  - 0.687 result: **1,343 members in upstream's order**, each defining upstream's symbols, binding
    included; 28 with compiler-only undefined differences (budget 28, W-8); 1,342 compile-unit names
    equal + 1 empty TU (budget 1); crt objects, `libyolom.a`
- compiler-rt = the release's — `bun tools/runtime/verify-compiler-rt.ts`
  - 0.687 result: **167 members in upstream's order**, exactly upstream's symbols, **0 departures** (`_Float16` off, as the release: W-10); 14 objects with compiler-only undefined differences (W-8)

The three tables these build from are regenerated per release (`bun tools/runtime/import-libpas-sources.ts`,
`import-yolomusl-sources.ts`, `import-compiler-rt-sources.ts`; the last needs `ninja` on `PATH`:
`~/zilc-work/tools/ninja`). 0.687: libpas 174 C + 1 generated + 1 assembly; yolo musl 1,343 libc
members, 5 crt, 2 ldso; compiler-rt 167 builtins (3 assembly). The libraries install under
`~/zilc-work/pure-zig/filc-0.687/lib`.

After a Fil-C move: `bun tools/gen/import-signatures.ts`, then the two oracles, then re-pin the
SHA-256 values Ruby printed.

## The gate with pure-Zig modules (`zig build gate-zig-modules`, 2026-10-27)

**Owner, 2026-10-27:** after a Fil-C update has passed every checklist item, the same build runs
again "by just swapping out the fil-c specific modules with the pure zig modules", as a `build.zig`
step (`design-decisions.md`, top row). Run in WSL:

```sh
ZILC_FILC=~/zilc-work/tools/filc-<release>-zilc/build/bin/clang ZILC_ZIG=~/zilc-work/tools/zig-0.15.2/zig \
  zig build gate-zig-modules -Dzig-modules=<dir with lib/> -Dzig-modules-filc=<release>
```

`tools/swap-modules.zig` (built and run by `build.zig`) copies the `ZILC_FILC` toolchain to
`-Dzig-modules-out` (default `~/zilc-work/zig-modules/filc-<release>-zig-modules`; the repo is on
exFAT), replaces every file of `pizfix/lib/` that `<dir>/lib/` has under the same name, then asks
the copy's clang for its default link line (`clang -###`) and marks each module **PURE ZIG,
linked** / **pure Zig, but NOT in the default link** / Fil-C's. The gate (`tools/gate.zig`,
unchanged) then runs against the copy. The table is written to the copy's `ZIG-MODULES.txt`. For
the corpus and the output comparison, run those tools with `ZILC_FILC` set to the clang it prints.

⚠️ **Swapped is not used:** Fil-C's clang links dynamically, so `-lc`, `-lpizlo`, `-lyoloc` resolve
to the `.so` files; a swapped `libyoloc.a` changes nothing. Only what the link line names counts.

**Refuses (exit 1):** without `-Dzig-modules`; when `-Dzig-modules-filc` is not the release the
toolchain's own `clang --version` names; when no file would be swapped; when no swapped module is
linked.

**First run, 2026-10-27** (Fil-C 0.686, zilc's patched clang; the pure-Zig modules read from
zailc's step-2 build at `~/zailc-work/out`, as a test input — nothing written there): 13 of 32
modules swapped, **9 linked** (`Scrt1.o`, `crti.o`, `crtn.o`, `crtbegin.o`, `crtend.o`,
`filc_crt.o`, `libyolom.a`, `libyolort.a`, `libyolounwind.a`); not linked: `libyoloc.a`, `crt1.o`,
`rcrt1.o`, `filc_mincrt.o`; `libpizlo-stock.a` ignored (half of `libpizlo`, no module of that
name). **Gate 8/8**, every case trapping at the same file:line. Still Fil-C's in that run: the
shared runtime (`libc.so`, `libpizlo.so`, `libyoloc.so` and its loader `ld-fil1-x86_64.so`) and
libc++. Refusals measured: no `-Dzig-modules` → exit 1; declared 0.687 on a 0.686 toolchain →
exit 1; a directory with no Fil-C module names → exit 1.

**On 0.687 with zilc's OWN pure-Zig modules, 2026-10-27** (`build/pure_zig.zig`, installed at
`~/zilc-work/pure-zig/filc-0.687`; zilc's patched 0.687 clang as the base): the same 13 swapped and
**9 linked**; **gate 8/8**. The checklist's corpus and output comparison against the same swapped
toolchain (`ZILC_FILC` = the copy's clang; `zilc-check.ts` hands `filc()`, i.e. `ZILC_FILC`, to zilc
— the logs do not print the path, so that is read from the code): **78/78 as designed in all four
modes**, the designed 7 by name; output comparison **0 unexplained** (`{same 501, expected 55,
varies 68, variesBad 0, differs 0}`). Unit tests 40/40, plain gate 8/8 on the same tree.

**With yolo musl's shared half, 2026-10-27** (`libyoloc.so`, which is also the loader
`ld-fil1-x86_64.so`; `cmem/workarounds.md` W-11): `verify-yolomusl.ts` OK, with 1,653 exports
equal by name and type, 0 undefined, dynamic tags equal, segment kinds equal but for the allowed
`PHDR` / `GNU_PROPERTY`, and the entry at `_dlstart`. Then **14 of 32 swapped, 10 linked**
(`libyoloc.so` added); **gate 8/8**; corpus with the swapped clang **78/78 as designed in all four
modes**, C and Zig; output comparison **0 unexplained**, with the same totals as above. Unit tests
40/40, plain gate 8/8. Fil-C's still in the default link: `libc.so`, `libpizlo.so`.

## Planned gates

1. **Bug-example gate** (invariant 2 in `design-decisions.md`): every `examples/*.c` built with the
   zilc target must reproduce the table above — same fault kind, same line. Checking the exit code
   alone would pass a crash for the wrong reason.
2. 🔁 **ABANDONED in zilc 2026-10-27** (P3 moved to zailc, `design-decisions.md` top row; zilc
   has no runtime of its own to compare). Was: **Fil-C differential → `zig build gate -Druntime=filc|zig|both`** (shape set 2026-09-30,
   `roadmap.md` P3). Each case is built under Fil-C's runtime and zilc's (`zilc build --runtime`).
   Output, exit code, fault kind and file:line must match. This becomes the proof of P3, and it
   stays meaningless until `--runtime zig` is enabled.
3. 🔁 **Not zilc's since 2026-10-27** (owner: zilc stays on the compatible Zig, always; kept as a
   recommendation, `upstream.md`). Was: **Version comparison (2026-09-30).** Stage B of an upgrade (`upstream.md`): zilc built by the
   latest Zig must produce **identical gate results** to the stage-A reference built by the
   compatible Zig. The gate already takes `ZILC_ZIG`/`ZILC_FILC`, so this needs two zilc builds
   and a comparison of the two reports, not a new gate. Worth automating once it has been done by
   hand once.
4. ✅ **Benchmark suite — BUILT 2026-11-06** (planned 2026-09-30 for upgrade stage C; owner
   2026-11-05: _"upstream's plus our zig only ports of upstreams plus new ones that we write to
   test the zig only version specifically"_). See "Benchmark suite" below.
