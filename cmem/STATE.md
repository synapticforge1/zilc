# STATE: zilc

Updated: 2026-11-25, at the commit of x86_64_frame checkpoint 9

## Version

- Released: `0.15.2-0.687.1` on 2026-10-27 (no release since; `release.md` § "Release History")
- Working branch: `work-2026-11-24` (the sarcasm port; from `review/0.15.2-0.687.2`; pushed 2026-11-24 and merged into `main`)
- Toolchain: Zig 0.15.2, Fil-C 0.687 with zilc's patched clang, built by Zig

## Now

- Final review standard (letter H37): review 1 complete at `5ed1df1` (`review-process.md` § Last review)
- Memory guide (letter H38): all seven steps done 2026-11-23; `bun scripts/check-cmem.ts` holds
- Sarcasm port to Zig: x86_64_frame checkpoints 3 to 9 done 2026-11-24..25 (every stage 0 differ;
  `sarcasm-port.md`); next: checkpoint 10, upstream 4696– (checkRangeFits, widthOf, first caller)
- Pure-Zig track: runtime pieces built and verified; the Fil-C-compiled pieces are next (`roadmap.md` Z1)

## Review

- Run for: review 2 under H37 (owner: "review", 2026-11-24): first review done, 10 findings;
  review 1 complete at `5ed1df1` (re-review 6 empty, full suite passed)
- Position: review 2's findings recorded and HELD (owner, 2026-11-24): fixed as item 3 below
- Open issues: the 24 carried from round 1 and 1 found 2026-11-19, not yet triaged
  (`review-issues.md`); review 1's below-floor notes are recorded there
- Platforms passed: linux-x64 on 2026-11-23 (`platforms.md`: the other five are none)

## Next

Order changed 2026-11-25 (owner; `design-decisions.md`): the findings come after the frame module.

1. Sarcasm port: x86_64_frame from checkpoint 10 to the module's end (rewrite included; pinned 0.687)
2. Round 1's 24 carried findings: triage and fix (D3, D4, D10 in `release.ts` among them)
3. Review 2's findings: fix, re-review, the full suite; then a review of the port's new code
4. The basics corpus: current C / C++ / Zig lessons, C++ linking and `-std=` (R2-B3; `design-decisions.md` 2026-11-24)
5. Sarcasm port resumes: transform, codegen, render, glue, tailcall, localcall, `.byte`, to S2
6. Pure-Zig track: the Fil-C-compiled pieces (`roadmap.md` Z1 item 3)

## Waiting on owner

- Owner call 1's follow-up: GitHub Support's purge of the old commits (`open-work.md` § Open work)

## Read next

- `working-rules.md`: before the first command or commit
- `review-process.md`: before a review, and for the reference results
- `open-work.md`: the open items and the workspace letters
