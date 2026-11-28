# sarcasm-port: x86_64_frame checkpoint 7-8 entries (archived 2026-11-25)

The checkpoint 7 and 8 entries of the § x86_64_frame text of `sarcasm-port.md` as they stood
before checkpoint 9, kept word for word when that note was condensed to stay under its 25 KB
limit. Fuller record of checkpoint 7 (measured hits, every fault): `sarcasm-port-frame-cp7.md`;
earlier: `-cp1-2.md`, `-cp3-4.md`, `-cp5-6-entries.md`.

- ✅ **checkpoint 7** (11-24) — upstream 4424–4543 (the B2 clone coordinate bands: per-clone
  extents, cumulative bases 128 apart rounded up to 64, the x86_b2band marks, the clone's own
  carrier accesses banded) in `x86_64_frame_bands.zig` (`Stop.b2Bands`; `Analysis.b2base`,
  `XF.b2band`, mark `b2band`); hook after 4543 (next 4545). K7 = per insn the band mark and
  aliasOff where set, then b2base in index order. The span never rejects. 0 differ (xframe
  195,063 lines, 19 of zilc's inputs). The corpus has one clone per function only, so the new
  input b2clone-bands.s adds two clones, lo / hi moves, a region skip, an in-clone carrier. 12
  planted faults caught (24 to 1,583 differ); not caught, 0 hits (kept as ported): alias
  banding with dropRestore, the prologue skip, the dyn skip with an rsp operand, regionCarrier
  (never set). Measured hits, every fault: `archive/sarcasm-port-frame-cp7.md`.
- ✅ **checkpoint 8** (11-25) — upstream 4545–4591 (the post-`and` frame extent: frameSize grows
  to the widest post-`and` plain rsp access, gated on frameAndSeen) in
  `x86_64_frame_postand.zig` (`Stop.postAnd`); hook after 4591 (next 4593). K8 = frameSize (the
  span sets no mark and never rejects). 0 differ (xframe 204,275 lines, 19 of zilc's inputs).
  Measured (corpus, 151 gated runs): 12 growths (6 changed K8 values), 469 widths, 192 fp / 277
  gpr paths, 57 lea, 7 dyn skips, 267 below-andDepth skips. Inputs postand-depth0.s (the depth-0
  note), -prologue-nop.s (`nopl 256(%rsp)` in the prologue), -preand.s, -b2clone.s, -localclone.s
  (each a store 256 above a 64-byte frame). 10 of 11 faults caught: `>` for `>=` 6 differ, no lea
  skip 6, fp path as gpr 3, offset sign 115, dyn depth unskipped (panic), and with the inputs the
  frameAndDepth gate, preAnd / prologue / b2clone / localClone skips 3 differ each. Not caught:
  last-vs-first mem operand (x86 has one explicit memory operand; string ops carry none).
  Unreachable: 4579's pcall failure and a nil width (an access the fp knowledge rejects dies in
  the fixpoint first, 2570; regonly / reject mnemonics with memory die in parse / classify).
