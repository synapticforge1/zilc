# Releasing & Versioning

## 🔖 THE VERSION IS **`0.15.2-3`** — APPLIED 2026-09-30 (was `0.3.0`; same release, new scheme)

In code, `src/root.zig` builds it from two named constants, `zig_line` (0.15.2) and `release`
(3), so a release bump changes one number and a Zig move changes the other. (`zig_line` was briefly
named `compatible_zig`; renamed 2026-09-30 when the meaning was corrected, below.) Two tests guard it: the
string must be `0.15.2-3`, and it must **parse back to the same fields** (the `_` trap below).
Verified at the change: tests 11/11, `zig build` accepts the zon, capi-smoke prints
`zilc 0.15.2-3`, gate 4/4 in WSL.

**Bumping:** a zilc release → `release += 1`. A new Zig line, **patch releases included** →
change `zig_line` **and reset `release` to 1**, and record its **basis** (below). Either way,
update `build.zig.zon`, the README status line and INDEX's STATE table (the four places, below).

## 🔖 THE SCHEME (owner, 2026-09-30): the version NAMES THE ZIG LINE, then our release

**`<Zig line>-<zilc release>`**, e.g. **`0.15.2-3`**: zilc release 3 of the Zig 0.15.2 line.
(First proposed as `0.15.2.3`; see the spelling decision below.)

⚠️ **Corrected 2026-09-30:** this section first said the Zig part names the *compatible* Zig (the one
user code needs). The owner's own example, **`0.16.2-1` based on `0.15.2-100`** while Fil-C is still
on the old LLVM, shows that it names **the Zig the release line is built with**. User code may need
an older Zig than the line's (upgrade stage B). **So the version does NOT tell users which Zig their
code needs.** `zilc --version` and the release notes must state it, along with the Fil-C release
(open item 4 below).

### Two kinds of line, and the BASIS (owner, 2026-09-30)

- **The reference line** is built with the Zig whose LLVM matches Fil-C's (upgrade stage A), e.g.
  `0.15.2-N` today. It is the one checked directly against Fil-C.
- **A latest line** is built with a newer Zig (stage B), e.g. `0.16.2-N`. **Every release in it
  names its BASIS:** the reference release it was ported from. Example: `0.16.2-1`, basis
  `0.15.2-100`.
- **When a new Zig line starts, port from the LATEST reference release** so the conversion is as
  small as possible, and use the port notes from the previous line (`ports/<version>.md`). With notes from
  the `0.16.1-1` port, `0.16.2-1` should go faster.
- **Why (owner):** if Fil-C stays on an old LLVM for a long time, the reference line keeps moving
  (`0.15.2-100`, `-101`, …) and remains the fixed point every latest-line release can be checked
  against. The changes are made on the reference line first, then carried to the latest line,
  taking the latest Zig's own changes into account.
- **ONE GIT BRANCH PER ZIG LINE (owner, 2026-09-30):** `0.15.1-N`, `0.15.2-N`, `0.16.1-N` and
  `0.16.2-N` each live on their own branch, for compatibility with that upstream Zig release.
  What follows from it:
  - A new line's branch is **created from its basis release**, e.g. the `0.16.2` branch starts at
    the `0.15.2-100` commit. The basis is then visible in git history, not only in the notes.
  - Each release is **tagged on its own branch** (e.g. `v0.15.2-3`), so every basis can be
    checked out exactly.
  - Carrying later reference changes to a latest line is a **merge or cherry-pick** from the
    reference branch, and the resulting release names its new basis.
  - An old line stays buildable with its own Zig indefinitely; nothing forces it forward.
  - ⚠️ *Upstream detail, unverified:* as far as we know, Zig itself keeps one branch per **minor**
    series (e.g. `0.15.x`) and tags patch releases. zilc goes finer, one branch per patch release,
    because patch releases break things too (owner). Check Zig's repository before quoting this.
  - ✅ **Settled (owner, 2026-09-30):**
    - **Branches are named `v<zig>`**: `v0.15.2`, `v0.16.2`, not `zig-0.15.2`.
    - **`main` is the base, the reference line.** It moves on when the reference moves, to a later
      `0.15.x` if Zig releases one, or to a newer line if Fil-C moves to a newer LLVM. The `v<zig>`
      branch of a line it leaves behind stays, frozen at that line's last release.
    - **`cmem/` is authoritative on `main` only.** A line branch's copy of `cmem/` is a snapshot from
      when it was cut. Port notes are written on `main`, in `cmem/ports/<version>.md`.
  - ⚠️ **Never create a TAG named just `v<zig>`** (e.g. `v0.15.2`). It would share a name with the
    branch, and git would call the name ambiguous. Release tags always carry `-N`: `v0.15.2-3`.
  - ✅ **Put in place 2026-09-30:** the commit with this change is tagged **`v0.15.2-3`**, the first
    release tag, and the **`v0.15.2`** branch was created there. Both are local; nothing was pushed.
