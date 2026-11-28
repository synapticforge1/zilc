# sarcasm-port: x86_64_frame checkpoint 3-4 entries (archived 2026-11-25)

The checkpoint 3 and 4 entries of the § x86_64_frame text of `sarcasm-port.md` as they stood
before checkpoint 8, kept word for word when that note was condensed to stay under its 25 KB
limit. Full record of both: `sarcasm-port-frame-cp3-4.md`.

- ✅ **checkpoint 3** (2026-11-24) — upstream 3213–3749 (validateTeardown, checkLostReload,
  retIsGpr, the annotation loop) in `x86_64_frame_annotate.zig` (`Stop.annotate`); K3 = per insn
  the marks, depth / saves / fp / smap, then frameAlignReq / frameAndDepth / frameAndSeen. 0 differ
  over 163,254 lines; 74,017 statements annotated; 20 rejections (8 fixpoint, 12 here); 8 planted
  faults caught; four `frame-branches/` inputs (reject-restore-rax / -restore-redef /
  -teardown-redef, rbp-restore-lea). Dead: the `localCall` guard (3230), table depths.
- ✅ **checkpoint 4** (11-24) — upstream 3751–4069 (andDomOf, reachedFromAnd, preAnd / postAnd,
  the governing-`and` dataflow, the crossing rejection, the prologue-`and` fill) in
  `x86_64_frame_and.zig` (`Stop.andWalk`); K4 per index 1..#body+1. 0 differ over 170,769 lines;
  67 functions with a mid `and`; 6 rejections; 7 planted faults caught; new inputs and-join.s,
  exempt-restore-and.s, reject-restore-loop-park.s. A walk to `#body+1` panics (upstream: a Lua
  indexing error). Full record of 3 and 4 (faults, dead branches): `archive/sarcasm-port-frame-cp3-4.md`.
