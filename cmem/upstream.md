# Upstream — tracking Fil-C

**Upstream:** https://github.com/pizlonator/fil-c, default branch **`deluge`**.
**Pinned at project start (2026-09-18):** `cd830ff67170486aaa74c253ae6ba665a2a601b5`.
**Site/docs:** https://fil-c.org/

The Fil-C repo is a **full llvm-project fork** (llvm, clang, lld, lldb, mlir, flang, libcxx…) plus
Fil-C's own directories. GitHub's license detector reports it as `NOASSERTION` because the tree is
multi-licensed (see `licensing.md`).

## Files that matter to zilc

| Upstream path | What it is | License |
| --- | --- | --- |
| `llvm/lib/Transforms/Instrumentation/FilPizlonator.cpp` | **The pass.** "Apply GIMSO semantics to LLVM IR" | Apache-2.0 WITH LLVM-exception |
| `clang/` (Fil-C diffs vs clang 20.1.8) | Frontend changes; size TBD | Apache-2.0 WITH LLVM-exception |
| `libpas/src/libpas/filc_runtime.c`, `filc_*.c/h` | **The runtime** | BSD-2-Clause |
| `libpas/` (rest) | Allocator substrate, incl. FUGC | BSD-2-Clause |
| `filc/include/stdfil.h` | Public Fil-C API header for programs | BSD-2-Clause |
| `filc/tests`, `filc/run-tests` | **Test corpus**, a candidate conformance suite for zilc | BSD-2-Clause (verify per file) |
| `projects/usermusl`, `projects/yolomusl` | The two-level libc | MIT |
| `yolounwind/` | Unwinder | verify |
| `invisicap.txt`, `invisicaps_by_example.md`, `gimso_semantics.md`, `Manifesto.md` | **Design docs**, read first | n/a (docs) |
| `README.md` | Build and license overview | n/a |

Excluded: `projects/*` other than the musl pair, `pizlix/`, and the glibc variant (see
`third_party/LICENSES.md` → Copyleft exclusion).

## 🔄 Upgrade procedure: Fil-C first, then the latest Zig (owner, 2026-09-30)

Every upgrade runs in **three stages**. Stage A produces a known-good **reference**, stage B is
checked against it, and stage C benchmarks all of them. Nothing moves to the latest Zig without
first passing on the Zig that matches Fil-C.

### Stage A: follow Fil-C to the COMPATIBLE Zig (the reference)

1. Record the new upstream SHA **and the prebuilt release version** (0.685 today) here, with the date.
2. **Check Fil-C's LLVM version** (`cmake/Modules/LLVMVersion.cmake`; 20.1.8 at the pinned SHA).
   Find the Zig release whose bundled LLVM has **the same major**. That is the *compatible Zig*
   (0.15.2 ↔ LLVM 20 today; verify in Zig's build files **and** with `zig cc --version`, per
   `best-practices.md`).
3. Diff only the files in the table above between the old and new SHA. Port the changes to anything
   zilc has adapted (see the ledger) and update each ledger entry's pinned commit. Re-measure the
   runtime contract (`architecture.md`), since a changed object layout breaks the P3 runtime.
4. Move the repo to the compatible Zig, if it changed. Re-run `zig build test` and `zig build gate`
   until they pass.
5. **Freeze the reference:** record the gate output, test count and stage-C numbers for this
   pair (Fil-C version + compatible Zig).

### Stage B: port to the LATEST Zig, if it is a different release

1. On **the new line's own branch, created from the latest reference release's tag** (the
   **basis**; one branch per Zig line, `releasing.md`), port zilc to the latest Zig, so the conversion is as small as possible. Start from the previous line's entry in
   `ports/<version>.md`, and follow `design-decisions.md` invariant 4 (fix the counted
   version-sensitive sites, keep the layout). The result is a new line, `<latest Zig>-1`, whose
   release notes name the basis (`releasing.md`).
2. ⚠️ **Only the Zig that builds zilc moves.** The Zig that compiles user code (`ZILC_ZIG`) stays on
   the compatible release, because Fil-C's LLVM has to read its IR. This procedure is what puts the
   two-Zig split into practice (invariant 4).
3. **Compare against the reference:** same tests passing, and **identical gate results**: every
   case traps with the same fault kind at the same file:line. Any difference is a porting bug until
   shown otherwise.
4. **One recorded experiment:** try the latest Zig as `ZILC_ZIG` too. IR from a newer LLVM major is
   expected to be rejected by Fil-C's LLVM. If it isn't, that's worth knowing, but it is not relied
   on.
5. **Write the port notes** in `ports/<version>.md` while the port is fresh: every API change hit, the
   fix, and which sites it touched. **Later changes** to the reference line are carried to the
   latest line the same way, and each resulting release names its new basis.

### Stage C: benchmark comparison between versions

Compare **previous reference → new reference (A) → latest-Zig port (B)**, on the same machine:

| metric | why |
| --- | --- |
| run time of each benchmark program, zilc vs. plain `zig` (baseline) | **zilc's own slowdown figure**, which `vision.md` still lists as unmeasured |
| run time, version vs. version | did an upgrade make the checked code slower or faster |
| `zilc build` wall time per program | compile-time cost of the upgrade |
| binary size (ReleaseSafe and Debug) | Debug is already 108× (KI-4); watch it |

⚠️ Performance claims need **repeats and a stated noise floor** (`best-practices.md` §1). A benchmark
suite does not exist yet (`testing.md`, planned gates).

## Git remote

Not added yet. How Fil-C enters the repo (subtree, submodule, sparse checkout of the paths above, or
reference-only) is open question 6 in `design-decisions.md`. A sparse, blob-filtered clone keeps
the llvm-project history out:

```sh
git clone --filter=blob:none --sparse https://github.com/pizlonator/fil-c.git
git -C fil-c sparse-checkout set llvm/lib/Transforms/Instrumentation libpas filc projects/usermusl projects/yolomusl
```
