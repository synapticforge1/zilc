#!/usr/bin/env -S deno run --allow-read --allow-write
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//
// Apply zilc's local fixes to Fil-C's compiler pass (FilPizlonator.cpp, which is
// Apache-2.0 WITH LLVM-exception; ledger entry `filc-pass-fixes` in
// third_party/LICENSES.md). Local use only: the patched clang is not distributed.
//
// Each edit names the exact original text and must match it exactly once, so a
// different Fil-C version fails loudly instead of being mis-patched (the same
// rule as src/stdpatch.zig).
//
//   deno run --allow-read --allow-write patch-pass.ts path/to/FilPizlonator.cpp
//
// KI-22 (cmem/workarounds.md): the frame-slot colouring tried FrameIndex = 0, 1,
// 2, ... and rescanned every neighbour at each index, O(degree x colours) per
// value; a function with N simultaneously live pointers costs about N^3 hash
// lookups. The replacement marks the indices the neighbours already hold, then
// takes the lowest unmarked one. Same values visited in the same order, same
// lowest-free-index choice: the SAME colouring, so the output is unchanged.

interface Edit {
  name: string;
  old: string;
  new: string;
}

const edits: Edit[] = [
  {
    name: "verification switch (ZILC_VERIFY_COLOURING), next to NumSpecialFrameObjects",
    old: `static constexpr size_t NumSpecialFrameObjects = 0;
`,
    new: `static constexpr size_t NumSpecialFrameObjects = 0;

// zilc (KI-22): with ZILC_VERIFY_COLOURING=1 in the environment, every frame slot is also found
// by the original search and the compile aborts if the two differ. Off by default; it restores
// the original's cost.
static bool zilcVerifyColouring() {
  static const bool On = [] {
    const char* V = getenv("ZILC_VERIFY_COLOURING");
    return V && V[0] == '1';
  }();
  return On;
}
`,
  },
  {
    name: "frame-slot colouring (FrameIndexMap, lines ~3054-3076 at bb0d0a64)",
    old: `    for (ValuePtr IP : Order) {
      const std::unordered_set<ValuePtr>& Adjacency = Interference[IP];
      for (size_t FrameIndex = NumSpecialFrameObjects; ; FrameIndex++) {
        bool Ok = true;
        for (ValuePtr AIP : Adjacency) {
          if (FrameIndexMap.count(AIP) && FrameIndexMap[AIP].Index == FrameIndex) {
            Ok = false;
            break;
          }
        }
        if (Ok) {
`,
    new: `    for (ValuePtr IP : Order) {
      const std::unordered_set<ValuePtr>& Adjacency = Interference[IP];
      // zilc (KI-22): mark the indices the neighbours hold, then take the lowest free one.
      // The original rescanned every neighbour for each candidate index (cubic on large
      // functions); this picks the same index.
      std::vector<bool> Taken(Adjacency.size() + 1, false);
      for (ValuePtr AIP : Adjacency) {
        auto Found = FrameIndexMap.find(AIP);
        if (Found != FrameIndexMap.end() && Found->second.Index >= NumSpecialFrameObjects
            && Found->second.Index - NumSpecialFrameObjects < Taken.size())
          Taken[Found->second.Index - NumSpecialFrameObjects] = true;
      }
      size_t FirstFree = 0;
      while (Taken[FirstFree])
        FirstFree++;
      if (zilcVerifyColouring()) {
        // The original search, kept to prove the two agree (ZILC_VERIFY_COLOURING=1).
        size_t Expected = NumSpecialFrameObjects;
        for (;; Expected++) {
          bool Clash = false;
          for (ValuePtr AIP : Adjacency) {
            if (FrameIndexMap.count(AIP) && FrameIndexMap[AIP].Index == Expected) {
              Clash = true;
              break;
            }
          }
          if (!Clash)
            break;
        }
        if (Expected != NumSpecialFrameObjects + FirstFree)
          report_fatal_error("zilc (KI-22): frame-slot colouring differs from the original");
      }
      for (size_t FrameIndex = NumSpecialFrameObjects + FirstFree; ; FrameIndex++) {
        bool Ok = true;
        if (Ok) {
`,
  },
  {
    name: "explicit stack-aux colouring (StackAuxInterference, lines ~3146-3160 at bb0d0a64)",
    old: `    for (AllocaInst* AI : StackAuxOrder) {
      const std::unordered_set<AllocaInst*>& Adjacency = StackAuxInterference[AI];
      for (size_t FrameIndex = FrameSize; ; FrameIndex++) {
        bool Ok = true;
        for (AllocaInst* AAI : Adjacency) {
          if (FrameIndexMap.count(ValuePtr(AAI, 0))
              && FrameIndexMap[ValuePtr(AAI, 0)].Index == FrameIndex) {
            Ok = false;
            break;
          }
        }
        if (Ok) {
`,
    new: `    for (AllocaInst* AI : StackAuxOrder) {
      const std::unordered_set<AllocaInst*>& Adjacency = StackAuxInterference[AI];
      // zilc (KI-22): same lowest-free-index choice as the original, without rescanning.
      std::vector<bool> Taken(Adjacency.size() + 1, false);
      for (AllocaInst* AAI : Adjacency) {
        auto Found = FrameIndexMap.find(ValuePtr(AAI, 0));
        if (Found != FrameIndexMap.end() && Found->second.Index >= FrameSize
            && Found->second.Index - FrameSize < Taken.size())
          Taken[Found->second.Index - FrameSize] = true;
      }
      size_t FirstFree = 0;
      while (Taken[FirstFree])
        FirstFree++;
      if (zilcVerifyColouring()) {
        size_t Expected = FrameSize;
        for (;; Expected++) {
          bool Clash = false;
          for (AllocaInst* AAI : Adjacency) {
            if (FrameIndexMap.count(ValuePtr(AAI, 0))
                && FrameIndexMap[ValuePtr(AAI, 0)].Index == Expected) {
              Clash = true;
              break;
            }
          }
          if (!Clash)
            break;
        }
        if (Expected != FrameSize + FirstFree)
          report_fatal_error("zilc (KI-22): stack-aux colouring differs from the original");
      }
      for (size_t FrameIndex = FrameSize + FirstFree; ; FrameIndex++) {
        bool Ok = true;
        if (Ok) {
`,
  },
  {
    // KI-4 (cmem/workarounds.md). With TWO OR MORE indirectbrs in a function, the copied
    // IndirectBrExpand logic merges them into one shared `switch_bb`. That (1) leaves the
    // destinations' phis naming the old indirectbr blocks, which are no longer predecessors (the
    // next CFG edit, SplitAllCriticalEdges in prepare(), then indexes a missing entry and
    // segfaults), and (2) makes every destination reachable from EVERY indirectbr site, so values
    // that dominated a destination before no longer do. Clang never takes this path (it funnels all
    // computed gotos through ONE indirectbr); Zig emits one per `continue :label`. At -O0 the
    // destinations have no phis yet, so only -O1 and up crashed.
    //
    // Fix: lower each indirectbr IN PLACE into its own switch over its own address-taken
    // destinations, with the same global block numbering. Every CFG edge is kept, so dominance and
    // phis stay valid; only edges to never-address-taken blocks and duplicate edges are dropped,
    // with their phi entries. The single-indirectbr path is untouched, so C output cannot change.
    name: "indirectbr lowering: one switch per indirectbr when there are several (KI-4)",
    old: `    if (IndirectBrs.size() == 1) {
      // If we only have one indirectbr, we can just directly replace it within
      // its block.
`,
    new: `    if (IndirectBrs.size() > 1) {
      // zilc (KI-4): lower each indirectbr in place, over its own destinations only, instead of
      // merging them into one switch_bb (which broke the destinations' phis and dominance).
      DenseMap<BasicBlock*, unsigned> BlockNumber;
      for (unsigned Index = 0; Index < BBs.size(); Index++)
        BlockNumber[BBs[Index]] = Index + 1;
      for (auto *IBr : IndirectBrs) {
        BasicBlock* From = IBr->getParent();
        SmallPtrSet<BasicBlock*, 8> Succs;
        for (BasicBlock* Succ : IBr->successors())
          Succs.insert(Succ);
        SmallVector<BasicBlock*, 8> Dests; // address-taken successors, once each, in BBs order
        for (BasicBlock* BB : BBs)
          if (Succs.count(BB))
            Dests.push_back(BB);
        SmallPtrSet<BasicBlock*, 8> Kept(Dests.begin(), Dests.end());
        // One edge From -> Dest remains per kept destination: keep exactly one phi entry for From
        // there, and none in successors that lose their edge.
        for (BasicBlock* Succ : Succs) {
          SmallVector<PHINode*, 8> Phis;
          for (PHINode& Phi : Succ->phis())
            Phis.push_back(&Phi);
          for (PHINode* Phi : Phis) {
            bool Seen = false;
            Phi->removeIncomingValueIf(
              [&] (unsigned Index) {
                if (Phi->getIncomingBlock(Index) != From)
                  return false;
                if (Kept.count(Succ) && !Seen) {
                  Seen = true;
                  return false;
                }
                return true;
              },
              /*DeletePHIIfEmpty=*/false);
            if (!Phi->getNumIncomingValues()) {
              Phi->replaceAllUsesWith(PoisonValue::get(Phi->getType()));
              Phi->eraseFromParent();
            }
          }
        }
        if (Dests.empty()) {
          (void)new UnreachableInst(F.getContext(), IBr);
          IBr->eraseFromParent();
          continue;
        }
        auto *SI = SwitchInst::Create(GetSwitchValue(IBr), Dests[0], Dests.size(), IBr);
        for (unsigned Index = 1; Index < Dests.size(); Index++)
          SI->addCase(ConstantInt::get(CommonITy, BlockNumber[Dests[Index]]), Dests[Index]);
        IBr->eraseFromParent();
      }
      return;
    }

    if (IndirectBrs.size() == 1) {
      // If we only have one indirectbr, we can just directly replace it within
      // its block.
`,
  },
];

const path = Deno.args[0];
if (!path) throw new Error("usage: patch-pass.ts path/to/FilPizlonator.cpp");
let text = await Deno.readTextFile(path);
// Each edit is applied on its own: skipped if its result is already there, applied if the exact
// original is there once, and an error otherwise.
for (const e of edits) {
  if (text.includes(e.new)) {
    console.log(`already patched: ${e.name}`);
    continue;
  }
  const n = text.split(e.old).length - 1;
  if (n !== 1) throw new Error(`${e.name}: original found ${n} times, expected 1`);
  text = text.replace(e.old, e.new);
  console.log(`patched: ${e.name}`);
}
await Deno.writeTextFile(path, text);
