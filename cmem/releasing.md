# Releasing & Versioning

## The version is `0.1.0` (2026-09-18, scaffold)

`0.x` means the target's semantics and ABI may change without notice. `1.0.0` should mean at least
the P2 exit criterion (C programs panic correctly under Zig's toolchain). Confirm with the owner.

## Where the number lives (keep them in sync; grep for the old one)

1. `build.zig.zon` → `.version`
2. `src/root.zig` → `version` (and the test that checks `version_string`)
3. `cmem/INDEX.md` → STATE table
4. `README.md` → status line

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
