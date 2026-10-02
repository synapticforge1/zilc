#!/usr/bin/env -S deno run --allow-read --allow-write
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//
// Add zilc's splitting mode to LLVM's `llvm-split` (from Fil-C's LLVM fork, Apache-2.0 WITH
// LLVM-exception; ledger entry `filc-pass-fixes` in third_party/LICENSES.md), for build-speed
// lever (a): Fil-C's pass and the -O1 optimizer run on the WHOLE module, then the code generation
// of the result runs in parallel parts (cmem/workarounds.md KI-22). Local use only.
//
//   llvm-split -j N --zilc-part=I [--zilc-keep-global=FILE] -o part_I.bc whole.bc
//
// Why not stock llvm-split (measured on `69`, 2026-10-02):
//  - Stock SplitModule CLONES each part. Cloning rebuilds every value's use-list in a new order,
//    and x86 code generation depends on use-list order (register allocation): 80+ functions came
//    out different from the unsplit compile of the same bitcode. This mode instead DELETES the
//    bodies the part does not own, which keeps the surviving uses in their original order. Its
//    parts give byte-identical function code (checked function by function).
//  - Stock parts carry unused hidden declarations of thread-locals, which GNU ld refuses ("TLS
//    reference mismatches non-TLS reference"). This mode drops unused declarations.
//
// The cut: function bodies are assigned largest first, each to the least-loaded part (balance;
// ties keep module order, so every process computes the same plan). Global variables stay in part
// 0. A local (private/internal) symbol used from another part becomes hidden external in every
// part (linkage does not change code generation: measured). After `ld -r` joins the parts, zilc
// makes them local again with `objcopy --keep-global-symbols`, fed the input's own non-local
// definitions from --zilc-keep-global. That list, not a list of the shared locals, because Zig
// names contain spaces, which objcopy's symbol files cannot hold, and the input's globals are few
// and plain; and not `--localize-hidden`, because Fil-C's output has WEAK HIDDEN globals of its
// own (`pizlonatedFI…_write` etc., 25 in `69`). Shapes this mode does not handle (ifuncs, comdats,
// unnamed locals, a global named with whitespace, no globals at all) exit with code 2: zilc then
// generates the module's code whole.
//
// Same rules as patch-pass.ts: each edit names its exact original and must match once.
//
//   deno run --allow-read --allow-write patch-split.ts [--check] path/to/llvm-split.cpp

interface Edit {
  name: string;
  old: string;
  new: string;
}

