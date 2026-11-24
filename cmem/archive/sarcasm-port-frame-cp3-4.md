# sarcasm-port: x86_64_frame checkpoints 3–4, the full record (archived 2026-11-24)

The checkpoint 3 and 4 entries (with checkpoint 3's open branches) of the § x86_64_frame text of
`sarcasm-port.md` as they stood before checkpoint 5, kept word for word when that note was
condensed to stay under its 25 KB limit. Checkpoints 1–2: `sarcasm-port-frame-cp1-2.md`.

- ✅ **checkpoint 3** (2026-11-24) — upstream 3213–3749 (validateTeardown, checkLostReload,
  retIsGpr, the annotation loop) in `src/sarcasm/x86_64_frame_annotate.zig`; hook after 3749
  (anchor `\tend`, next line 3751), K3 = per insn statement pro / depth / saves / fp / smap /
  aliasOff / aliasSaveIdx / the flag marks, then frameAlignReq / frameAndDepth / frameAndSeen.
  The harness runs each stop separately (`Stop.annotate`), so K err after K2 = a rejection in
  this span. Result: 0 differ over 163,254 lines (K1 4,589, K3 4,575 calls). 74,017 statements
  annotated (teardownStart 1,054, teardown 1,949, leaSave 147, spSave 140, aliasOff 286, …); 20 rejections (8 in the fixpoint, 12 here).
  Planted faults (differ): starter `leave` inverted 257; aliasSaveIdx dropped 286; frameAndDepth
  update dropped 53; spillPop depth test inverted 48; midSp `nd >= 0` → `> 0` 3; probe `or
  localClone` dropped 4; 16-byte `and` note rule 11; checkLostReload worklist reversed 0 (1 with
  reject-lostreload-order.s). Driven by `frame-branches/` inputs: restore load into %rax
  (reject-restore-rax.s), redefined restore (reject-restore-redef.s), teardown pop of a redefined
  save at dyn depth (reject-teardown-redef.s), rbp restore-base lea (rbp-restore-lea.s); the last
  two open branches are settled under checkpoint 4. Table depths: regionCarrierAccess and the {anchored} restore-base lea are dead
  (no-ops, documented); x86_depth / fp / saves / smap are the fixpoint's arrays, not copied.
- ✅ **checkpoint 4** (11-24) — upstream 3751–4069 (andDomOf, reachedFromAnd, preAnd /
  postAnd marks, the governing-`and` dataflow, the crossing rejection and its dropRestore
  exemption, the prologue-`and` fill) in `x86_64_frame_and.zig` (`Stop.andWalk`; andDomOf and
  reachedFromAnd are Analysis fields). Hook after 4069 (next line 4071); K4 = per index
  1..#body+1 (successors can name #body+1) pre / post / andDomOf / reachedFromAnd, indexed (no
  table order); a rejection is `K err` after K3. 0 differ over 170,769 lines. Corpus: 67
  functions with a mid `and`; preAnd 295, postAnd 535, reachedFromAnd 600; 6 rejections. Planted faults (differ): gandJoin's
  disagreement keeps the first 7; `leave` out of the rsp-moves-up list 3; preAnd / postAnd on the
  `and` 71 / 71; crossing test inverted 139,472; exemption's reachedFromAnd test inverted
  128,149; prologue fill skipping "none" 45; name test inverted 127,853. New inputs
  in `frame-branches/`: and-join.s (gandJoin's equal arm), exempt-restore-and.s (exemption
  succeeds), reject-restore-loop-park.s (park reached from an `and`). Unreachable by
  construction (kept as ported): a nil `out` in gandJoin, a non-insn or depth-less `and` in the
  walk, dropRestore's nil guards (restoreLoadOf implies them), a save-depth miss; a walk to
  `#body+1` panics here (upstream: Lua indexing error). `sIdx >` → `>=`: 0 (equivalent).
  Checkpoint 3's open branches: (1) validateTeardown's `if st.localCall then return nil` (3230)
  is dead: localCall sits only on `call` / `callq` statements (localcall.luau 92–96, 118–123,
  872 / 915 / 948; tailcall.luau 399–408), and the next test `b == "call"` returns nil for
  them, so removing the line changes nothing (no input). (2) The B2-clone buffer probe (fixpoint
  1957–1975, annotation 3486–3500) is driven by `b2clone-lea-probe.s` (b2clone.s plus a
  value-used `leaq 0(%rsp)` in the shared tail): `k >= lo` → `k > lo` gives 4 differ (fixpoint)
  and 1 (annotation).
