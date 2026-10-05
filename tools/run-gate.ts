// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//
// Run `zig build gate` where Fil-C lives (Linux; from Windows, inside WSL automatically).
//
//   deno run -A tools/run-gate.ts [extra zig build args]
//
// The Zig cache goes to the Linux home on purpose: the repo is on an exFAT drive, and a cache there
// is poisoned after one build (cmem/known-issues.md KI-2). Fil-C's clang: ZILC_FILC, else zilc's
// patched build (KI-22, tools/filc/build-patched-clang.ts), else the stock prebuilt.
import { filc, HOME, linuxOnly, REPO, show, ZIG } from "./lib/tool.ts";

await linuxOnly(import.meta);
Deno.exit(await show([ZIG, "build", "--build-file", `${REPO}/build.zig`, "gate", ...Deno.args], {
  env: { ZILC_ZIG: ZIG, ZILC_FILC: filc(), ZIG_LOCAL_CACHE_DIR: `${HOME}/.cache/zilc-zig` },
}));
