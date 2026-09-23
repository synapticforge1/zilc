# Releasing & Versioning

## 🔖 THE VERSION IS `0.3.0` — P1 and P2 shipped 2026-09-23

Per the cadence below (minor per roadmap phase): `0.1.0` scaffold → **`0.2.0` P1**, the feasibility
milestone → **`0.3.0` P2**, the driver, Debug support, whole Zig programs and the safety gate. P1 and
P2 landed the same day, so `0.2.0` was never a separate release; the ladder still counts them.

`1.0.0` should mean the target is trustworthy for real Zig code — at minimum P4 (language fidelity)
with a substantial corpus passing, not just four examples. **Not yet proposed.**

## ~~The version is `0.1.0`~~ (2026-09-18, scaffold)

`0.x` means the target's semantics and ABI may change without notice. `1.0.0` should mean at least
the P2 exit criterion (C programs panic correctly under Zig's toolchain). Confirm with the owner.

## 🔢 Where the number lives — FOUR places, and only a grep keeps them honest

1. `build.zig.zon` → `.version`
2. `src/root.zig` → `version` **and the test that asserts `version_string`** — that test is what
   makes a half-done bump fail loudly instead of shipping a lying `zilc --version`
3. `cmem/INDEX.md` → the STATE table
4. `README.md` → the status line

⚠️ **`minimum_zig_version` is a SEPARATE number** (`0.15.2`, pinned to Fil-C's LLVM — KI-3). Do not
move it with the version.

## Cadence

Adopt wazmrt's rule once past `1.0.0`: every component is a single digit, `+0.0.1` per shipped track,
and a breaking change takes the next major immediately. Before `1.0.0`, bump the minor per roadmap
phase (P1 → `0.2.0`, …).

## Per-release checklist (draft)

- [ ] `zig build test`, `capi-smoke`, and every active gate in `testing.md` are green.
- [ ] Version synced in all four places above.
- [ ] `third_party/LICENSES.md` ledger matches what is actually in the tree. Any license that must
      travel with `zig-out/` is installed by `build.zig`.
- [ ] `cmem/INDEX.md` STATE updated.
