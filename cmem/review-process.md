# review-process.md — zilc's slots in the workspace review standard

🔒 **Owner, 2026-11-12 (workspace letter H35):** one review process everywhere —
`../cmem/review-process.md`, from S3D-ReportCompiler. "review", "security review", "hardening
review" each run in rounds by fresh, read-only reviewers and **stop when a round's reviewers find
nothing**; **a security review and a hardening review are required before every release**, recorded
in that release's entry in [release.md](release.md) before the bump. The PROCESS is the workspace
file's and is not copied here; this file fills its **[project]** slots for zilc (§ 7 there).

## The owner's words (beside "commit" / "push" / "release", `working-rules.md` § Owner commands)

| the owner says | it is | none of them commits, pushes or releases |
| --- | --- | --- |
| **"review"** | a targeted agent code review, workspace § 2 | |
| **"security review"** | a security review, workspace § 3 | |
| **"hardening review"** | a hardening review, workspace § 4 | |

## The slots

**Private data a reviewer never reads (§ 1.1, § 5):** `cmem/local/` (gitignored, machine facts);
`.claude/`; anything outside the clone except the read-only siblings it is pointed at. A reviewer
works in its own scratch folder; in WSL that is under `~/zilc-work/` (WSL's `/tmp` was seen
emptied between invocations, 2026-11-12). 🛑 It never executes anything built by Fil-C, cosmo or zilc on
the Windows host (`workarounds.md`): every run is in WSL or Linux.

**The worst silent case (§ 1.2):** **a memory-unsafe program that zilc compiles and that runs
without trapping** — an out-of-bounds, use-after-free or type-confused access Fil-C would have
stopped, let through by zilc's driver, its pass patches or a pure-Zig piece. Next: a pure-Zig
piece whose output differs from Fil-C's (a sarcasm stage, a runtime module, the link) while every
test passes. Both rank above any crash.

**The reference results that must still hold (§ 1.3.4)** — each a dated count in `testing.md` /
`open-work.md`, re-derived before quoting:

| set | command | holds at |
| --- | --- | --- |
| the safety gate | `bun tools/run-gate.ts` (Fil-C in WSL) | **8/8**, every case trapping at its file:line |
| unit tests | `zig build test --summary all` | **40/40** (2026-11-07) |
| the corpus | `testing.md` "corpus" | **78/78 as designed in all four modes** |
| the output comparison | `testing.md` | **0 unexplained** |
| Fil-C's own suite | `tools/filc/run-filc-tests.ts`, stock vs zilc's clang | **0 differences** on 7,269 |
| the pure-Zig chain | `tools/filc/compare-chains.ts` | **14/14** |
| the sarcasm port | `bun tools/sarcasm/check-stages.ts` | **every stage 0 differ** |

**CI jobs (§ 1.5):** `.github/workflows/release.yml` on every push to `main`, `ubuntu-latest`
(Linux x86_64): `checks` (zig fmt, `zig build test`, the release scripts' tests, the five version
places, the privacy scan), then on a release `tag` and `release` ([release.md](release.md)). The
Fil-C half (the gate, the suite, the corpus) has no runner and is the owner's machine's half, run
by `tools/release/release.ts` and the per-release checklist.

**Classes (§ 2.2):** none fixed yet; a class-by-class review takes its classes from
`workarounds.md`'s failure families.

**The seven security surfaces (§ 3.1), for zilc:**

1. **Untrusted input:** the user's Zig / C / C++ source and build files, the Fil-C source archive
   fetched by `zig build` (pinned by hash in `build.zig.zon`), upstream's sarcasm inputs. Building
   a program runs its own `build.zig` by design (Zig's model); nothing else of the input runs.
2. **Malformed input** is a compiler diagnostic or a named refusal of the tool, never a crash of
   zilc's driver or tools, never a silently different program.
3. **Paths:** `zig build` writes into the cache and `zig-out/` only; the tools write under
   `~/zilc-work/` and the repo's ignored folders; nothing unpacks outside its folder.
4. **Resources:** a time limit on every network request (the release scripts: 30 s); the long
   builds (Fil-C's clang, its suite) are measured and dated in `testing.md`.
5. **The release path:** [release.md](release.md) — only CI tags and makes the page; no registry;
   no `uses:`; Zig and Bun pinned by sha256; `contents: write` only in the two write jobs, which
   check out nothing; no `gh`.
6. **Dependencies:** Fil-C (pinned release, hash), LLVM inside it, Zig 0.15.2, Bun; licences in
   `third_party/LICENSES.md`, verified from the source; no Fil-C distributable committed, ever.
7. **Privacy:** `working-rules.md` § Privacy — the scan, text and binaries; it STOPS a push
   (`release.ts`, CI's `checks`).

**The environment matrix (§ 4.1):** **Linux x86_64 only** (owner, 2026-10-27) — WSL2 Ubuntu on the
owner's machine and a GitHub `ubuntu-latest` runner; Zig 0.15.2 (the Zig whose LLVM matches
Fil-C's); Bun latest installed (1.4.4); a clean clone (`tools/README.md` "First-time setup").
Nothing else is a target here; other platforms are zailc's.

**Records (§ 6):** findings → [known-issues.md](known-issues.md) (one `KI-n` row each; the WHY of
any workaround in [workarounds.md](workarounds.md)); the round → [open-work.md](open-work.md); a
release's two reviews → that release's entry in [release.md](release.md), before the bump
(`bump.ts` and `release.ts` refuse without both).
