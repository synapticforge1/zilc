# Best Practices — the method rules

Every rule below was paid for, most of them in the sibling project **wazmrt**, whose
`cmem/best-practices.md` holds the full incident write-ups. Only rules that transfer to a
compiler/runtime project are copied here. Add new ones as zilc earns them: one bold rule plus a
citation to the incident.

**This file holds METHOD, not findings.**

---

## 1. Verifying a change

- **Diff the OUTPUT, not the exit code.** A gate that exits 0 while silently doing less is a
  regression. For zilc: a "safe" build of a bug example must panic *with the right fault*, not just
  exit non-zero.
- **An inversion that does not compile looks exactly like an inversion nothing caught.** When
  proving a check works by breaking it, first assert that the broken build *built*. (wazmrt, three
  sessions running.)
- **A single run that matches a recorded number to two decimals is a coincidence you can afford to
  check.** Performance claims need repeats and a stated noise floor. (wazmrt, 2026-08-19.)

## 2. Investigating a defect

- **Finding a real defect at a layer is not evidence that it causes your symptom.** Vary one thing
  at a time. (wazmrt KI: exFAT zig-cache, four misdiagnoses; zilc KI-2.)
- **When a reducer leaves something "innocent" behind, the reducer is missing a unit type, not the
  bug.** Teach it the missing unit (functions, then globals), then sweep the minimal shape's
  neighbours by hand with tiny probes until the rule is exact. (KI-18, 2026-10-01: a function-only
  reduction kept an innocent `syscall4`; adding globals found `i21` in 11 runs.)
