# sarcasm-port.md — porting Fil-C's assembler from Luau to Zig

Owner, 2026-11-06: *"Port sarcasm to Zig"* (`design-decisions.md` top row; plan stages S0–S2 in
`roadmap.md` Z1). This file is the PORTING MAP: what sarcasm is, how it is put together, and what a
byte-identical port has to reproduce. Measured from Fil-C 0.687's `projects/sarcasm` (paths below
relative to it) on 2026-11-06; a claim with a date, re-check when the pin moves.

## What it is

Fil-C's "pizlonating assembler": `.s` with Fil-C annotations in, a memory-safe object out. Fil-C's
clang runs `pizfix/bin/sarcasm [--x86_64|--arm64] [-g] IN.s -o OUT.o` for every `.s` input (a Luau
script under minilute, which then runs `as`); `-S` writes the rewritten assembly instead — what the
oracle compares. 28 modules, 34,398 lines; the x86_64 path ≈ 28,100 (the six `arm64_*` modules are
not ported: zilc is Linux x86_64 only; `lift` requires `arm64_isa` only for a default argument).

## The oracle (S0, done)

`tools/sarcasm/compare-sarcasm.ts`: upstream's sarcasm (the release's `pizfix/bin/sarcasm`) and a
candidate, `--x86_64 -S`, over all 1,431 `.s` files in Fil-C's `filc/tests`; exit code, stdout,
stderr and assembly byte for byte. Against itself: 0 differ (746 accepted, 685 rejected with
`--x86_64`; the rejections' diagnostics are compared too). ~0.56 s per file under minilute.

## The x86_64 pipeline (`sarcasm/sarcasm.luau`)

- `main` (1725–1871): argv; `detect.detect` (syntax; `--x86_64` alone keeps the detected syntax,
  default AT&T); `makeTarget` (36–57); one `pcall` around parse + compile; `fs.write`.
- **parse** — `x86_64_parse.parseString` (871–938): statements
  `{kind=insn|label|directive|blank, …, line, file}`; operands in INTEL order (AT&T reversed):
  `reg {rc,num,width,name,pseudo?}`, `imm {text,value,absAddr?}`, `mem {base,index,scale,dispVal,
  dispSym,dispReloc,deco/bcastN}`, `sym {text,reloc}`, `numref {text,num,dir,indirect}`; then
  `numlabel.resolve`. Lines 1041–2600: an x86 machine-code decoder for `.byte` runs.
- **compile** (1061–1696): expandRept; .globl/.hidden; `localcall.prescanCalls`; `splitFunctions`
  (104–200, with `tailcall.scanAliases`); `localcall.discover`; `decodeByteInsns`; stack-buffer
  resolution (`x86_64_frame.analyzeFrame`, resolution only, 1139–1272); `tailcall.buildContext`;
  `collectX86Data` (607–1008: data objects, .init/.fini); per function (1500–1631):
  `sig.parseSignature` (signature = 1 + Ret + 133·Arg, base-11 class codes), `tailcall.rewrite`,
  `localcall.augment`, decode, **`transform.transformFunction`** (transform 748–5240: validate,
  analyzeFrame ×2, `frame.preprocess` → `x86_64_frame.rewrite`, `lift.liftFunction`, DCE,
  `ptrflow.analyze`, `cgm.make` codegen, expandFpSaves → `tr {fipNodes, temps, …}`),
  **`allocateWithSpilling`** (454–547, ≤ 32 rounds of `regalloc.color` / rewriteSpills /
  packSpillSlots), then glue (`getter`, `emit.emitFip`, thunks, origins, aliases); callsite
  thunks in sorted signature order; data globals; .init sections; `.note.GNU-stack`; joined with
  "\n" and a final "\n". `analyzeFrame` also annotates statements in place (~27 `st.x86_*` fields).
- **diagnostics** (`err.luau`): `err.at(st, msg)` → `"sarcasm: <file>:<line>: <msg>"`, `err.here`
  (parser line), `err.plain`; `main` prints the message to STDOUT (`print`) and exits 1 (usage: 2).
  Errors are also CONTROL FLOW: `pcall` at sarcasm.luau 710 and 1232–1269 (swallows any error,
  runtime errors included, unless it says "the offsets must match"), transform 862 / 1031,
  x86_64_frame 2850 2986 4579 4648 5263 6547 6793 7135 8577, x86_64_parse 2514 — so in Zig: error
  unions carrying the message, and what would be a Luau RUNTIME error must be a catchable error at
  those sites.

## Progress

- ✅ **S0, the oracle** (2026-11-06): above.
- ✅ **Foundation 1, Luau's table** (2026-11-06): `src/sarcasm/luau_table.zig`, a port of
  ltable.cpp (array/hash parts, hashnum/luaS_hash, Brent's newkey, rehash/computesizes/adjustasize,
  the `lastfree`/`aboundary` union, luaH_getn, luaH_next order) and ltablib's insert/remove
  (moveelements' two paths). Proven by `tools/sarcasm/check-luau-table.ts` against the release's
  minilute: 2,000 and 4,000 random scenarios (two seeds), every `#t` and all 10,974 / 21,938
  traversal orders equal. Inverted (the boundary cache disabled: fails at line 113, `#t` 15 vs
  10). ⚠️ One thing NOT emulated, by design: a nil-valued node with a STRING key becomes a dead key
  when Luau's GC traverses the table (lgc removeentry), which moves later keys — GC timing, not the
  table algorithm (measured: the first run, with string deletions, differed from line 2,459). Number
  keys are never collected, so number-keyed layouts are exact; sarcasm sorts the string-keyed
  traversals that reach its output (below).

- ✅ **Foundation 3, Lua patterns** (2026-11-06): `src/sarcasm/lua_pattern.zig`, a port of
  lstrlib.cpp's matcher (match with its tail calls, classend, matchbracketclass, singlematch,
  max/min_expand, captures incl. position captures, %b, %f, back-references, the NUL C reads past
  both ends, C-locale ctype) and find (plain search, init) / match / gmatch / gsub (string
  replacements with %0–%9, function replacements). Proven by `tools/sarcasm/check-lua-pattern.ts`:
  211 patterns — all 189 literal patterns in sarcasm's x86_64-path sources plus 22 hand-written —
  over 601 subjects (corpus lines and tokens), every find / match / gmatch / gsub result equal to
  Luau's (one malformed pattern errors on both sides). Inverted (the frontier's previous character
  forced to NUL: the `%f[%w]…` patterns fail).

