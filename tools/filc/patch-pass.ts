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

// zilc (KI-22 lever b): with ZILC_VERIFY_INTERFERENCE=1, the original hash-set interference graph
// is built too and the compile aborts unless it equals the dense one, neighbour set by neighbour
// set. Off by default; it restores the original's cost.
static bool zilcVerifyInterference() {
  static const bool On = [] {
    const char* V = getenv("ZILC_VERIFY_INTERFERENCE");
    return V && V[0] == '1';
  }();
  return On;
}
`,
  },
  {
    // ⚠️ The original has a line of six spaces after `Live = LiveAtTail[BB];`, kept below. Editors
    // that trim trailing whitespace break the match ("original found 0 times"); restore it.
    name: "interference graph over dense ids (KI-22 lever b, lines ~2970-3046 at bb0d0a64)",
    old: `    std::unordered_map<ValuePtr, std::unordered_set<ValuePtr>> Interference;

    for (size_t BlockIndex = Blocks.size(); BlockIndex--;) {
      BasicBlock* BB = Blocks[BlockIndex];
      std::unordered_set<Value*> Live = LiveAtTail[BB];
      
      for (auto It = BB->rbegin(); It != BB->rend(); ++It) {
        Instruction* I = &*It;

        Instruction* Defined = nullptr;
        if (LifetimeMarker LM = analyzeLifetimeMarker(I)) {
          if (LM.LMK == LifetimeMarkerKind::Start) {
            Live.erase(LM.AI);
            Defined = LM.AI;
          }
        } else {
          Live.erase(I);
          Defined = I;
        }

        if (Defined) {
          size_t NumIPtrs = countPtrsForValue(Defined);
          if (NumIPtrs) {
            for (Value* LV : Live) {
              size_t NumVIPtrs = countPtrsForValue(LV);
              for (size_t LVPtrIndex = NumVIPtrs; LVPtrIndex--;) {
                for (size_t IPtrIndex = NumIPtrs; IPtrIndex--;) {
                  Interference[ValuePtr(Defined, IPtrIndex)].insert(ValuePtr(LV, LVPtrIndex));
                  Interference[ValuePtr(LV, LVPtrIndex)].insert(ValuePtr(Defined, IPtrIndex));
                }
              }
            }
          }
        }

        if (LifetimeMarker LM = analyzeLifetimeMarker(I)) {
          if (LM.LMK == LifetimeMarkerKind::End)
            Live.insert(LM.AI);
        } else {
          for (Value* V : I->operand_values()) {
            if (Value* LV = LiveCast(V))
              Live.insert(LV);
          }
        }
      }
    }

    // The arguments interfere with one another.
    for (Argument& A1 : OldF->args()) {
      size_t NumA1Ptrs = countPtrs(A1.getType());
      if (!NumA1Ptrs)
        continue;
      for (Argument& A2 : OldF->args()) {
        size_t NumA2Ptrs = countPtrs(A2.getType());
        for (size_t A2PtrIndex = NumA2Ptrs; A2PtrIndex--;) {
          for (size_t A1PtrIndex = NumA1Ptrs; A1PtrIndex--;)
            Interference[ValuePtr(&A1, A1PtrIndex)].insert(ValuePtr(&A2, A2PtrIndex));
        }
      }
    }

    // All indices for a value interfere with one another.
    for (Argument& A : OldF->args()) {
      for (size_t PtrIndex = countPtrs(A.getType()); PtrIndex--;) {
        for (size_t APtrIndex = countPtrs(A.getType()); APtrIndex--;)
          Interference[ValuePtr(&A, PtrIndex)].insert(ValuePtr(&A, APtrIndex));
      }
    }
    for (BasicBlock* BB : Blocks) {
      for (Instruction& I : *BB) {
        for (size_t PtrIndex = countPtrsForValue(&I); PtrIndex--;) {
          for (size_t APtrIndex = countPtrsForValue(&I); APtrIndex--;)
            Interference[ValuePtr(&I, PtrIndex)].insert(ValuePtr(&I, APtrIndex));
        }
      }
    }
