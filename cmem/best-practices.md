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
- **Reserve a switch by refusing it, never by falling back.** `--runtime zig` existed but refused
  to run (2026-09-30 → 2026-10-27, removed when P3 moved to zailc), so no build could claim the new
  path while quietly using the old one. The same rule applied
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
- **Script in Bun only: never Deno, never Python** (owner, 2026-10-22; was "Deno or Bun",
  2026-09-18). The owner says Deno is going away. Tooling in `tools/` is `.ts`/`.mjs`, run with
  `bun tools/<group>/<tool>.ts`; all of it was ported from Deno on 2026-10-22. Use Node's APIs
  (`node:fs/promises`, `process`) plus `Bun.spawn`/`Bun.Glob`/`Bun.YAML`, never `Deno.*` or
  `jsr:` imports. Bun lives at `~/.bun/bin/bun` in WSL (the first-time step in `tools/README.md`).
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
  have been Deno since 2026-10-05 and Bun since 2026-10-22, but the rule holds for any shell script that remains.)
- 🛑 **Never execute anything built by Fil-C, cosmo or zilc on the Windows host** (owner,
  2026-10-08). The machine runs SentinelOne; on 2026-10-05 running cosmo APE files as `.exe` from
  Claude's Windows scratchpad got them quarantined and Claude Code killed. Run programs in WSL; the
  Windows half of an APE only under `wine64` inside WSL; no WinDbg here. Why and evidence:
  `workarounds.md` "Nothing built by Fil-C or cosmo is ever EXECUTED on the Windows host".
- **Stopping a WSL command from the Windows side does not stop its Linux processes.** A
  "killed" background job kept running and polled on; check `ps` in WSL after a timeout, and
  give long jobs a long timeout up front. (2026-10-02.)
- **Exact-match patch text must keep upstream's trailing whitespace.** The file editor trims a
  whitespace-only line, and an edit's "original" then matches 0 times. Check suspicious lines
  with `cat -A`; fix them with `sed`, and mark them in the edit script. (KI-22 lever (b),
  2026-10-02: a six-space line in `FilPizlonator.cpp`.)

## 6. The workspace ★ rules (copied verbatim)

The convergent rules of the workspace this repo sits in (owner, 2026-09-20: every repo carries
them; workspace letters H6, H26). They are copied, never edited here: a change is made in the
canonical file and re-copied. Section numbers are the canonical file's; the gaps are its non-★
rules, which are not copied. Proof of the copy: a text comparison of all 28 rules (number +
normalized text), not a count. Where a rule repeats one in §§ 1–5 above, both stand: the ones
above carry zilc's own incidents.

Copied from synapticforge1/cmem/best-practices.md on 2026-10-27

### §1 Evidence and measurement

- **1.1 ★ An exit code is not evidence; diff the OUTPUT counts, per file.** Exit-0 runs silently
  dropped passes in four repos; binaryen-ts's serious defects were valid wasm with the wrong value;
  wabt-ts's `wat2wasm` silently deleted an instruction. [wabt-ts + binaryen-ts + wazmrt + wasmtk + wasmrt]
- **1.2 ★ A green suite is evidence about the tests, not the code.** The fuzzer had zero `makeLoad`
  / `makeBreak`; `deno test tests/` collected 513 of 908 and exited 0. [binaryen-ts + wabt-ts]
- **1.3 ★ Re-derive before quoting any number; a count in prose is a dated claim.** Counts were
  cited eight days stale; artifacts doubled while "smallest binary" was the goal; three commit
  messages contradicted their own diffs. [every repo]
- **1.4 ★ When the corpus can move, the denominator is a measurement, and a comparison must print
  it.** The failure total matched on both sides by coincidence after +4 files; four totals were
  computed over zero modules because `--enable-all` is not a `wasm-opt` flag. [wasmrt + binaryang]
- **1.11 ★ Validate the harness against a known positive; an extreme number is evidence about the
  harness, and a broken harness can score BETTER.** 1937/1937 failing; give it an input it must
  fail on. [wabt-ts + binaryen-ts]

### §2 Gates and tests