- ✅ **Foundation 2, number formatting** (2026-11-06): `src/sarcasm/luau_number.zig` —
  `tostring(n)` is luai_num2str (lnumprint.cpp): the SHORTEST round-trip digits (⚠️ not `%.14g`:
  sarcasm's own comment at x86_64_parse 192–194 describes an older Luau; minilute prints 2^62 as
  `4611686018427388000`), fixed layout for a decimal point in −5..21, else scientific with a ≥ 2
  digit exponent, `nan` / `inf` / `-inf` / `-0`; `string.format("%.0f")` is printf's exact
  decimal, half to even, `-nan`. The digits come from Zig's formatter (Ryu), the layout is
  Luau's. Proven by `tools/sarcasm/check-luau-number.ts`: 211,424 doubles (random bit patterns,
  integers, halves, every power of two ± 1 ulp, 10^−330…10^310) equal to Luau's for both;
  inverted (the fixed range cut to 20: 10^20 differs).

- ✅ **The stage checker and the first modules** (2026-11-06): `src/sarcasm/sarcasm.zig` (the
  package root), `err.zig` (diagnostics: upstream's module state; a rejection stores its exact
  message and returns `error.Sarcasm`; locations are `Loc{file, line}`), `sig.zig`, `detect.zig`.
  `tools/sarcasm/check-stages.ts` runs each stage of the port (`tools/sarcasm/stage-check.zig`)
  against UPSTREAM'S OWN Luau module (the release's `pizfix/lib/sarcasm`, required by a generated
  harness under minilute), both dumped canonically: **detect** on all 1,431 corpus files, **sig**
  (parseSignature + checkSupportedClasses) on all 473 distinct `;!`/`#!` annotation bodies of the
  corpus plus 14 synthetic — 0 differ, rejection messages included. Inverted (sig's base 11 → 12:
  99 differ; detect's `.intel_syntax` → AT&T: 162 differ). Found: detect's `%%rip` check can never
  decide (`%rip` already matches the earlier `%%r[a-z0-9]`): removing it changes nothing — kept,
  as upstream has it.

- ✅ **Foundation 4, `tonumber`** (2026-11-06; found while reading the parser, which leans on it):
  `luau_number.tonumber` = luaO_str2d — C's strtod (the libc minilute links: Fil-C's musl) on the
  longest valid prefix (whitespace, sign, decimal / hex floats, inf / infinity / nan[(…)]), the
  strtoul-base-16 fallback when strtod stops at an `x`, then only whitespace. Decimal goes through
  Zig's correctly rounded parser (= musl's decfloat); HEX is a port of musl's `hexfloat()`
  (floatscan.c) in x87 `long double` (Zig's f80), because musl's result is not simply correctly
  rounded: its bias trick and strtod's narrowing round some subnormals UP (0xd.87a1cbe50f29436d8p-1047
  → …60 where exact rounding gives …5f), and Zig's own parser truncates hex past 64 bits; and
  musl's `-nan` is +nan. Proven by `check-luau-number.ts`: 18,811 strings (every operand-shaped
  corpus token, edge cases, 8,000 random long hex integers and hex floats across the exponent
  range incl. subnormals), the result's BITS equal to Luau's. (Both earlier versions failed it:
  that is the inversion.)

