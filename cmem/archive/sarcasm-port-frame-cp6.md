# sarcasm-port: x86_64_frame checkpoint 6, the full record (archived 2026-11-24)

The checkpoint 6 entry of the § x86_64_frame text of `sarcasm-port.md` as it stood before
checkpoint 7, kept word for word when that note was condensed to stay under its 25 KB limit.
Checkpoints 1–2: `sarcasm-port-frame-cp1-2.md`; 3–4: `sarcasm-port-frame-cp3-4.md`; 5:
`sarcasm-port-frame-cp5.md`.

- ✅ **checkpoint 6** (11-24) — upstream 4361–4422 (the epilogue movq-restore loads: an rsp / rbp
  save-slot `mov` load of a save redefined after its push, proven dead by checkLostReload, marked
  x86_dropRestore) in `x86_64_frame_restore.zig` (`Stop.epilogueRestore`; checkLostReload now
  pub); hook after 4422 (next 4424). K6 = the indices marked dropRestore; a rejection is `K err`.
  0 differ (xframe 187,831 lines with 18 of zilc's inputs). Measured: 4,622 rsp / rbp loads, 185
  not 8 wide, 4,175 with saves, 3 at dyn depth (skipped), 165 rbp-based (156 with rbpNorm != 0),
  17 corpus marks (0 already marked by 3406), no corpus rejection. Inputs: epilogue-restore-rbp.s,
  reject-epilogue-restore-{rax,reload}.s. Planted faults (differ): `redefined` test dropped 41,760;
  offset `D0 - d` → `+ d` 41,552; width `!= 8` inverted 41,552; mark dropped 41,552; retIsGpr
  inverted 35,325; spill skip dropped 20,180; rbpNorm dropped 0 on the corpus, 830 with the rbp
  input; checkLostReload skipped 316; dyn-depth guard dropped: stage-check crashed. Not caught
  (kept as ported): the rbp-slot skip (225 hits skipped, none redefined); 0 hits: depth nil.