- **2.1 ★ A new test that has never failed has not been shown to test anything: invert it and
  watch it fail for the RIGHT reason.** A baseline probe appended a WAT comment and could not fire;
  deleting the release guard left twelve tests green; a mutant caught by a different check is a bad
  mutant. [wazmrt + wabt-ts + binaryen-ts + binaryang + wasmtk]
- **2.3 ★ A gate that cannot fail is decoration; a gate with no trigger, a goal with no gate, a
  gate that only prints, and a property asserted in a doc comment are all preferences.** `| tail`
  swallowed the oracle monitor's status; `check-bridge-corpus.ts` exited 0 either way; "exhaustive
  over `Op`" ended in `_ => return None` and shipped four ungated ops. [wazmrt + wasmrt + binaryang]
- **2.4 ★ The local gate must BE CI's gate: read the steps from the workflow file.** 65 unpushed
  commits were red by CI's standard; `tasks.md` went binary to grep from NUL bytes because the
  hygiene gate was scoped to what the compiler reads, not what the workflow reads. [binaryang + wabt-ts]
- **2.16 ★ A change's own new surface is the one place the audit that produced it will not look —
  re-run the governing audit against the new members before landing.** The `--update-baseline` path
  OOMed; the day's own suites passed throughout six silent CLI regressions. [wazmrt + wasmrt + wasmtk]

### §3 Producer/consumer pairs and oracles

- **3.1 ★ A round trip proves agreement with yourself; when a bug is visible only to a third party
  the test has to BE a third party — hand the bytes to an outside reader as a GATE, not a habit.**
  Legacy EH: wabt-ts parsed it, V8 ran it, wasi 417/417 green, wasmtime rejected all ten modules;
  `(ref any)` emitted as an internal tag byte and `try_table`'s label off by one in assembler,
  validator and interpreter alike — wasmtime refused both in one afternoon. [wazmrt + binaryen-ts + wabt-ts + wasmrt + wasmtk]
- **3.2 ★ Agreement between components that learned the convention from each other is not
  evidence, and there can be three.** Decoder and encoder shared a catch-depth off-by-one; every
  round trip was byte-identical and green. [binaryen-ts + wabt-ts + wazmrt + wasmrt]
- **3.3 ★ Producer/consumer pairs are the recurring blind spot; fix the gap, not a post-process
  workaround, and pin both directions.** T13.22 cancelling off-by-ones across a repo boundary,
  invisible for four releases; fixing one direction turned silent accept into loud reject. [binaryang + wazmrt + wabt-ts]
- **3.8 ★ A stale vendored snapshot is indistinguishable from live data without recorded
  provenance: stamp source + date in the change that creates it, and never let a check read an
  artifact it did not just produce.** A 2020 `proposals/threads/` snapshot was filed against us; a
  frozen 272-file copy filed seven "invalid" modules that run clean; a size gate read yesterday's
  artifact. [wabt-ts + wasmtk + wasmrt + wazmrt]
- **3.10 ★ A claim about another project's code is a hypothesis until you grep their source; a
  stated BENEFIT is a hypothesis about someone else's code.** "wabt-ts accepts try_table" (the
  writer could not encode it); the wasm-c-api "drop-in" payoff never existed — the loaders use
  `wasmtime_*`. [wasmtk + wasmrt + wazmrt]

### §4 Where defects hide

- **4.1 ★ One authoritative enumeration; a second copy drifts into silence; one reader per grammar
  production, and a production has more than one site.** `deepCopy` covered 29 of 79 kinds; the heap
  type table existed three times; a private `skip_const_expr` refused two valid modules; reftype was
  read as valtype at the table-type site for the project's whole life. [binaryen-ts + wabt-ts + wasmrt + wazmrt]
- **4.2 ★ A value read and discarded is a decision; a wrong decode made harmless by a guard in
  another file is a load-bearing coincidence.** `r.readU32(); // table index`; three reserved bytes;
  `br_on_cast` flags, the elemkind byte, element flags `8`. [binaryen-ts + wabt-ts + wasmrt]