- **Where the basis is recorded:** the release notes (`Basis: 0.15.2-100`), and the line's entry
  in `ports/<version>.md`. ⚠️ **zilc has no release-notes file yet.** It is needed before the first
  latest-line release.

**Why:** the old minor-per-phase ladder (`0.3.0`, `0.4.0`, …) would eventually climb into
Zig's own numbers (`0.15.x`) and be mistaken for them (owner). Switching early costs nothing: `0.3.0`
maps directly to **`0.15.2-3`**, keeping our release number `3`, and it sorts above `0.3.0`.

⚠️ **Why not four numbers, measured 2026-09-30 with Zig 0.15.2's `std.SemanticVersion.parse`:**
`build.zig.zon`'s `.version` must be a three-number semantic version, and **`0.15.2.3` is rejected
(`InvalidVersion`)**. Other spellings:
- `0.15.2+zilc.3` is accepted, but the part after `+` is ignored when comparing versions, so
  `+zilc.3` and `+zilc.4` compare **equal**. Unusable.
- `0.15.2-zilc.3` is accepted and our releases sort correctly among themselves, but every one sorts
  *below* `0.15.2`, which reads like a Zig pre-release.
- `0.3.0+zig.0.15.2` is valid and sorts correctly, but puts our number first.

✅ **SPELLING CHOSEN (owner, 2026-09-30): `0.15.2-N`**, e.g. **`0.15.2-3`**, used everywhere
(`build.zig.zon`, `zilc --version`, tags, README), so there is only one spelling. Verified with
Zig 0.15.2's parser: `-3` is read as a numeric pre-release tag, `0.15.2-9 < 0.15.2-10` (compared as
numbers, not text), today's `0.3.0 < 0.15.2-3` so the switch sorts upward, and `0.15.2-12 < 0.16.0-1`.
The one cost: `0.15.2-3 < 0.15.2` to generic semver tools, which read it as a pre-release. Harmless,
since nothing of ours is ever versioned plain `0.15.2`.

❌ **`0.15.2_3` was considered and REJECTED:** Zig *accepts* it, but its number parser treats `_` as a
digit separator (as in `1_000`), so it is **patch 23**: `0.15.2_3 == 0.15.23`. That would collide
with a real Zig release. Accepted is not the same as understood (`best-practices.md`).

✅ **NO 1.0 (owner, 2026-09-30): "We will not have a 1.0. We will just have a -? progression."**
zilc's version is `<Zig line>-N` for good. The only number zilc advances is `N`. The leading
numbers are Zig's, so if Zig itself reaches 1.0, ours reads `1.0.0-N` as a result, not because of any
milestone of ours. Consequences:
- **The number does not signal breaking changes.** Semver's major is Zig's. A breaking zilc change
  is announced in the release notes, not in the version.
- **Maturity is not encoded either.** What a release is trustworthy for is stated by the gates and
  the README status line, not the number.