- ✅ **The parser** (2026-11-06): `src/sarcasm/ir.zig` (the parse IR: `Stmt`, `Operand` with
  upstream's field names as optionals, f64 numbers; numref's string `num` as `refNum`),
  `numlabel.zig`, `x86_64_parse.zig` (upstream lines 1–946: classifyReg with the per-file pseudo
  registry, regName, splitOperands, the recursive-descent constant folder with upstream's error
  order, AVX512 decorators, the AT&T and Intel operand parsers, attMnemonic, comment / annotation
  splitting, lock / rep prefixes, encoding hints, `.alloca`, the line loop). Stage **parse** in
  `check-stages.ts`: every corpus file through upstream's parseString and the port's, every
  statement serialized canonically (fields sorted, \ddd-quoted strings, tostring numbers) —
  61,518 dump lines (~84,000 operands; 154 files rejected, their messages compared), 0 differ.
  Inverted (a two-letter mnemonic given an AT&T size suffix: `bl` / `jb` statements, 29 differ).
  Not yet ported: the `.byte` decoder (decodeByteInsns, upstream lines 948–2669), called later
  by compile.

- ✅ **The ISA knowledge: `x86_64_fp.zig`, `x86_64_isa.zig`** (2026-11-07), with `util.zig` (shared
  Luau idioms) and `ir.zig`'s `Class` (classify's result: defs / uses as operand pointers,
  rmw, control, targets, pin, rep, flagsPush / flagsPop / unknown) plus the operand fields
  classify makes or reads (`implicit`, `fixedReg`, `isSlot`) and the later passes' statement
  marks (`localCall`, `localRet`, `x86_slotPartial`). The EXACT table is a comptime string map;
  upstream's width FUNCTIONS are the `WFn` enum (pmov / pmovtr carry their divisor), so
  SIZE_DRIVEN is a set of enum values; unit tests prove EXACT, BASE and FIXED have no duplicate
  keys (where Luau's later assignment would silently win). Three stages in `check-stages.ts`,
  every entry point dumped (classify with operand IDENTITY: `@i` the statement's own operand,
  `@ib`/`@ix` its base / index, `#n{…}` a fresh table numbered by first appearance, so a missing
  or extra share shows; lookup, accessWidth both lowercase and as spelled, vecEffects in
  iteration order, maskedAccessInfo, the flag predicates and masks, lockAllows / isMemRmw /
  gprAccessRegWidth, narrowSuffix, unsafeReject, hasFpReg):
  **isa** — every instruction of the 1,431 corpus files, 39,257 lines (10,692 rejections);
  **isasyn** — every name token of upstream's fp / isa sources and every corpus mnemonic, bare and
  v-prefixed, across ~150 AT&T / Intel operand shapes, plus ~400 hand-written edge lines
  (.alloca, lock / rep, high bytes, string ops, masked AVX512, narrowing converts, …):
  398,810 inputs; 203,356 classified, 194,751 rejected (12,117 distinct messages), 19 distinct
  access width/alignment pairs, 7,201 masked-access results, 2,665 pins, 2,799 shared fresh tables;
  **fplookup** — 12,169 names (those tokens with v-prefix, b/w/l/q/x/y/z suffixes, upper case):
  lookup, narrowFamily, and the dump on a zero-operand statement. **All 0 differ.** Inverted with
  ten planted faults, one at a time, files restored byte-identical after: narrowing-convert dest
  class 49 differ, an EXACT width 320, `int $3` 3, movmskPd 132, gprByPosition swapped 4,103,
  the self-zero idiom 5, loop's shared counter made fresh 191, inc/dec flag mask 164 (isa),
  mwait's implicit-only branch 2 (fplookup), cmpxchg's default width 57.
  Gap found and closed in the harness: an EMPTY input line was skipped by both sides, so sig's
  `""` annotation (one of the 14 synthetic) had never been compared (487 inputs, 486 lines). Hex
  input lines are now `x` + hex: sig 487 lines, 0 differ (`""` → "cannot parse function signature
  annotation: " on both sides); inverted (a fault only `""` reaches: exactly 1 differ).

- ✅ **prof, frame, lift, ptrflow, regalloc** (2026-11-07). `prof.zig` (inert unless
  SARCASM_PROFILE; callers pass a format, formatted only when on). `frame.zig`: the skeleton,
  the architecture policy as an interface (`Policy`, `Ctx`, `Region` with an opaque `ext` for
  transform's data). `lift.zig`: entry temps numbered in the iteration order of `entrySites` /
  `usedRegs` (Luau tables); the reaching-definition sets are bit sets (they only pick a web's
  union-find root, never the webs or their numbering — proven, not assumed: 0 differ below);
  classify is required (upstream's default is arm64's, not ported). `regalloc.zig`: every table
  upstream ITERATES is a Luau table (the first worklist move, adjacency sets, live sets, the
  caller's temps, color); lookup-only tables are hash maps. `ptrflow.zig`: isPtr / lowerTemp /
  dynamic are Luau tables; node-keyed seeds are hash maps.
  Stage **lift** (corpus, the body = the parse minus what classify rejects): liftFunction with a
  callInfo rule; ptrflow with rule-chosen seeds (arg pointers, load / call defs, save / restore
  pairs) both widening and not; regalloc.color four ways (full, 5 registers, rcx reserved, both
  argument temps precolored rdi) + liveOut; frame.preprocess through a test policy (the same on
  both sides). 68,705 lines, 0 differ: 1,277 files lifted (0–7,403 instructions, 27,134 nodes),
  pointers in 1,036, 86 dynamic webs, 121 snapshots, 60 non-convergence rejections, 53 spill
  colorings, 1,493 with aliases, 185 backstop rejections; frame 463 slots, 179 region hits, 174
  bounds rejections. Ten planted faults all caught (8 to 21,486 differ), among them REVERSED
  iteration order in regalloc's sets (2,667 differ): the stage sees Luau-order faults.
  Stage **framecalls** (frame against the REAL policy): upstream's whole driver runs on every
  corpus file with frame.preprocess wrapped; every call x86_64_frame makes into the context
  (regionOf 3,396, checkBounds 15,144, slotReg 2,357, rejectEscape 19) is logged with upstream's
  result and REPLAYED into frame.zig's Ctx: 25,230 lines, 0 differ. A boundary sweep through the
  same wrapper covers what the corpus never reaches (an access exactly at the lower bound, the
  region edges, fractional / huge offsets, located / default-file / unlocated rejections):
  inverted, `<` → `<=` at the lower bound is caught only with it (54 differ; 0 without — the gap
  it closes); a slot-name fault 2,357. What remains for frame: preprocess's own ten-line loop
  with the real policy is exercised only through the test policy until x86_64_frame is ported.
  **ptrflow's `pairs(seeds.capSave)`** (address order upstream, seed order here) is PROVEN not to
  matter: each save writes only capShot[its var], and transform rejects a second save of a name
  before recording it (transform.luau 1510–1517; one save clause per annotation, line 71);
  upstream's own test sarcasm-reject-dup-save-capability is rejected by upstream's sarcasm at the
  second save (line 13, first at 11), exit 1.

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
- next: upstream 1191 on (the control-flow rsp-depth / save-pairing analysis: transferCore …).

## What a byte-identical port must reproduce (the foundations)

1. **Luau's table iteration order** (the biggest risk). Output depends on `for k in t` over
   INTEGER-keyed tables living in the hash part, whose order is Luau's ltable algorithm (array
   part, hash part, main position, free pointer from the top, rehash/array sizing, dead keys):
   lift 253 (temp ids; key 0 is always in the hash part) and 213; regalloc 229 281 268 429 313
   343 (worklists, adjacency, "first move"); sarcasm 331 349 (order of emitted spill
   reloads/stores); transform 1727 says so in a comment. String-keyed iterations that matter are
   sorted by upstream (parse 142–150, transform 1305 5015, sarcasm 1223 1636, ptrflow 584,
   localcall 613 764). → a `LuauTable` in Zig, validated against minilute micro-scripts.
2. **Numbers are f64.** The expression folder (parse 216–375) is double arithmetic and its
   inexactness above 2^53 reaches the output; `tostring(n)` (~170 uses, incl. signature numbers
   in symbol names) is the shortest round-trip form (✅ above; not `%.14g`); `%.0f` (parse 196),
   `%02x`, `0x%08x%08x`; `bit32` ops are u32.
3. **Lua patterns**: `%s %w %d %a %x %S`, sets, lazy `.-`, frontier `%f[…]` (14), balanced
   `%b{}`, position captures `()`, `gsub` with `%1`; `string.find(…, 1, true)`. → port Luau's
   lstrlib matcher exactly.
4. **`table.sort` is unstable**: comparators at transform 82, x86_64_frame 5660 / 6081 may tie
   (not yet checked) — if so, Luau's sort algorithm exactly.
5. **Module state reset per file**: err 21 30–31, x86_64_parse 69–70 2483, x86_64_frame 263–367,
   x86_64_render 232–234.
6. No metatables, no coroutines; OOP is closures (`cgm.make`, `makeTarget`).

## Porting order (leaves first) and the stage dumps

err, build, prof (stub) → numlabel, sig, detect → **x86_64_parse** (first stage dump) →
x86_64_fp, x86_64_isa (mostly tables) → regalloc, lift, ptrflow, frame → x86_64_frame (8,934) →
x86_64_codegen → transform (5,243) → tailcall, localcall → x86_64_render, emit, x86_64_glue →
the driver. Stage dumps (S1), JSON Lines with sorted keys, numbers `%.17g`, table identities as
indices, from a patched COPY of sarcasm.luau run under minilute (env switch): after parse; after
split/decode/rewrite; after analyzeFrame (the st.x86_* fields); after lift (temps — the first test
of the table emulation); fipNodes; each regalloc round; per-function emitFip text and glue.

Sizes (lines / code): x86_64_frame 8934/5112, transform 5243/3189, x86_64_parse 2669/1960,
x86_64_isa 2032/1118 (tables + classify ~950), x86_64_fp 1693/998 (tables), x86_64_codegen
1693/1011, sarcasm 1873/1340, localcall 965/636, x86_64_render 954/598, tailcall 744/485,
x86_64_glue 724/539 (templates), ptrflow 696/389, regalloc 639/491, lift 293/235, sig 236/161,
detect 169/95, frame 134/70, numlabel 108/74, emit 97/65, build 88/61, err 87/46, prof 51/31.