- **4.3 ★ Silent-wrong output is the worst class and where every serious defect has been: ask "what
  would a wrong answer look like?" first, and prefer a hard error over a stub.** A feature can be
  decoded, validated, printed and never execute (the start function, five releases). [wasmrt + wasmtk + wabt-ts]
- **4.16 ★ A rationale expires; the code it justified does not: a comment justifying a deviation
  names the authority it defers to; "by design" and "out of scope" age badly by definition; a stale
  rationale is worse than none.** "Mirroring the oracle" survived the oracle's retirement five weeks;
  the `import.meta.main` ban's reason expired while the rule stayed right for another reason.
  [wasmrt + wazmrt + binaryang]

### §5 Investigating

- **5.1 ★ Prove, do not assume: prove the REASON, not just the answer; UNVERIFIED is a legitimate
  status.** Four read-not-verify claims were wrong when run; a `--features` alias rationale was
  right by luck. [wazmrt + wasmrt]
- **5.2 ★ Identify the LAYER before naming a cause; the stage that REPORTS a failure is usually
  not the stage that caused it; finding a real defect at a layer is not evidence it causes your
  symptom — vary one thing.** "Memory-grow ordering" was decoder reordering; a symptom caused by the
  development drive's FILESYSTEM (exFAT) was diagnosed wrong three times. [wazmrt + binaryen-ts + wasmtk + wasmrt]

### §6 Recording and claims

- **6.1 ★ A written result is a CLAIM: a commit message, a status line, a doc of a safety guard, a
  contract row verified by reading. Compare it to the artifact; put a pin where the tool enforces
  it.** `8d9ba0cb9` (was `b8fafaa3f` before binaryang's 2026-10-23 purge; corrected here 2026-10-26, ledger C8) said "pin to 132" and left 116; prose has no failure mode. [binaryang + wabt-ts + wasmrt]
- **6.2 ★ Write down the thing you only said out loud; write the negatives (what was varied, what
  held fixed), the calibration, and what you did NOT check; distinguish clean / measured /
  UNMEASURED.** Knowledge that exists only in a conversation is operationally identical to
  knowledge nobody has. [wabt-ts + binaryang]
- **6.3 ★ Record findings that were WRONG so they are not fixed again; a retraction re-checks the
  REASONING, not the requirement; a correction is a dated claim too; a reopen condition is not
  self-checking.** [wazmrt + wasmtk + binaryen-ts + wabt-ts]

### §7 Tooling that lies

- **7.1 ★ Do not author file CONTENT through a shell heredoc; scripts go in files, always; commit
  messages through `-F <file>`.** Four corruption modes (escapes eaten, long commands truncated,
  backticks substituted, `$$` templates), five corruptions including a NUL byte in `.gitattributes`;
  broken five times by the rule's own author. [binaryang + wasmtk + wazmrt + wasmrt]
- **7.2 ★ When the exit code IS the measurement, do not pipe.** `deno fmt --check | tail -1`
  committed a failing check; `| tail -20` swallowed the oracle monitor. [wasmtk + wasmrt + wabt-ts]
- **7.3 ★ A change that silently does nothing is indistinguishable from one that worked: prefer
  "fail if absent" over "act if present"; edit scripts assert each match exactly once; read back;
  omission is not reset.** Seven no-ops in one register (replace without asserting the target, an
  omitted workspace key, a `--dry-run` that bumped). [binaryang + wazmrt + wasmrt]
- **7.6 ★ Line endings: pin in `.gitattributes` wildcard-first; measure with a positive control;
  never fix with `git config`; test inputs whose bytes feed a digest are never whitespace-trimmed.**
  `grep -c '\r'`=140, `grep -c $'\r'`=0, `grep -cU $'\r'`=184 on the same file. [wasmtk + binaryang + wazmrt + wasmrt]

### §8 Working across repos

- **8.1 ★ Read freely, write never: nothing is written into a sibling's tree — not its source, not
  its `cmem/`, not its copy of the contract — unless the owner directs that write, and then it is
  logged in both memories.** Two destructive overwrites on 2026-08-19; a commit that laundered
  authorship. [wasmrt + wazmrt + binaryang + wabt-ts]
