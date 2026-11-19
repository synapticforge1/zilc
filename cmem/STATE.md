# STATE: zilc

Updated: 2026-11-19, at the end of the session

## Version

- Released: `0.15.2-0.687.1` on 2026-10-27 (no release since; `release.md` § "Release History")
- Working branch: `work-2026-11-15` (merged into `main` and pushed 2026-11-19, CI green; H37 work since)
- Toolchain: Zig 0.15.2, Fil-C 0.687 with zilc's patched clang, built by Zig

## Now

- Final review standard (letter H37): (a)–(g) done 2026-11-19; CI only publishes, every gate local
- Memory guide (letter H38): steps 1–3 done 2026-11-19; steps 4–7 next
- Sarcasm port to Zig: paused at x86_64_frame checkpoint 3 (`sarcasm-port.md`)
- Pure-Zig track: runtime pieces built and verified; the Fil-C-compiled pieces are next (`roadmap.md` Z1)

## Review

- Run for: none in progress (round 1 stopped 2026-11-19, superseded by H37)
- Position: none; the first review under H37's five classes is due before the next release
- Open issues: 25 in `review-issues.md` (24 carried from round 1, 1 found 2026-11-19), not yet classed
- Platforms passed: none recorded yet under H37 (`platforms.md`: linux-x64 only)

## Next

1. Letter H38 steps 4–7: closed items to `archive/`, split files over 25 KB, wrap long lines, the size check
2. One full first review under H37 (basic, hardening, licensing, security, privacy)
3. Sarcasm port: x86_64_frame checkpoint 3
4. Pure-Zig track: the Fil-C-compiled pieces (`roadmap.md` Z1 item 3)

## Waiting on owner

- A GitHub token (fine-grained, no permissions) for GitHub's Markdown renderer at release time:
  unauthenticated calls were refused by the rate limit (`review-issues.md` H1)
- Owner call 1's follow-up: GitHub Support's purge of the old commits (`open-work.md` § Owner calls)

## Read next

- `working-rules.md`: before the first command or commit
- `../workspace/cmem/memory-guide.md` § Migration: steps 4–7
- `open-work.md`: the open items and the workspace letters table
