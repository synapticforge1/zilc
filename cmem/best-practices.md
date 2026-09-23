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
- **A reopen condition is not self-checking.** Re-test it when you *price* the entry, not just when
  it was written.

## 3. Upstreams and claims

- **Run the cheapest experiment that can KILL the plan, first.** One afternoon of shell scripts
  falsified two of three integration routes for zilc and found the real constraint (KI-4). Reading
  the pass source had suggested the opposite — that "GIMSO accepts any LLVM module" meant any
  *producer's* module. It means any module **in Fil-C's dialect**. (zilc P1, 2026-09-23.)
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
- **Verify licenses per file, not per badge.** (Fil-C = `NOASSERTION` on GitHub, three licenses in
  practice; wasmtime's badge omitted its LLVM exception.)
- **Ask where the artifact goes, not where the file sits.** License obligations attach to what you
  distribute. For zilc, the runtime is distributed *inside users' binaries* (`licensing.md`).

## 4. Tests and gates

- **A "0 failed / 0 skipped" corpus is not "everything ran."** Count files that errored before
  producing results.
- **Every declared symbol needs a link-time gate.** Tests that call only what exists never notice
  what is promised but missing. (wazmrt audit #20: 180 such symbols.)

## 5. Tooling on this machine

- **Write source files with the file tools, not shell heredocs, when they contain backslashes.**
  A bash heredoc dropped one `\` from Zig's `\\` multiline-string prefix and broke `main.zig`.
  (zilc, 2026-09-18.)
- **Script in Deno or Bun, never Python** (owner, 2026-09-18). Tooling in `tools/` is `.ts`/`.mjs`,
  run with `deno run` or `bun`. This follows the project's memory-safety stance and matches
  wazmrt's Deno tooling.
