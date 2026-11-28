# sarcasm-port: x86_64_frame checkpoint 5-6 entries (archived 2026-11-25)

The checkpoint 5 and 6 entries of the § x86_64_frame text of `sarcasm-port.md` as they stood
before checkpoint 8, kept word for word when that note was condensed to stay under its 25 KB
limit. Fuller records: `sarcasm-port-frame-cp5.md`, `-cp6.md`; earlier: `-cp1-2.md`, `-cp3-4.md`;
later: `-cp7.md`.

- ✅ **checkpoint 5** (11-24) — upstream 4070–4359 (anyMidAnd, parkPostOf, the clone subframe
  balance check) in `x86_64_frame_clone.zig` (`Stop.cloneBalance`); K5 = anyMidAnd, parkPostOf
  per index; a rejection is `K err`. 0 differ; 10 rejections; 7 planted faults caught; inputs
  b2clone-carrier-zero.s, reject-b2clone-{push,norecover,redef}.s. Faults, measured hits and dead
  branches (cloneRet without b2clone, carrierToZeroOk's entry depth):
  `archive/sarcasm-port-frame-cp5.md`.
- ✅ **checkpoint 6** (11-24) — upstream 4361–4422 (the epilogue movq-restore loads: an rsp / rbp
  save-slot `mov` load of a save redefined after its push, proven dead by checkLostReload, marked
  x86_dropRestore) in `x86_64_frame_restore.zig` (`Stop.epilogueRestore`; checkLostReload now
  pub); hook after 4422 (next 4424). K6 = the indices marked dropRestore; a rejection is `K err`.
  0 differ; 17 corpus marks, no corpus rejection; inputs epilogue-restore-rbp.s and
  reject-epilogue-restore-{rax,reload}.s; 9 planted faults caught (rbpNorm only with the rbp
  input; the rbp-slot skip stays uncaught, kept). Measured hits, faults: `archive/sarcasm-port-frame-cp6.md`.
