# sarcasm-port: x86_64_frame checkpoint 7, the full record (archived 2026-11-24)

The checkpoint 7 entry of the § x86_64_frame text of `sarcasm-port.md` as written when it was
done, kept word for word when the note was condensed to stay under its 25 KB limit. Earlier
checkpoints: `sarcasm-port-frame-cp1-2.md`, `-cp3-4.md`, `-cp5.md`, `-cp6.md`.

- ✅ **checkpoint 7** (11-24) — upstream 4424–4543 (the B2 clone coordinate bands: per-clone
  extents, cumulative bases 128 apart rounded up to 64, the x86_b2band marks, the clone's own
  carrier accesses banded) in `x86_64_frame_bands.zig` (`Stop.b2Bands`; `Analysis.b2base`,
  `XF.b2band`, mark `b2band`); hook after 4543 (next 4545). K7 = per insn the band mark and
  aliasOff where set, then b2base in index order. The span never rejects. 0 differ (xframe
  195,063 lines, 19 of zilc's inputs). Corpus: one clone per function only (base 1 = 128 / 192
  / 256); 8 carrier accesses banded, 77 at depth != D0, 15 dyn. New input b2clone-bands.s: two
  clones (base 2), lo / hi moves, region skip, an in-clone carrier. 12 planted faults, all
  caught (differ): offset sign 293; separation 64 727; rounding 366; region skip 1,583; cursor
  hi → lo 24; lo / hi update dropped 24 / 24; alias extent 1,555; park test 2; alias add 14;
  sort desc 42; mark default 1,167. Not caught, 0 hits (kept as ported): alias banding with
  dropRestore set (a restore load has an rsp / rbp base, a carrier access does not), prologue
  skip (a clone follows the jump that ends the prologue scan), dyn skip with an rsp operand (a
  clone `ret` at dyn depth is rejected earlier), regionCarrier (never set).
  Measured with temporary counters (corpus + the first inputs): 0 hits for ext-lo, multi-band,
  region-skip, alias-dropRestore, alias-nosaveidx, alias-badidx before b2clone-bands.s; the
  corpus's own clones are all index 1 and all rounding hides lo / hi (192 - lo stays in
  (128, 192]), so the input's accesses were chosen to cross a 64 boundary. First plants that
  slipped through the corpus alone: cursor hi → lo, lo / hi update dropped, alias extent.
