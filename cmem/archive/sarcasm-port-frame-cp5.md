# sarcasm-port: x86_64_frame checkpoint 5, the full record (archived 2026-11-24)

The checkpoint 5 entry of the § x86_64_frame text of `sarcasm-port.md` as it stood before
checkpoint 6, kept word for word when that note was condensed to stay under its 25 KB limit.
Checkpoints 1–2: `sarcasm-port-frame-cp1-2.md`; 3–4: `sarcasm-port-frame-cp3-4.md`.

- ✅ **checkpoint 5** (11-24) — upstream 4070–4359 (anyMidAnd, parkPostOf, the clone subframe
  balance check with its direct-carrier hatch) in `x86_64_frame_clone.zig` (`Stop.cloneBalance`;
  anyMidAnd an Analysis field, parkPostOf `XF.parkPostOf`); hook after 4359 (next 4361). K5 =
  anyMidAnd, parkPostOf(nil), each index where parkPostOf holds; the span sets no marks, a
  rejection is `K err` after K4. 0 differ (xframe 183,037 lines with 15 of zilc's inputs): corpus
  4,568 spans pass, 10 rejections (3 clone + 1 local unbalanced, 5 + 1 unknown depth); 67
  anyMidAnd, 2,665 parkPostOf-true indices. Measured: depth mismatch 52 calls (teardown hatch
  48), cloneRet without regions skipped 101. New inputs: b2clone-carrier-zero.s (lea and mov
  recovery accepted), reject-b2clone-push.s, -norecover.s, -redef.s. Planted faults (differ):
  hatch `teardown` test inverted 174,388; `park >` → `>=` 173,055; regions guard dropped 38,281;
  depthEq `==` → `>=` 37,780; recovery `rd == 0` → `!=` 1,057; ret-carrier saveIdx test
  inverted 1,117; mov `depth == 0` → `!=` 919. Pop arm of the push/pop test: 0 differ (kept).
  0 hits, no input (kept as ported): ret depth nil (CFG-reachable: an analysis-gap guard; or
  dead), clone entry depth nil, dyn / non-empty saves at a clone point, no smap at the ret.
  Dead: cloneRet without b2clone (tailcall 636–637, 651–652), carrierToZeroOk's entry depth 0 /
  non-number (depthEq or the dyn test already decided).
