# STATE: zilc

Updated: 2026-11-24, at the end of the session

## Version

- Released: `0.15.2-0.687.1` on 2026-10-27 (no release since; `release.md` § "Release History")
- Working branch: `review/0.15.2-0.687.2` (review 1, committed `4f377a5`; not merged, not pushed)
- Toolchain: Zig 0.15.2, Fil-C 0.687 with zilc's patched clang, built by Zig

## Now

- Final review standard (letter H37): review 1 complete at `4f377a5` (`review-process.md` § Last review)
- Memory guide (letter H38): all seven steps done 2026-11-23; `bun scripts/check-cmem.ts` holds
- Sarcasm port to Zig: paused at x86_64_frame checkpoint 3 (`sarcasm-port.md`)
- Pure-Zig track: runtime pieces built and verified; the Fil-C-compiled pieces are next (`roadmap.md` Z1)

## Review

- Run for: review 1 under H37, 2026-11-23/24; complete (re-review 6 empty, full suite passed)
- Position: done; the review gate accepts a release whose code is `4f377a5` plus memory changes
- Open issues: the 24 carried from round 1 and 1 found 2026-11-19, not yet triaged
  (`review-issues.md`); review 1's below-floor notes are recorded there
- Platforms passed: linux-x64 on 2026-11-23 (`platforms.md`: the other five are none)

## Next

1. On the owner's "push": merge `review/0.15.2-0.687.2` into `main`, push both
2. Triage the 24 carried round-1 findings under H37's classes
3. Sarcasm port: x86_64_frame checkpoint 3
4. Pure-Zig track: the Fil-C-compiled pieces (`roadmap.md` Z1 item 3)

## Waiting on owner

- A GitHub token (fine-grained, no permissions) for GitHub's Markdown renderer at release time:
  unauthenticated calls were refused by the rate limit (`review-issues.md` H18)
- R3L1: whether NOTICE says built programs carry MIT code (Zig's std, compiler-rt)
- Repository settings: branch and tag protection on `main` (not checkable without the API)
- Owner call 1's follow-up: GitHub Support's purge of the old commits (`open-work.md` § Open work)

## Read next

- `working-rules.md`: before the first command or commit
- `review-process.md`: before a review, and for the reference results
- `open-work.md`: the open items and the workspace letters