✅ **`N` RESTARTS AT 1 FOR EVERY NEW ZIG VERSION, patch releases included (owner, 2026-09-30).**
"When zig hits 0.16.2, which seems to be a breaking change in the grand scheme of Zig world, we
start back at -1." Zig breaks APIs even between patch releases, so each Zig release starts its own
line of zilc releases: `0.16.1-1 … 0.16.1-5`, then `0.16.2-1`. Consequences:
- **`N` alone does not identify a release; the full version does.** Always quote it whole.
- **Ordering still holds across Zig versions:** `0.16.1-5 < 0.16.2-1`, the same kind of comparison
  as `0.15.2-12 < 0.16.0-1`, which was verified with Zig's parser.
- **Today's `0.15.2-3` keeps its `3`.** It carries the existing count (`0.1.0` → `0.3.0`) and is not
  renumbered. The restart rule applies from the next Zig change on.

**Settled questions:**
1. ~~Spelling~~: `-N`, settled above.
2. ~~Continue or restart~~: restart at 1, settled above.
3. ~~What `1.0` means~~: there is none, settled above.

**Still to act on:**
4. **What the number doesn't say must be shown elsewhere.** `zilc --version` and the release notes
   should state **the Zig user code needs** (0.15.2 today; it can lag the line's Zig), **the Fil-C
   release** (0.685, which fixes the runtime ABI), and on a latest line, **the basis**. Not done
   yet: `--version` prints only `zilc 0.15.2-3`.

Neither open question blocked the change to `0.15.2-3`. **The minor-per-phase cadence below is
retired** and kept for history.

## ~~The version is `0.3.0`~~ — P1 and P2 shipped 2026-09-23 (superseded 2026-09-30 by `0.15.2-3`)

Per the cadence below (minor per roadmap phase): `0.1.0` scaffold → **`0.2.0` P1**, the feasibility
milestone → **`0.3.0` P2**, the driver, Debug support, whole Zig programs and the safety gate. P1 and
P2 landed the same day, so `0.2.0` was never a separate release; the ladder still counts them.

~~`1.0.0` should mean the target is trustworthy for real Zig code.~~ Moot: there is no 1.0
(owner, 2026-09-30).

## ~~The version is `0.1.0`~~ (2026-09-18, scaffold)

`0.x` means the target's semantics and ABI may change without notice. `1.0.0` should mean at least
the P2 exit criterion (C programs panic correctly under Zig's toolchain). Confirm with the owner.

## 🔢 Where the number lives — FOUR places, and only a grep keeps them honest

1. `build.zig.zon` → `.version`
2. `src/root.zig` → `version` **and the test that asserts `version_string`** — that test is what
   makes a half-done bump fail loudly instead of shipping a lying `zilc --version`
3. `cmem/INDEX.md` → the STATE table
4. `README.md` → the status line

⚠️ **`minimum_zig_version` is a SEPARATE number.** It names the Zig that *builds* zilc. The version's
leading `0.15.2` names the Zig that compiles *user code*. They match at upgrade stage A, and they
**separate at stage B**, where `minimum_zig_version` moves to the latest Zig and the version's Zig
part stays on the compatible one (`upstream.md`, `design-decisions.md` invariant 4).

## Cadence

`N` goes up by one per shipped zilc release, and **resets to 1 whenever the Zig line
changes**, patch releases included. There is no major/minor of our own and no 1.0 (above).
~~Retired 2026-09-30: minor per roadmap phase before `1.0.0`, then wazmrt's single-digit rule.~~

## Per-release checklist (draft)

- [ ] `zig build test`, `capi-smoke`, and every active gate in `testing.md` are green.
- [ ] Version synced in all four places above.
- [ ] Release notes state: **the basis** (latest-line releases), **the Zig user code needs**, and
      **the Fil-C release**. A new Zig line also gets its `ports/<version>.md` entry.
- [ ] `third_party/LICENSES.md` ledger matches what is actually in the tree. Any license that must
      travel with `zig-out/` is installed by `build.zig`.
- [ ] `cmem/INDEX.md` STATE updated.
