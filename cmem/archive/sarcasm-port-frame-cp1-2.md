# sarcasm-port: x86_64_frame checkpoints 1–2, the full record (archived 2026-11-24)

The § x86_64_frame text of `sarcasm-port.md` as it stood before checkpoint 4 (committed state),
kept word for word when that note was condensed to stay under its 25 KB limit.

## x86_64_frame (in progress, started 2026-11-07)

8,934 lines (5,112 code); two entry points: `analyzeFrame` (lines 677–7221, ONE function of
~6,500 lines, closures throughout) and `rewrite` (7222–8922), plus helpers (137–676) and the
stack-buffer API (beginStackBufResolution / endStackBufResolution / stackBufCanonOf /
recordStackBufCanon / stackBufLayout / stackBufGroupBaseFor / resolveStackBufDeclAt) and
frameBaseDepth / rbpNormalization. Requires x86_64_isa, x86_64_parse, x86_64_fp, sig, frame,
err. Module state carried from analyzeFrame to rewrite (D0, rbpNorm, maskScratchNum,
frameAlignReq / frameAndDepth / frameAndIdx / frameAndSeen, slotGranules, cloneRetProofRan,
yoloCount / yoloBase, sbLayout) and across a FILE (sbCanon, sbResolving).

The boundary, measured on the corpus under upstream's driver (2026-11-07): analyzeFrame runs
4,576 times (1,530 with regions = nil: transform's early geometry run, which skips the cloneRet
proof), rewrite 23,949 times. Statements arrive with the parse fields plus transform's
(b2clone, cloneRet, crossJumpEntry, localClone, localCloneEntry, localCall, localRet,
stackBufAnno, tailCall, tailRet; 68 also carry stale x86_* marks — copied clones, cleared by
analyzeFrame first); analyzeFrame ADDS 25 x86_* fields (x86_depth number or "dyn", x86_saves
table or string, x86_smap, x86_fp, x86_prologue, x86_teardown*, …, x86StackBufRep); rewrite adds
none to its input (it emits). Regions carry base (number or table), size, align, anchored,
frameRegion; sigDesc is sig's Descriptor.

The check — stage **xframe** in `check-stages.ts` (built 2026-11-07): under the real driver,
every analyzeFrame call writes its full input (`A <iser>`: statements with table identity —
`&id{…}` / `*id`, fixed-width `\ddd` escapes so the capture can be READ — sigDesc, regions, the
stack-buffer table; the stale x86_* marks are left out because analyzeFrame clears all of them
first, upstream 685–719); a patched COPY of upstream's module (`x86_64_frame_cp.luau`, a hook
inserted at each checkpoint line after verifying the line's exact text) stops at a checkpoint and
dumps its locals (`K<n>`). The port reads each capture (`tools/sarcasm/luau_value.zig` +
`capture.zig`: an unmodeled field is an error naming it), runs `analyzeFrameTo(…, stop)` and
prints its K. Progress:
- ✅ **checkpoint 1** — upstream 677–1189 (setup, stack-buffer probes, sigHasFp, yolo count,
  labelAt / nextInsn, the prologue prefix scan, D0 / rbpNorm / frameSize): 4,576 calls, 0 differ
  (233 fp frames, 87 alignment notes, 18 spill pushes, 45 with stack args, 173 buffer probes, 13
  b2 declarations); inverted twice (13 and 6 differ).
- ✅ **checkpoint 2** (2026-11-07) — upstream 1191–3211 (transferCore, the carrier map, transfer,
  the merges, successors, leaSaveUsesMemoryOnly, flagsDeadAfter, the depth fixpoint) in
  `src/sarcasm/x86_64_frame_flow.zig`: per statement the fixpoint's depth / saves / fp / smap
  (smap a Luau table — its order is upstream's output: the use check names the first offending
  carrier) and the marks it sets. 83,131 K lines, 0 differ (73,844 statement states; 95 at dyn
  depth, 2,495 with an established fp, 3,682 non-empty smaps, 646 slot carriers, 12 conflicts, 1,027
  region pointers, 8 rejections). Inverted: the call poison 63,367 differ, REVERSED smap copy order
  451, a no-op control 0. Two branches no Fil-C test reaches (measured: 0 hits) are driven by zilc's
  own inputs `tests/sarcasm/frame-branches/` (xframe runs them after the corpus): the saveIdx merge
  (saveidx-merge.s — both keep and rewrite traced directly) and D-space slot carriers /
  clearDynSlots (dyn-slot.s); with them a fault in each is caught (27 and 12 differ). Table depths
  are unreachable (corpus: x86_depth only number / "dyn"), so Depth is number | dyn. The replay
  seeds the parser's pseudo-register registry from the captured operands (classifyReg in
  leaSaveUsesMemoryOnly).
  Harness bugs found and fixed: the patched upstream module was written back UTF-8-re-encoded
  (now latin1, verified byte-identical to the release minus the inserted line), and the sequential
  comparator decoded the two sides differently (now both as bytes). Open curiosity: an in-harness
  stderr probe undercounted a branch the direct trace shows hit; trace the checker binary directly.
- next: **checkpoint 3** — upstream 3213–3750 (validateTeardown, checkLostReload, the annotation
  pass that sets x86_prologue / x86_depth / x86_saves / … on every statement).