const edits: Edit[] = [
  {
    name: "headers for zilc's splitting mode",
    old: `#include "llvm/IR/LLVMContext.h"
`,
    new: `#include "llvm/IR/LLVMContext.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Instruction.h"
#include "llvm/IR/Module.h"
#include <algorithm>
#include <numeric>
`,
  },
  {
    name: "zilc's splitting mode (options and implementation, before main)",
    old: `int main(int argc, char **argv) {
`,
    new: `// zilc (KI-22 lever a): see tools/filc/patch-split.ts in zilc for the why.
static cl::opt<int> ZilcPart("zilc-part", cl::init(-1),
                             cl::desc("zilc: write only part I of -j N, cut by deleting the "
                                      "other parts' bodies (keeps use-list order)"),
                             cl::cat(SplitCategory));
static cl::opt<std::string> ZilcKeepGlobal("zilc-keep-global",
                                           cl::desc("zilc: write the names of the input's "
                                                    "non-local definitions (for objcopy "
                                                    "--keep-global-symbols after ld -r)"),
                                           cl::value_desc("filename"), cl::cat(SplitCategory));

namespace {
// Which part owns a value's users: a function's part for an instruction, a global's part for an
// initializer, found through any constant expressions in between.
void zilcUserParts(const Value *V, const DenseMap<const GlobalValue *, unsigned> &Owner,
                   SmallPtrSetImpl<const Value *> &Seen, SmallVectorImpl<unsigned> &Parts) {
  for (const User *U : V->users()) {
    if (const auto *I = dyn_cast<Instruction>(U)) {
      Parts.push_back(Owner.lookup(I->getFunction()));
    } else if (const auto *G = dyn_cast<GlobalValue>(U)) {
      Parts.push_back(Owner.lookup(G));
    } else if (Seen.insert(U).second) {
      zilcUserParts(U, Owner, Seen, Parts);
    }
  }
}

int zilcSplitPart(Module &M, unsigned N, unsigned Part) {
  if (!M.ifunc_empty() || !M.getComdatSymbolTable().empty()) {
    errs() << "zilc-part: module has ifuncs or comdats; not split\\n";
    return 2;
  }
  std::vector<StringRef> Globals; // the input's non-local definitions, which stay global
  for (const GlobalValue &G : M.global_values()) {
    if (G.hasLocalLinkage() && !G.hasName()) {
      errs() << "zilc-part: module has unnamed locals; not split\\n";
      return 2;
    }
    if (!G.hasLocalLinkage() && !G.isDeclaration()) {
      // objcopy's symbol files end a name at whitespace.
      if (G.getName().find_first_of(" \\t\\r\\n") != StringRef::npos) {
        errs() << "zilc-part: a global's name has whitespace; not split\\n";
        return 2;
      }
      Globals.push_back(G.getName());
    }
  }
  if (Globals.empty()) {
    // objcopy treats an empty --keep-global-symbols list as no list at all.
    errs() << "zilc-part: module defines no globals; not split\\n";
    return 2;
  }

  // 1. The plan. Same input, same plan, in every process.
  DenseMap<const GlobalValue *, unsigned> Owner;
  std::vector<Function *> Defs;
  std::vector<uint64_t> Cost;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    uint64_t C = 1;
    for (const BasicBlock &BB : F)
      C += BB.size();
    Defs.push_back(&F);
    Cost.push_back(C);
  }
  std::vector<size_t> Order(Defs.size());
  std::iota(Order.begin(), Order.end(), 0);
  std::stable_sort(Order.begin(), Order.end(),
                   [&](size_t A, size_t B) { return Cost[A] > Cost[B]; });
  std::vector<uint64_t> Load(N, 0);
  for (size_t K : Order) {
    unsigned P = std::min_element(Load.begin(), Load.end()) - Load.begin();
    Owner[Defs[K]] = P;
    Load[P] += Cost[K];
  }
  for (GlobalVariable &GV : M.globals())
    Owner[&GV] = 0;
  for (GlobalAlias &GA : M.aliases()) {
    const GlobalObject *O = GA.getAliaseeObject();
    Owner[&GA] = O ? Owner.lookup(O) : 0;
  }

  // 2. Locals used from another part than their own become hidden external (in every part).
  std::vector<GlobalValue *> Shared;
  for (GlobalValue &G : M.global_values()) {
    if (!G.hasLocalLinkage() || G.isDeclaration())
      continue;
    SmallPtrSet<const Value *, 8> Seen;
    SmallVector<unsigned, 8> Parts;
    zilcUserParts(&G, Owner, Seen, Parts);
    unsigned Mine = Owner.lookup(&G);
    if (std::any_of(Parts.begin(), Parts.end(), [&](unsigned P) { return P != Mine; }))
      Shared.push_back(&G);
  }
  if (Part == 0 && !ZilcKeepGlobal.empty()) {
    std::error_code EC;
    raw_fd_ostream OS(ZilcKeepGlobal, EC, sys::fs::OF_Text);
    if (EC) {
      errs() << ZilcKeepGlobal << ": " << EC.message() << "\\n";
      return 1;
    }
    for (StringRef Name : Globals)
      OS << Name << "\\n";
  }
  for (GlobalValue *G : Shared) {
    G->setLinkage(GlobalValue::ExternalLinkage);
    G->setVisibility(GlobalValue::HiddenVisibility);
    G->setDSOLocal(true);
  }

  // 3. Keep only this part's definitions; the rest become declarations.
  for (Function &F : M)
    if (!F.isDeclaration() && Owner.lookup(&F) != Part) {
      GlobalValue::VisibilityTypes Vis = F.getVisibility();
      bool Local = F.isDSOLocal();
      F.deleteBody();
      F.setVisibility(Vis);
      F.setDSOLocal(Local);
    }
  for (GlobalVariable &GV : llvm::make_early_inc_range(M.globals())) {
    if (GV.isDeclaration() || Part == 0)
      continue;
    if (GV.hasAppendingLinkage()) {
      GV.eraseFromParent(); // llvm.used and friends: part 0's copy is the one.
      continue;
    }
    GV.setInitializer(nullptr);
    GV.setLinkage(GlobalValue::ExternalLinkage);
  }
  for (GlobalAlias &GA : llvm::make_early_inc_range(M.aliases())) {
    if (Owner.lookup(&GA) == Part)
      continue;
    GlobalValue *Decl;
    if (auto *FT = dyn_cast<FunctionType>(GA.getValueType()))
      Decl = Function::Create(FT, GlobalValue::ExternalLinkage, GA.getAddressSpace(), "", &M);
    else
      Decl = new GlobalVariable(M, GA.getValueType(), false, GlobalValue::ExternalLinkage,
                                nullptr, "", nullptr, GA.getThreadLocalMode(),
                                GA.getAddressSpace());
    Decl->setVisibility(GA.getVisibility());
    Decl->setDSOLocal(GA.isDSOLocal());
    Decl->takeName(&GA);
    GA.replaceAllUsesWith(Decl);
    GA.eraseFromParent();
  }

  // 4. Unused declarations go: a hidden one still becomes an undefined symbol, and for a
  // thread-local GNU ld then sees a non-TLS reference against the definition in another part.
  for (GlobalVariable &GV : llvm::make_early_inc_range(M.globals()))
    if (GV.isDeclaration() && GV.use_empty())
      GV.eraseFromParent();
  for (Function &F : llvm::make_early_inc_range(M.functions()))
    if (F.isDeclaration() && F.use_empty() && !F.isIntrinsic())
      F.eraseFromParent();

  if (verifyModule(M, &errs())) {
    errs() << "zilc-part: broken part\\n";
    return 1;
  }
  std::error_code EC;
  ToolOutputFile Out(OutputFilename, EC, sys::fs::OF_None);
  if (EC) {
    errs() << EC.message() << "\\n";
    return 1;
  }
  WriteBitcodeToFile(M, Out.os(), /*ShouldPreserveUseListOrder=*/true);
  Out.keep();
  return 0;
}
} // namespace

int main(int argc, char **argv) {
`,
  },
  {
    name: "dispatch to zilc's splitting mode after parsing",
    old: `  unsigned I = 0;
  const auto HandleModulePart`,
    new: `  if (ZilcPart >= 0) {
    if (unsigned(ZilcPart) >= NumOutputs) {
      errs() << "zilc-part: part " << ZilcPart << " of " << NumOutputs << "\\n";
      return 1;
    }
    return zilcSplitPart(*M, NumOutputs, ZilcPart);
  }

  unsigned I = 0;
  const auto HandleModulePart`,
  },
];

const check = Deno.args[0] === "--check";
const path = check ? Deno.args[1] : Deno.args[0];
if (!path) throw new Error("usage: patch-split.ts [--check] path/to/llvm-split.cpp");
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
// Only on a change (a rewrite would make ninja rebuild for nothing; see patch-pass.ts).
if (text !== original) await Deno.writeTextFile(path, text);