`,
    new: `    // zilc (KI-22 lever b): the SAME interference graph, built over dense ids. The original
    // inserted every (definition x live value) pair into hash sets keyed by ValuePtr, ~40% of
    // this pass on a big Zig module. Here every value gets a number and a range of ids (one per
    // pointer slot), the live set is a dense set of value numbers, and a neighbour list is a
    // plain vector. Duplicates are allowed: the colouring only asks which indices the
    // neighbours hold. ZILC_VERIFY_INTERFERENCE=1 builds the original too and compares.
    DenseMap<Value*, unsigned> ZilcValNum;  // value -> value number
    std::vector<unsigned> ZilcValCount;     // countPtrsForValue: what the def x live edges use
    std::vector<unsigned> ZilcValBase;      // the value's first id
    std::vector<ValuePtr> ZilcPtrOf;        // id -> ValuePtr
    std::vector<std::vector<uint32_t>> ZilcAdj;
    auto ZilcNumber = [&](Value* V) -> unsigned {
      auto Found = ZilcValNum.find(V);
      if (Found != ZilcValNum.end())
        return Found->second;
      unsigned N = ZilcValCount.size();
      ZilcValNum[V] = N;
      size_t Count = countPtrsForValue(V);
      size_t Slots = Count;
      // The argument edges below count an argument's slots with countPtrs(type) instead.
      if (Argument* A = dyn_cast<Argument>(V))
        Slots = std::max(Slots, countPtrs(A->getType()));
      ZilcValCount.push_back(Count);
      ZilcValBase.push_back(ZilcPtrOf.size());
      for (size_t PtrIndex = 0; PtrIndex < Slots; PtrIndex++)
        ZilcPtrOf.push_back(ValuePtr(V, PtrIndex));
      ZilcAdj.resize(ZilcPtrOf.size());
      return N;
    };
    for (Argument& A : OldF->args())
      ZilcNumber(&A);
    for (BasicBlock* BB : Blocks) {
      for (Instruction& I : *BB)
        ZilcNumber(&I);
    }

    // The live set: value numbers, with each one's position for O(1) erase.
    std::vector<uint32_t> ZilcLive;
    std::vector<uint32_t> ZilcLivePos;
    auto ZilcLiveInsert = [&](unsigned N) {
      if (ZilcLivePos.size() <= N)
        ZilcLivePos.resize(ZilcValCount.size(), UINT32_MAX);
      if (ZilcLivePos[N] == UINT32_MAX) {
        ZilcLivePos[N] = ZilcLive.size();
        ZilcLive.push_back(N);
      }
    };
    auto ZilcLiveErase = [&](Value* V) {
      auto Found = ZilcValNum.find(V);
      if (Found == ZilcValNum.end())
        return;
      unsigned N = Found->second;
      if (N >= ZilcLivePos.size() || ZilcLivePos[N] == UINT32_MAX)
        return;
      uint32_t Pos = ZilcLivePos[N];
      uint32_t Last = ZilcLive.back();
      ZilcLive[Pos] = Last;
      ZilcLivePos[Last] = Pos;
      ZilcLive.pop_back();
      ZilcLivePos[N] = UINT32_MAX;
    };

    for (size_t BlockIndex = Blocks.size(); BlockIndex--;) {
      BasicBlock* BB = Blocks[BlockIndex];
      for (uint32_t N : ZilcLive)
        ZilcLivePos[N] = UINT32_MAX;
      ZilcLive.clear();
      for (Value* V : LiveAtTail[BB])
        ZilcLiveInsert(ZilcNumber(V));

      for (auto It = BB->rbegin(); It != BB->rend(); ++It) {
        Instruction* I = &*It;

        Instruction* Defined = nullptr;
        if (LifetimeMarker LM = analyzeLifetimeMarker(I)) {
          if (LM.LMK == LifetimeMarkerKind::Start) {
            ZilcLiveErase(LM.AI);
            Defined = LM.AI;
          }
        } else {
          ZilcLiveErase(I);
          Defined = I;
        }

        if (Defined) {
          unsigned DN = ZilcNumber(Defined);
          size_t NumIPtrs = ZilcValCount[DN];
          if (NumIPtrs) {
            uint32_t DBase = ZilcValBase[DN];
            for (uint32_t LN : ZilcLive) {
              uint32_t LBase = ZilcValBase[LN];
              for (size_t LVPtrIndex = ZilcValCount[LN]; LVPtrIndex--;) {
                for (size_t IPtrIndex = NumIPtrs; IPtrIndex--;) {
                  ZilcAdj[DBase + IPtrIndex].push_back(LBase + LVPtrIndex);
                  ZilcAdj[LBase + LVPtrIndex].push_back(DBase + IPtrIndex);
                }
              }
            }
          }
        }

        if (LifetimeMarker LM = analyzeLifetimeMarker(I)) {
          if (LM.LMK == LifetimeMarkerKind::End)
            ZilcLiveInsert(ZilcNumber(LM.AI));
        } else {
          for (Value* V : I->operand_values()) {
            if (Value* LV = LiveCast(V))
              ZilcLiveInsert(ZilcNumber(LV));
          }
        }
      }
    }

    // The arguments interfere with one another.
    for (Argument& A1 : OldF->args()) {
      size_t NumA1Ptrs = countPtrs(A1.getType());
      if (!NumA1Ptrs)
        continue;
      uint32_t Base1 = ZilcValBase[ZilcNumber(&A1)];
      for (Argument& A2 : OldF->args()) {
        size_t NumA2Ptrs = countPtrs(A2.getType());
        uint32_t Base2 = ZilcValBase[ZilcNumber(&A2)];
        for (size_t A2PtrIndex = NumA2Ptrs; A2PtrIndex--;) {
          for (size_t A1PtrIndex = NumA1Ptrs; A1PtrIndex--;)
            ZilcAdj[Base1 + A1PtrIndex].push_back(Base2 + A2PtrIndex);
        }
      }
    }

    // All indices for a value interfere with one another.
    for (Argument& A : OldF->args()) {
      uint32_t Base = ZilcValBase[ZilcNumber(&A)];
      for (size_t PtrIndex = countPtrs(A.getType()); PtrIndex--;) {
        for (size_t APtrIndex = countPtrs(A.getType()); APtrIndex--;)
          ZilcAdj[Base + PtrIndex].push_back(Base + APtrIndex);
      }
    }
    for (BasicBlock* BB : Blocks) {
      for (Instruction& I : *BB) {
        uint32_t Base = ZilcValBase[ZilcNumber(&I)];
        for (size_t PtrIndex = countPtrsForValue(&I); PtrIndex--;) {
          for (size_t APtrIndex = countPtrsForValue(&I); APtrIndex--;)
            ZilcAdj[Base + PtrIndex].push_back(Base + APtrIndex);
        }
      }
    }

    if (zilcVerifyInterference()) {
      // The original construction, verbatim, then the two graphs compared as sets.
      std::unordered_map<ValuePtr, std::unordered_set<ValuePtr>> Interference;
      for (size_t BlockIndex = Blocks.size(); BlockIndex--;) {
        BasicBlock* BB = Blocks[BlockIndex];
        std::unordered_set<Value*> Live = LiveAtTail[BB];
        for (auto It = BB->rbegin(); It != BB->rend(); ++It) {
          Instruction* I = &*It;
          Instruction* Defined = nullptr;
          if (LifetimeMarker LM = analyzeLifetimeMarker(I)) {
            if (LM.LMK == LifetimeMarkerKind::Start) {
              Live.erase(LM.AI);
              Defined = LM.AI;
            }
          } else {
            Live.erase(I);
            Defined = I;
          }
          if (Defined) {
            size_t NumIPtrs = countPtrsForValue(Defined);
            if (NumIPtrs) {
              for (Value* LV : Live) {
                size_t NumVIPtrs = countPtrsForValue(LV);
                for (size_t LVPtrIndex = NumVIPtrs; LVPtrIndex--;) {
                  for (size_t IPtrIndex = NumIPtrs; IPtrIndex--;) {
                    Interference[ValuePtr(Defined, IPtrIndex)].insert(ValuePtr(LV, LVPtrIndex));
                    Interference[ValuePtr(LV, LVPtrIndex)].insert(ValuePtr(Defined, IPtrIndex));
                  }
                }
              }
            }
          }
          if (LifetimeMarker LM = analyzeLifetimeMarker(I)) {
            if (LM.LMK == LifetimeMarkerKind::End)
              Live.insert(LM.AI);
          } else {
            for (Value* V : I->operand_values()) {
              if (Value* LV = LiveCast(V))
                Live.insert(LV);
            }
          }
        }
      }
      for (Argument& A1 : OldF->args()) {
        size_t NumA1Ptrs = countPtrs(A1.getType());
        if (!NumA1Ptrs)
          continue;
        for (Argument& A2 : OldF->args()) {
          size_t NumA2Ptrs = countPtrs(A2.getType());
          for (size_t A2PtrIndex = NumA2Ptrs; A2PtrIndex--;) {
            for (size_t A1PtrIndex = NumA1Ptrs; A1PtrIndex--;)
              Interference[ValuePtr(&A1, A1PtrIndex)].insert(ValuePtr(&A2, A2PtrIndex));
          }
        }
      }
      for (Argument& A : OldF->args()) {
        for (size_t PtrIndex = countPtrs(A.getType()); PtrIndex--;) {
          for (size_t APtrIndex = countPtrs(A.getType()); APtrIndex--;)
            Interference[ValuePtr(&A, PtrIndex)].insert(ValuePtr(&A, APtrIndex));
        }
      }
      for (BasicBlock* BB : Blocks) {
        for (Instruction& I : *BB) {
          for (size_t PtrIndex = countPtrsForValue(&I); PtrIndex--;) {
            for (size_t APtrIndex = countPtrsForValue(&I); APtrIndex--;)
              Interference[ValuePtr(&I, PtrIndex)].insert(ValuePtr(&I, APtrIndex));
          }
        }
      }
      for (size_t Id = 0; Id < ZilcAdj.size(); Id++) {
        std::unordered_set<ValuePtr> Mine;
        for (uint32_t N : ZilcAdj[Id])
          Mine.insert(ZilcPtrOf[N]);
        auto Found = Interference.find(ZilcPtrOf[Id]);
        if (Found == Interference.end() ? !Mine.empty() : Found->second != Mine)
          report_fatal_error("zilc (KI-22): interference graph differs from the original");
      }
      for (auto& Entry : Interference) {
        if (Entry.second.empty())
          continue;
        auto Found = ZilcValNum.find(Entry.first.V);
        if (Found == ZilcValNum.end()
            || ZilcValBase[Found->second] + Entry.first.PtrIndex >= ZilcPtrOf.size()
            || !(ZilcPtrOf[ZilcValBase[Found->second] + Entry.first.PtrIndex] == Entry.first))
          report_fatal_error("zilc (KI-22): original interference has a value the dense graph lacks");
      }
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
          FrameEntryKind FEK;
          PointerKind PK = pointerKindDirect(IP.V);
          assert(PK == PointerKind::Escaping || PK == PointerKind::LocalNaked);
          if (PK == PointerKind::LocalNaked)
            FEK = FrameEntryKind::LowerFromStackAux;
          else
            FEK = FrameEntryKind::Lower;
          FrameIndexMap[IP] = FrameEntry(FEK, FrameIndex);
`,
    new: `    // zilc (KI-22 lever b): the index each id holds, mirrored from FrameIndexMap (which already
    // holds the Ignored entries made just above), so the colouring makes no hash lookups.
    std::vector<size_t> ZilcHeld(ZilcPtrOf.size(), SIZE_MAX);
    for (auto& Entry : FrameIndexMap) {
      auto Found = ZilcValNum.find(Entry.first.V);
      if (Found == ZilcValNum.end())
        continue;
      size_t Id = ZilcValBase[Found->second] + Entry.first.PtrIndex;
      if (Id < ZilcPtrOf.size() && ZilcPtrOf[Id] == Entry.first)
        ZilcHeld[Id] = Entry.second.Index;
    }

    for (ValuePtr IP : Order) {
      const size_t IPId = ZilcValBase[ZilcNumber(IP.V)] + IP.PtrIndex;
      const std::vector<uint32_t>& Adjacency = ZilcAdj[IPId];
      // zilc (KI-22): mark the indices the neighbours hold, then take the lowest free one.
      // The original rescanned every neighbour for each candidate index (cubic on large
      // functions); this picks the same index. (Lever b: neighbours are dense ids, which may
      // repeat; the size bound still leaves a free index in range.)
      std::vector<bool> Taken(Adjacency.size() + 1, false);
      for (uint32_t N : Adjacency) {
        size_t Held = ZilcHeld[N];
        if (Held != SIZE_MAX && Held >= NumSpecialFrameObjects
            && Held - NumSpecialFrameObjects < Taken.size())
          Taken[Held - NumSpecialFrameObjects] = true;
      }
      size_t FirstFree = 0;
      while (Taken[FirstFree])
        FirstFree++;
      if (zilcVerifyColouring()) {
        // The original search, kept to prove the two agree (ZILC_VERIFY_COLOURING=1). It reads
        // FrameIndexMap itself, so it also checks the ZilcHeld mirror.
        size_t Expected = NumSpecialFrameObjects;
        for (;; Expected++) {
          bool Clash = false;
          for (uint32_t N : Adjacency) {
            ValuePtr AIP = ZilcPtrOf[N];
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
          FrameEntryKind FEK;
          PointerKind PK = pointerKindDirect(IP.V);
          assert(PK == PointerKind::Escaping || PK == PointerKind::LocalNaked);
          if (PK == PointerKind::LocalNaked)
            FEK = FrameEntryKind::LowerFromStackAux;
          else
            FEK = FrameEntryKind::Lower;
          FrameIndexMap[IP] = FrameEntry(FEK, FrameIndex);
          ZilcHeld[IPId] = FrameIndex;
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

// `--check`: report, edit by edit, whether the patch would apply, WITHOUT writing. Used by
// tools/upstream/check-upstream.ts against upstream's newest FilPizlonator.cpp. Exit 1 if any
// edit's original text is gone (upstream changed the code we patch: re-derive that edit).
const check = Deno.args[0] === "--check";
const path = check ? Deno.args[1] : Deno.args[0];
if (!path) throw new Error("usage: patch-pass.ts [--check] path/to/FilPizlonator.cpp");
let text = await Deno.readTextFile(path);
const original = text;
if (check) {
  let broken = 0;
  for (const e of edits) {
    const n = text.split(e.old).length - 1;
    const state = text.includes(e.new) ? "already applied" : n === 1 ? "applies" : `ORIGINAL FOUND ${n} TIMES (expected 1)`;
    if (!text.includes(e.new) && n !== 1) broken++;
    console.log(`  ${state.padEnd(36)} ${e.name}`);
  }
  Deno.exit(broken ? 1 : 0);
}
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
// Only on a change: rewriting an already-patched file bumps its timestamp, and ninja would then
// recompile it and relink clang for nothing.
if (text !== original) await Deno.writeTextFile(path, text);
