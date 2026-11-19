# platforms.md — where zilc is tested, and what differs per platform

The support matrix, then notes per platform ID only where there is something to say. Common facts
(the six IDs, the statuses, the testing tiers, the Linux baseline): `../workspace/cmem/platforms.md`.
Created 2026-11-19 (letter H37, work item (g)); last verified 2026-11-19. Machine names stay in
`cmem/local/`. The measured record of the P6 scope pass and the cosmo evaluation (closed
2026-10-08, kept for zailc) is `archive/platforms-p6-cosmo-2026-10-08.md`.

## Support matrix

🔒 **zilc is Fil-C on Linux x86_64 only, worked in WSL or Linux — always** (owner, 2026-10-27;
`design-decisions.md`): Fil-C itself is x86_64 Linux only, and the cross-platform work is zailc's.
zilc ships SOURCE (the tag's source archive); "Target name" is the Zig target zilc compiles for.

| Platform    | Status | Target name         | Tested on                                |
| ----------- | ------ | ------------------- | ---------------------------------------- |
| win-x64     | none   | —                   | — (cross-platform is zailc's; see below) |
| win-arm64   | none   | —                   | — (zailc's)                              |
| mac-x64     | none   | —                   | — (zailc's)                              |
| mac-arm64   | none   | —                   | — (zailc's)                              |
| linux-x64   | tested | `x86_64-linux-musl` | the development machine, WSL2 guest      |
| linux-arm64 | none   | —                   | — (Fil-C is x86_64 only; zailc's)        |

- `none` here is the owner's scope rule, not a missing machine: no test machine changes it.
- A release states one `Tested on: <OS and version> (linux-x64)` line, the distro named — on the
  Release page, in its `release.md` entry and in the README — and claims nothing else (owner,
  2026-11-19). The first release to carry it is the next one.
- Until 2026-11-19 CI ran the no-Fil-C half of the tests on GitHub's `ubuntu-latest`; that was CI,
  not a test machine, and the tests left CI that day (H37 (e)).

## Linux distros tested

| Distro | Version     | Platform  | Date       |
| ------ | ----------- | --------- | ---------- |
| Ubuntu | 26.04.1 LTS | linux-x64 | 2026-11-19 |

- The development machine's WSL2 guest (glibc 2.43): every gate, test and reference suite runs
  there (`testing.md`). Other distros (Parallels guests on the Intel Mac, workspace `platforms.md`)
  are not run yet.
- **glibc 2.28 baseline:** unaffected — zilc publishes no Linux binary. A user builds zilc from
  source, and the programs zilc compiles link Fil-C's own musl-based libc (KI-6), not the host's
  glibc. No separate musl build is made (none is shipped).

## linux-x64

- **The one target:** `x86_64-linux-musl`, the driver's default (`src/driver.zig`, `src/main.zig`,
  tagged `[linux-x64]`): Fil-C's libc is musl, and a gnu target fails to link on `*64` symbols
  (KI-6).
- **The tools run inside Linux only:** `tools/lib/tool.ts` refuses any other platform at import
  (tagged `[linux-x64]`); from a Windows host, a WSL shell.
- **WSL on an exFAT drive:** the repository's drive has no symlinks or Unix modes, so the Zig cache
  lives in the Linux home (KI-2) and the toolchain is archived as a tarball (`toolchain/README.md`).
- 🛑 **Nothing built by Fil-C, cosmo or zilc is executed on the Windows host** (owner, 2026-10-08;
  the machine's EDR, `workarounds.md`).
