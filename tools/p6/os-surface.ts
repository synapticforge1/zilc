// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//
// P6 platforms scope pass (roadmap.md P6, pre-publish): how big is the OS layer Zig's std needs on
// each target? Compiles every tests/basics Zig program with PLAIN Zig 0.15.2 to Zig's UNOPTIMIZED
// LLVM IR (the module zilc feeds Fil-C, KI-17), for each target, and counts in it:
//   - external functions: every `declare` that is not an LLVM intrinsic or compiler-rt helper.
//     That is what the program needs from the OS's libraries (libc, libSystem, kernel32/ntdll),
//     so it sizes the checked-wrapper layer a memory-safe runtime must provide there.
//   - raw kernel entries: inline asm containing `syscall` / `svc` (KI-7's class: under Fil-C these
//     are refused, and a Zig runtime must route them through checked helpers).
//   - integer-to-pointer functions: functions containing `inttoptr i64 %v` (the KI-5 family: pointers built
//     from integers carry no capability under Fil-C). Counted per std function, so the sites a
//     target ADDS over x86_64-linux-musl show where its OS layer would trap.
// Plus how many programs compile at all for the target (Zig's std refuses some APIs on some OSes).
// No Fil-C involved, nothing is linked: it measures Zig's std, not zilc. Linux; from Windows it runs
// inside WSL.
//
//   deno run -A tools/p6/os-surface.ts        env: JOBS (default 12), TARGETS (space-separated)
// Writes $WORK/p6/os-surface.json (per target: the symbol lists) and prints the summary table.
import { basename, env, envInt, glob, linuxOnly, mkdirp, pool, REPO, rmrf, run, WORK, ZIG } from "../lib/tool.ts";

await linuxOnly(import.meta);

// -lc where the platform's C library is how std reaches the OS (Linux musl as zilc builds; Android
// Bionic; Darwin always links libSystem). Windows std talks to kernel32/ntdll directly, no libc.
const targets: { t: string; lc: boolean }[] = (env("TARGETS") ||
  "x86_64-linux-musl aarch64-linux-musl aarch64-linux-android x86_64-linux-android aarch64-macos x86_64-macos aarch64-ios x86_64-windows aarch64-windows")
  .split(" ").filter(Boolean).map((t) => ({ t, lc: !t.includes("windows") }));

const out = `${WORK}/p6`;
await rmrf(`${out}/ir`);
await mkdirp(`${out}/ir`);
const files = await glob(`${REPO}/tests/basics/zig-0.15.2/*/*.zig`);

// compiler-rt and Zig-internal helpers that every target has; not OS surface.
const notOs = /^(llvm\.|__(udiv|umod|div|mod|mul|add|sub|neg|ashl|ashr|lshr|fix|float|trunc|extend|cmp|unord|eq|ne|lt|le|gt|ge|pow|clz|ctz|popcount|bswap|bitreverse|parity|zig_|stack_chk|chkstk)|_tls_index$|fmaq|memcpy$|memset$|memmove$|memcmp$)/;

interface Prog { ok: boolean; err?: string; ext: string[]; asm: number; i2p: string[] }

const results: Record<string, Record<string, Prog>> = {};
for (const { t, lc } of targets) {
  const progs = await pool(files, envInt("JOBS", 12), async (f): Promise<[string, Prog]> => {
    const name = basename(f.slice(0, f.lastIndexOf("/")));
    const ll = `${out}/ir/${t}-${name}.ll`;
    const r = await run([ZIG, "build-obj", "-target", t, "-O", "ReleaseSafe", "-fno-emit-bin",
      `--verbose-llvm-ir=${ll}`, "-fllvm", "-fno-stack-check", ...(lc ? ["-lc"] : []), f],
      { cwd: `${out}/ir`, timeout: 900 });
    if (r.code !== 0) {
      const err = (r.out.split("\n").find((l) => l.includes("error:")) ?? `exit ${r.code}`).replace(/.*error: /, "");
      await rmrf(ll);
      return [name, { ok: false, err, ext: [], asm: 0, i2p: [] }];
    }
    const ir = await Deno.readTextFile(ll);
    await rmrf(ll); // ~10 MB each
    const ext = new Set<string>();
    for (const m of ir.matchAll(/^declare [^@]*@("[^"]+"|[\w.$]+)\(/gm)) {
      const s = m[1].replace(/^"|"$/g, "");
      if (!notOs.test(s)) ext.add(s);
    }
    const asm = [...ir.matchAll(/asm sideeffect "[^"]*\b(syscall|svc)\b/g)].length;
    // Only `inttoptr i64 %value`: a pointer built from a RUNTIME integer. Constant ones
    // (`inttoptr (i64 -6148914691236517206 to ptr)`, Zig's 0xaa.. undefined pattern, and -1
    // sentinels) are in most functions and are never dereferenced. Anonymous-type numbers
    // (`__struct_3400`) differ between targets, so they are masked to compare names.
    const i2p = new Set<string>();
    let fn = "";
    for (const line of ir.split("\n")) {
      const d = line.match(/^define [^@]*@("[^"]+"|[\w.$]+)\(/);
      if (d) fn = d[1].replace(/^"|"$/g, "").replace(/__(anon|struct|enum|union|opaque)_\d+/g, "__$1");
      else if (fn && /inttoptr i(64|32) %/.test(line)) i2p.add(fn);
      else if (line === "}") fn = "";
    }
    return [name, { ok: true, ext: [...ext].sort(), asm, i2p: [...i2p].sort() }];
  });
  results[t] = Object.fromEntries(progs);
  const ok = progs.filter(([, p]) => p.ok).length;
  console.error(`${t}: ${ok}/${files.length} compile`);
}
await Deno.writeTextFile(`${out}/os-surface.json`, JSON.stringify(results, null, 1));

// The summary. "Std" names keep Zig's mangling (`posix.read`, `os.linux.x86_64.syscall3`, ...).
const base = results["x86_64-linux-musl"];
const union = (t: string, k: "ext" | "i2p") => new Set(Object.values(results[t]).flatMap((p) => p[k]));
const baseI2p = base ? union("x86_64-linux-musl", "i2p") : new Set<string>();
const baseExt = base ? union("x86_64-linux-musl", "ext") : new Set<string>();
console.log("| target | compile | external functions (union) | median per program | syscall/svc asm sites | inttoptr functions | new vs x86_64-linux-musl (ext / inttoptr) |");
console.log("| --- | --- | --- | --- | --- | --- | --- |");
for (const { t } of targets) {
  const ps = Object.values(results[t]);
  const ok = ps.filter((p) => p.ok);
  const ext = union(t, "ext"), i2p = union(t, "i2p");
  const per = ok.map((p) => p.ext.length).sort((a, b) => a - b);
  const asm = ok.reduce((n, p) => n + p.asm, 0);
  const newExt = [...ext].filter((s) => !baseExt.has(s)).length;
  const newI2p = [...i2p].filter((s) => !baseI2p.has(s)).length;
  console.log(`| ${t} | ${ok.length}/${ps.length} | ${ext.size} | ${per[per.length >> 1] ?? 0} | ${asm} | ${i2p.size} | ${newExt} / ${newI2p} |`);
}
console.log("\n-- compile failures by reason:");
for (const { t } of targets) {
  const counts = new Map<string, number>();
  for (const p of Object.values(results[t])) if (!p.ok) counts.set(p.err!, (counts.get(p.err!) ?? 0) + 1);
  for (const [k, n] of [...counts].sort((a, b) => b[1] - a[1])) console.log(`  ${t}: ${n} × ${k.slice(0, 140)}`);
}
