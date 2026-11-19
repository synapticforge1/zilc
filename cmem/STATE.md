# STATE: zilc

Updated: 2026-11-19, at the end of the session

## Version

- Released: `0.15.2-0.687.1` on 2026-10-27 (no release since; `release.md` § "Release History")
- Working branch: `work-2026-11-15`, merged into `main` and pushed 2026-11-19 (CI green)
- Toolchain: Zig 0.15.2, Fil-C 0.687 with zilc's patched clang, built by Zig

## Now

- Memory guide (letter H38): steps 1–3 done 2026-11-19 (this file, the router INDEX, `CLAUDE.md`)
- Sarcasm port to Zig: paused at x86_64_frame checkpoint 3 (`sarcasm-port.md`)
- Pure-Zig track: runtime pieces built and verified; the Fil-C-compiled pieces are next (`roadmap.md` Z1)

## Review

- Run for: none in progress (round 1 stopped 2026-11-19, superseded by the final standard, letter H37)
- Position: none; the first review under H37's five classes comes after H37 (a)–(g)
- Open issues: 0 tracked (`review-issues.md` arrives with H37)
- Platforms passed: none recorded yet (`platforms.md` gets the matrix with H37)

## Next

1. Letter H37 (a)–(g): `review-process.md`, `release.ts`, `release.yml`, `platforms.md`
2. Letter H38 steps 4–7: closed items to `archive/`, split files over 25 KB, wrap long lines, the size check
3. One full first review under H37 (basic, hardening, licensing, security, privacy)
4. Sarcasm port: x86_64_frame checkpoint 3
5. Pure-Zig track: the Fil-C-compiled pieces (`roadmap.md` Z1 item 3)

## Waiting on owner

- Nothing blocks the next item. "push" and "release" are the owner's words (`working-rules.md`).
- Owner call 1's follow-up: GitHub Support's purge of the old commits (`open-work.md` § Owner calls)

## Read next

- `working-rules.md`: before the first command or commit
- `../workspace/cmem/letters/H37.md`: the next item
- `open-work.md`: the open items and the workspace letters table
