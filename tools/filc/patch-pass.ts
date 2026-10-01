#!/usr/bin/env -S deno run --allow-read --allow-write
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//
// Apply zilc's local fixes to Fil-C's compiler pass (FilPizlonator.cpp, which is
// Apache-2.0 WITH LLVM-exception; ledger entry `filc-pass-colouring-fix` in
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
      for (size_t FrameIndex = FrameSize + FirstFree; ; FrameIndex++) {
        bool Ok = true;
        if (Ok) {
`,
  },
];

const path = Deno.args[0];
if (!path) throw new Error("usage: patch-pass.ts path/to/FilPizlonator.cpp");
let text = await Deno.readTextFile(path);
if (text.includes("zilc (KI-22)")) {
  console.log("already patched");
  Deno.exit(0);
}
for (const e of edits) {
  const n = text.split(e.old).length - 1;
  if (n !== 1) throw new Error(`${e.name}: original found ${n} times, expected 1`);
  text = text.replace(e.old, e.new);
  console.log(`patched: ${e.name}`);
}
await Deno.writeTextFile(path, text);
