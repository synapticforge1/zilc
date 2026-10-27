# history-map-2026-10-27.md — zilc's history purge (letter H19)

🔒 Owner, 2026-10-27: "yes perform the history purge". Personal drive paths were removed from every
commit on every branch and tag; nothing else changed. **Look a pre-purge id up here before quoting
it**; ids in records written before 2026-10-27 (zilc's own `cmem/`, the workspace's letters and
ledger, zailc's oracle notes) are OLD ids.

## What was removed (measured over every blob on every branch and tag)

| token | blobs | replaced by |
| --- | --- | --- |
| the wazmrt template path in `cmem/INDEX.md:11` (the owner's project tree) | 54 | `../wazmrt/cmem` (the 2026-10-27 HEAD wording) |
| the repo's WSL path (`/mnt/d/…`) in the pre-Deno shell tools (`tools/run-gate-wsl.sh`, `tools/p1/reference-behavior.sh`, `tools/p2/*.sh`) | 7 | `<repo-root>` |
| a user-named Windows scratchpad path with a session id (`tools/p2/dialect-probe.sh`, `tools/p2/milestone.sh`) | 2 | `<scratchpad>` |

Kept: `cmem/working-rules.md:65` (the privacy rule's own elided examples); convention paths
(`C:\zig-cache\zilc`, `C:\zig\0.15.2\zig.exe`, `C:\git\zilc.git`); elided paths (`…`). No commit or tag
message carried a path.

## How, and how it was checked

- In a mirror clone on NTFS: each of the 63 dirty blobs was rewritten once (each replacement
  asserted to apply, each result re-scanned clean), then `git filter-branch --index-filter` swapped
  blob ids in the index (no checkout) over `--branches --tags ^961a9d5`, with `--tag-name-filter
  cat`. The root `961a9d5` (GitHub-created, GitHub-signed, clean) was excluded, so it keeps its id
  and signature.
- Verified pair by pair (one-time Bun script): 69 pairs; author, committer and message identical;
  parents mapped; every tree difference is exactly a planned blob swap (383 entries in 67 commits;
  the last 2 commits' trees identical); `main` and `bun-port` tip trees identical; the annotated
  tag's tagger and message identical; every blob on the new refs clean but the rule text.
  Inverted: one swap dropped from the table → exactly 1 failure; control: the old refs → all 64
  dirty blobs found.
- The rewritten refs were fetched back into the working repo (tree unchanged, status clean). A
  pre-purge bundle of every branch and tag is in the gitignored `cmem/local/backups/`.

## Pushed (2026-10-27, owner: "perform the open items")

Force-pushed with `--force-with-lease` on each old value: `main` `19e7172` → `2c7faf0` (the
rewritten history plus the day's later commits), `v0.15.2` `19e7172` → `13ce96a`, tag
`v0.15.2-0.686.1` `fda2d43` → `7dbddf8`; `ls-remote` read back equal to local. Checked after: a
fresh mirror clone from GitHub — 80 commits, 959 blobs over every ref, scanned with `grep -a` — has
no personal path (the only candidates are the privacy rule's own placeholder line, in 5 versions of
`working-rules.md`) and none in any commit message. Locally the reflogs were expired and
`gc --prune=now` left 1 pack (840 KiB); `fsck` clean; `19e7172` and `fda2d43` are gone. GitHub may
serve the old commits by hash until its own GC; removing them sooner is a GitHub Support request
(owner). `bun-port` was never pushed.

## Refs

| ref | old | new |
| --- | --- | --- |
| tag `v0.15.2-0.686.1` (published 2026-10-05) | tag `fda2d43` → commit `19e7172` | tag `7dbddf8` → commit `13ce96a` |
| `v0.15.2` (published) | `19e7172` | `13ce96a` |
| `main` | `5df1416` | `6427c82` |
| `bun-port` (never pushed) | `6a458c3` | `9d0ceda` |

## Every commit, oldest first (the root `961a9d5` is unchanged)

| old | new | date and subject |
| --- | --- | --- |
| `780625c64` | `216e1d9dd` | 2026-09-18 Scaffold zilc: dual license, project memory, Zig 0.15.2 build |
| `26f9c0592` | `b2addb02f` | 2026-09-18 cmem: record git safe.directory fix for the exFAT checkout |
| `b501cd598` | `758969e7d` | 2026-09-23 P1 feasibility results: Fil-C's IR is a patched-LLVM dialect |
| `e2ecfdfda` | `51d7b585e` | 2026-09-23 Add .gitattributes: keep LF on scripts and sources |
| `db8951022` | `a7234a9a1` | 2026-09-23 cmem: measure how far Fil-C's IR is from standard LLVM IR |
| `75cae695c` | `1d1ce31c3` | 2026-09-23 P2: the milestone works. Zig + C memory safety through Fil-C today |
| `8b782eac4` | `09f2d1a14` | 2026-09-23 gitattributes: keep LF on .ll files too |
| `3b1f66513` | `4e2918122` | 2026-09-23 zilc driver: one command compiles Zig + C into a memory-safe binary |
| `a6ab9a825` | `5ab7026ff` | 2026-09-23 Support -O Debug, and exonerate inline asm as the crash cause |
| `10c1f5bdb` | `aa57fac67` | 2026-09-23 Reduce the Fil-C Debug crash to 8 functions, and draft the upstream report |
| `28a2b10c0` | `35e5b1799` | 2026-09-23 Whole Zig programs run: generate a C-ABI entry shim |
| `61df55b72` | `06977d51e` | 2026-09-23 Add the safety gate: every example must trap at the right line |
| `620c0669e` | `e2902313a` | 2026-09-23 Update project memory and bump to 0.3.0 for the pause |
| `5464a1741` | `277cc809a` | 2026-09-30 Add --runtime, adopt <zig>-N versioning (0.15.2-3), plan the Zig runtime |
| `403351ffe` | `909f490ff` | 2026-09-30 Add the basics test corpus, decode Fil-C's runtime ABI, scope P3 |
| `8bdb670f1` | `e322bf9d7` | 2026-09-30 Fill Fil-C ABI gaps from upstream design docs |
| `53b071422` | `4025d87ae` | 2026-09-30 Record the port's order: fidelity first, then streamline |
| `c4719ae4c` | `77705a8bc` | 2026-09-30 Add the Zig 0.16.0 examples; fix redirected stdio in the 0.15.2 set |
| `e80bfd68c` | `92dcd20a9` | 2026-09-30 Pass -fno-stack-check in every mode (KI-8); rename tests/basics/zig |
| `4dbe0d779` | `a37cc26df` | 2026-09-30 Route Zig's raw syscall asm through Fil-C's libc (KI-7) |
| `dc61d4ede` | `27c2f3fab` | 2026-09-30 Observe the GC protocol entry points (P3 scoping) |
| `bdef8e0b3` | `ccbd2f02d` | 2026-09-30 Panic through Fil-C, and build f128 helpers through the pass |
| `2308a287a` | `b12f74c49` | 2026-09-30 Clear the mmap-hint bounds violation; document Zig upstream behaviours |
| `96fe3f294` | `05bc8f1b3` | 2026-09-30 Backport Zig 0.16.0's findSentinel into a 0.15.2 std overlay (KI-11) |
| `fab5a4d9a` | `1dd73d660` | 2026-09-30 Fix the null-object class: expose checked arithmetic, patch fromPage (KI-13) |
| `f50d7f958` | `6b8f69b75` | 2026-09-30 Take Zig's unoptimized IR; make every Release mode identical (KI-17) |
| `411b02f7e` | `2571a82b2` | 2026-09-30 Record owner decisions: clean-room runtime, platforms, publish plan |
| `0185e3e9b` | `4cddb3607` | 2026-09-30 Record platform processors: x86_64 + aarch64; riscv64 out of scope |
| `f3c88a907` | `60db5eae0` | 2026-09-30 Pause note: start next session with KI-18, then the pre-publish checklist |
| `e3570d643` | `93d733256` | 2026-10-01 Fix KI-18, KI-20, KI-21; diagnose KI-22 build time; record decisions |
| `18b8b3de5` | `40f0f7e1e` | 2026-10-01 Patched Fil-C clang: fix KI-4 and KI-22; Debug at -O1 fixes KI-19 |
| `d1846529c` | `f28215ef6` | 2026-10-01 Guard Debug's stack-trace route; research and reject KI-22 option 3 |
| `a343a9f8e` | `bc933c052` | 2026-10-01 Record end of day: build-speed options approved, start-here note |
| `f56bbb736` | `4a1f9fdaa` | 2026-10-01 Archive the patched Fil-C clang in the project (local, gitignored) |
| `d3deddac3` | `e9ee3c3dc` | 2026-10-01 Keep the toolchain archive current: check script and memory-update rule |
| `0c08f7284` | `ccba465d0` | 2026-10-01 Upstream reference clone + monitor; LF everywhere |
| `52f161b81` | `029182f40` | 2026-10-01 Correct stale status labels in project memory |
| `455f7693f` | `bff2c5d3a` | 2026-10-01 Update project memory: upstream, LF, labels; sync README |
| `97bdfd9f8` | `ea4bf6c83` | 2026-10-01 Record KI-23 (git maintenance on exFAT) and global LF setting |
| `9e4b9e0ea` | `ffbebb7f0` | 2026-10-01 Update project memory: KI-23 in the Files table, tracing lesson |
| `f8d3b3570` | `5761a08c5` | 2026-10-01 KI-23: the projects' NTFS cache setup covers the Zig cache, not git |
| `8a60da36a` | `db63d1a85` | 2026-10-01 Record owner decision: projects stay on D: for portability |
| `cee525e8d` | `711458da3` | 2026-10-01 Update project memory: KI-23 fully closed, no open-sounding text |
| `3ed7b5bd4` | `7792eec25` | 2026-10-02 KI-22 lever (a): parallel code generation for big modules |
| `b69c4342c` | `067459efe` | 2026-10-02 KI-22 levers (b) and (c): dense interference graph, object cache |
| `3b41fd30a` | `a8e6ce661` | 2026-10-02 Add zilc --clean-cache; record the owner's cache decision |
| `312e25bd3` | `fa3343701` | 2026-10-02 Pre-publish: output comparison vs native, 0 unexplained differences |
| `bddd8e943` | `146bb8db4` | 2026-10-02 Pre-publish: library mode gets zilc's std hooks |
| `564cedd28` | `829e71abd` | 2026-10-02 Pre-publish KI-5: std.os.environ set; stack expansion measured unneeded |
| `8cfd270ce` | `983b86f10` | 2026-10-02 KI-20: tell the user when their crypto_always_getrandom is overridden |
| `0a07e3e14` | `359da6ed4` | 2026-10-05 Pre-publish: zilc --version states its Zig and Fil-C; RELEASE-NOTES.md |
| `ca851d096` | `cd46e4c33` | 2026-10-05 Run Fil-C's own test suite against zilc's patched clang: 0 differences |
| `514a4249e` | `41c800bf1` | 2026-10-05 Convert every tool script from shell to Deno (cross-platform) |
| `767742485` | `22e8f03fb` | 2026-10-05 Record tiny-ni2.ll and the P1 IR inputs; update project memory |
| `ae91404da` | `663f336dc` | 2026-10-05 Move to Fil-C 0.686; version 0.15.2-0.686.1; upstream review |
| `19e717294` | `13ce96aff` | 2026-10-05 P6 platforms scope pass: cmem/platforms.md, tools/p6/os-surface.ts |
| `14e713156` | `324450ef5` | 2026-10-05 Record the v0.15.2-0.686.1 publish; next: evaluate cosmo mode |
| `7ce1cf4a6` | `bf9857cdb` | 2026-10-05 Cosmo evaluation step 1: build-cosmo.ts (Fil-C from source, cosmo mode) |
| `742319776` | `b2d37f7d6` | 2026-10-05 Owner direction: 0.16.0 line, only-Zig goal; clean up 0.16.1 examples |
| `5d3a4cdb1` | `7af6c66af` | 2026-10-05 Owner: translate Fil-C into Zig on 0.15.2 first; WSL interop vs cosmo |
| `b47af42e3` | `bca89de4c` | 2026-10-05 Cosmo evaluation done; Zig version of Fil-C scoped on 0.15.2 |
| `73311571a` | `4a2227f18` | 2026-10-05 Owner: new project Zaig; zilc stays the reference; resolve review rows |
| `ba4d72bd7` | `175edcca8` | 2026-10-08 Cosmo evaluation closed; rule: never execute Fil-C/cosmo output on the Windows host |
| `b886339d4` | `2cd3f223c` | 2026-10-08 cmem: Zaig started 2026-10-08 in the sibling repo; zilc is its oracle |
| `992ecad75` | `2692b67a8` | 2026-10-08 cmem: the new project is named zailc = Zig + AI + Fil-C (was Zaig) |
| `9794594fb` | `538d93097` | 2026-10-08 cmem: the brief's Windows-crash bullet corrected; zailc's evening state and remote noted |
| `44e0b1a02` | `c2841dddf` | 2026-10-22 Tools: Bun only, Deno dropped; port every tool to Bun |
| `6a458c3a1` | `9d0cedae4` | 2026-10-27 cmem: bring zilc under the workspace floor (letters H26, H15, H19, H22, H27, H28) |
| `5df141609` | `6427c8282` | 2026-10-27 Merge bun-port: every tool on Bun, and the workspace-floor compliance |