- **To prove a compiler change is output-identical, compare INSIDE one run, not two binaries.**
  Fil-C's pass is not reproducible under ASLR, and two different builds of it lay out the heap
  differently, so byte comparison of their objects proves nothing on large inputs. Keep the old
  computation behind a switch and abort if the two disagree (KI-22's `ZILC_VERIFY_COLOURING`).
  Check the reproducibility of the BASELINE first (`setarch -R`, two runs).
- **Cap build parallelism to memory, not to cores.** 32 parallel `RelWithDebInfo` compiles of
  clang crashed the 31 GB WSL VM, and with it the WSL service, twice. `ninja -j 12` was fine.
  (2026-10-01.)
- **KI-1 again: never pass shell text containing `|` inline through PowerShell to WSL**, even in
  a "simple" wait loop. A `grep -E "a|b"` became shell pipes, and the watcher looped on errors
  for an hour. Put it in a script file. (2026-10-01.)
- **Before building a workaround for an upstream cost, read whether upstream already discards
  your input.** Option 3 (inserting lifetime markers for Fil-C) would have been real compiler work
  with miscompile risk, but the pass erases escaping allocas' markers before the analysis they
  were meant to speed up. One `grep` for how the pass treats the construct settled it. (KI-22,
  2026-10-01.)
- **Measure Debug separately; its std is different code.** Debug-only std behaviour
  (`unexpectedErrno` dumping stack traces) kept 56k lines of dead code in every Debug build after
  the Release builds were already clean. (KI-21, 2026-10-01.)
- **Name the repo in every git command (`git -C <absolute path>`), and never chain commands with
  `;` after one that can fail.** A `cd` into a new clone failed, the next commands ran in zilc
  itself, and a `fetch --filter=blob:none` silently turned zilc into a partial clone
  (`promisor`, `partialclonefilter`, format version 1). It was caught by reading `.git/config`.
  (2026-10-01.)
- **LF everywhere (owner): `* text=auto eol=lf` in `.gitattributes`, and `core.autocrlf=false` in
  any reference clone.** The global Windows `core.autocrlf=true` checked Fil-C out as CRLF, so every
  exact-text patch check failed, and per-extension rules let `.ts`, `.patch` and `.gitignore` slip
  through. (2026-10-01.)
- **When something reports total failure, suspect the instrument.** "0 matches" for all four patch
  edits, including a one-line anchor, was line endings, not upstream changes. Run a control (the
  known-good v0.685 file) before believing it. (2026-10-01.)
- **When a git (or any) task fails only on Windows, trace down to the CHILD command that fails
  and run it alone.** KI-23's "Permission denied" was not a lock held by another program. A
  plain `git multi-pack-index write` worked; it failed only as a child of `repack`, which held the
  file memory-mapped. `GIT_TRACE=1` showed the child in one run. Then read the next error too:
  "File exists" was a second, separate Windows/exFAT rename rule. (2026-10-01.)
- **When a fix lands, update EVERY issue it closes, in the same commit, and re-check before calling
  anything open.** KI-17's unoptimized route fixed KI-10's thread joins on 2026-09-30, but KI-10's
  heading stayed 🟡 and it was listed as open the next day. Before listing open items, check each
  label against the latest corpus results. (2026-10-01.)
- **Write the WHY of a workaround when you make it** (`workarounds.md`), keeping measured facts and
  surmises apart, and listing what was ruled out. (Owner rule, 2026-10-01.)
- **A reopen condition is not self-checking.** Re-test it when you *price* the entry, not just when
  it was written.

## 3. Upstreams and claims

- **⚠️ A DEFAULT IS A VARIABLE. Vary it before declaring anything impossible.** zilc spent a session
  concluding "Zig IR cannot enter Fil-C's pass" from runs that were all in Zig's **default Debug
  mode**. ReleaseSmall/Fast/Safe all work, and the milestone fell out within the hour. The route
  declared dead was the one that shipped. (zilc P1→P2, 2026-09-23.)
- **Run the cheapest experiment that can KILL the plan, first.** One afternoon of shell scripts
  falsified two of three integration routes for zilc and found the real constraint (KI-4). Reading
  the pass source had suggested the opposite — that "GIMSO accepts any LLVM module" meant any
  *producer's* module. It means any module **in Fil-C's dialect**. (zilc P1, 2026-09-23.)
- **⚠️ A function's NAME is not its mechanism — open it.** zilc wrote "Zig walks off the end of
  `envp` to find auxv" into a known-issues entry, inferred from the name `expandStackSize`. The code
  does `@ptrFromInt(getauxval(AT_PHDR))`: it **forges a pointer from an integer**, which is a
  different and far more fundamental conflict. The wrong write-up would have sent the fix hunting
  for a bounds problem. (zilc KI-5, 2026-09-23.)
- **Check for the boring explanation before the interesting one.** A print that "should" have
  appeared was missing before a trap, which looked like Fil-C hoisting checks across side effects —
  a serious semantic claim. Adding `fflush` showed both lines present: it was stdio buffering.
  (zilc, 2026-09-23.)
- **Automate the reduction; a 189,740-line crash is not a bug report.** Delta debugging took zilc's
  crash to 8 functions in 1,648 runs, unattended, and named the guilty subsystem
  (`std.compress.flate`) — something no amount of reading would have found. ⚠️ **Check the
  interestingness test first:** the first run reported "nothing to reduce" because clang's *driver*
  exits 1 when its frontend dies on a signal, so the 139 never reached the reducer. A reducer with a
  broken oracle fails silently and convincingly. (zilc P2, 2026-09-23.)
- **Exonerate the prime suspect before building the case on it.** zilc named inline asm as the cause
  of the Debug-IR crash in a written-up entry; two three-line probes showed Fil-C compiles inline asm
  fine in both C and IR. The real cause was an optimizer interaction, found by varying `-O` on the
  *consumer* side. (zilc P2, 2026-09-23.)
- **In a pipeline, `$?` is the LAST command's status.** `./prog | sed …` reports sed's exit code, so
  a test that asserts on the exit status silently asserts nothing. Redirect to a file, check the
  status, then format. (zilc, 2026-09-23.)
- **When a tool rejects your input, make it tell you what it wanted.** The exact data layout Fil-C
  requires came out of an error message from `-Xclang -disable-llvm-passes`, after three guesses
  from reading source had failed. (zilc, 2026-09-23.)
- **A "Benefit" line asserting what another project does is a HYPOTHESIS.** Open that project's
  source and grep for it before relying on it. (wazmrt wasm-c-api removal, 2026-08-11.) This applies
  directly to the vision's unverified claims (`vision.md`).
- **Verify a toolchain-version claim twice: in the upstream build files AND in the installed
  binary.** Zig 0.15.2's `CMakeLists.txt` said "LLVM 20", and `zig cc --version` on the real
  download confirmed clang 20.1.2 before the repo moved to it. A version match is what keeps IR
  readable across the Zig → Fil-C boundary, so neither check alone is enough. (zilc KI-3,
  2026-09-18.)
- **A minimum-version field is not a pin.** `minimum_zig_version` only rejects *older* Zigs. A
  newer one runs and fails with ordinary compile errors that look like code bugs. Name the required
  toolchain wherever build commands appear. (zilc, 2026-09-18.)
- **Measure the contract before planning the port.** Running `nm` over the prebuilt runtime
  turned "port Fil-C to Zig" from a guess into 294 + 1,032 + 335 named symbols in separable layers.
  That showed which layer could be swapped a function at a time and which could only be swapped
  whole. It took ten minutes and needed no source tree. (zilc, 2026-09-30, `architecture.md`.)
  ⚠️ **But symbol counts show SIZE, not COUPLING.** The same day, decoding one real call showed the
  "separable" OS layer depends on the object format shared with the GC, which reordered the plan.
  **Before sequencing a port by layer, trace one call end to end through the compiler's output.**
  (`filc-abi.md` §6.)
- **A parser that ACCEPTS your input may not have understood it. Print what it produced.**
  `std.SemanticVersion.parse("0.15.2_3")` succeeds, because `_` is a digit separator, and yields
  patch **23**, silently equal to `0.15.23`. Only printing the parsed fields exposed it. (zilc
  versioning, 2026-09-30.)
- **A fix that passes may be passing because of the optimiser. Re-test with the optimiser off.**
  zilc's overflow fold alone made `09_slices` pass in ReleaseSafe, only because clang inlined
  `fromPage` before Fil-C's pass. In Debug (`-O0`) it trapped again, which proved the std patch was
  still needed. For any fix that depends on code shape, run it in Debug **and** a Release mode.
  (zilc KI-13, 2026-09-30.)
- **Read the IR before believing a mechanism.** "An integer parameter loses its capability" was
  true but not sufficient; the IR showed overflow intrinsics breaking the chain inside the
  function too. One look at the actual `define` beat two rounds of reasoning. (zilc KI-13.)
- **Reserve a switch by refusing it, never by falling back.** `--runtime zig` exists but refuses
  to run, so no build can claim the new path while quietly using the old one. The same rule applied
  to Debug before it was supported. (zilc, 2026-09-30.)
- **Verify licenses per file, not per badge.** (Fil-C = `NOASSERTION` on GitHub, three licenses in
  practice; wasmtime's badge omitted its LLVM exception.)
- **Ask where the artifact goes, not where the file sits.** License obligations attach to what you
  distribute. For zilc, the runtime is distributed *inside users' binaries* (`licensing.md`).

## 4. Tests and gates

- **A "0 failed / 0 skipped" corpus is not "everything ran."** Count files that errored before
  producing results.
- **Every declared symbol needs a link-time gate.** Tests that call only what exists never notice
  what is promised but missing. (wazmrt audit #20: 180 such symbols.)
- **A comparison harness must give both sides the same world.** Same environment (start the
  program with `env -i` and a fixed list), same inputs, same working-directory layout; and run
  the reference twice to separate "differs" from "varies by itself". (Output comparison,
  2026-10-02: the harnesses' own variables were the only real difference.)
- **A resource probe must defeat the optimizer AND Fil-C's escape analysis.** Check that the
  native number is physically possible (a "195 MiB" recursion on an 8 MiB stack was a loop), and
  keep the measured locals from escaping, or Fil-C moves them off the machine stack. Use
  `noinline`, `@call(.never_tail, …)`, `std.mem.doNotOptimizeAway`. (KI-5 stack probe, 2026-10-02.)
- **Prove "same code" like for like, and prove the comparison can tell.** Compare against a
  reference built from the SAME input in the same form, not against a run whose own output
  varies; show the variation with a harmless perturbation (a timing-only flag) and a
  deterministic control. And keep LLVM use-list order (bitcode with use-lists, no text round
  trip, no cloning) wherever machine code must match: it changes register allocation.
  (KI-22 lever (a), 2026-10-02: 80+ functions "differed" until both were fixed; then 2,840/2,840.)

## 5. Tooling on this machine

- **Write source files with the file tools, not shell heredocs, when they contain backslashes.**
  A bash heredoc dropped one `\` from Zig's `\\` multiline-string prefix and broke `main.zig`.
  (zilc, 2026-09-18.)
- **Script in Deno or Bun, never Python** (owner, 2026-09-18). Tooling in `tools/` is `.ts`/`.mjs`,
  run with `deno run` or `bun`. This follows the project's memory-safety stance and matches
  wazmrt's Deno tooling.
- **Every generated input a recorded result depends on needs its exact recipe written down, next
  to the tool that reads it.** "Made during P1" is not a recipe. The commands for three P1 IR files
  had to be recovered by trial (one was `build-exe -lc`, readable only from the file's own
  `output_mode` and `link_libc`); two scripts had silently copied inputs from a vanished scratchpad.
  Commit small inputs; for big generated ones, record the command and a checksum. (tiny-ni2.ll,
  2026-10-05.)
- **A harness that captures a program's output must keep stdout and stderr in ONE stream.** Read
  through two pipes, the lines of a program writing to both come out in a different order each run;
  the shell's `> f 2>&1` shares one file and keeps the order. `tools/lib/tool.ts` `run()` does the
  same (`exec "$@" 2>&1` in the child). (39_logging, 2026-10-05: it "differed" until fixed; nine
  more programs then matched native exactly.)
- **A shell script whose usage line says `sh` must run under dash.** `export -f` (bash-only)
  makes dash exit 2 with no message. Test with `sh -x`. (zilc-check.sh, 2026-10-02; the tools
  have been Deno since 2026-10-05, but the rule holds for any shell script that remains.)
- **Stopping a WSL command from the Windows side does not stop its Linux processes.** A
  "killed" background job kept running and polled on; check `ps` in WSL after a timeout, and
  give long jobs a long timeout up front. (2026-10-02.)
- **Exact-match patch text must keep upstream's trailing whitespace.** The file editor trims a
  whitespace-only line, and an edit's "original" then matches 0 times. Check suspicious lines
  with `cat -A`; fix them with `sed`, and mark them in the edit script. (KI-22 lever (b),
  2026-10-02: a six-space line in `FilPizlonator.cpp`.)
