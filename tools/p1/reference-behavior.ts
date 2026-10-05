// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//
// P1 step 2: record Fil-C's reference behavior on the zilc bug examples (examples/oob_write.c,
// examples/use_after_free.c). This is where cmem/testing.md's expected output came from ("THE
// EXPECTED OUTPUT IS RECORDED (2026-09-23)": both exit 133, SIGTRAP, with the fault kind and
// file:line:column). Linux; from Windows it runs inside WSL.
//
//   deno run -A tools/p1/reference-behavior.ts
//   env: WORK (default ~/zilc-work)
// Output: $WORK/p1/{hello.c,hello,<name>,<name>.build.log,<name>.out}, and the same report on the
// terminal as the shell version (tools/p1/reference-behavior.sh).
//
// Fil-C's clang is the STOCK PREBUILT 0.685 on purpose (not filc(), which prefers zilc's patched
// build): the recorded reference is upstream Fil-C's behavior, before any zilc patch existed.
import { FILC_PREBUILT_TREE, linuxOnly, mkdirp, REPO, run, show, WORK } from "../lib/tool.ts";

await linuxOnly(import.meta);
const FILC = `${FILC_PREBUILT_TREE}/build/bin/clang`;
const OUT = `${WORK}/p1`;
await mkdirp(OUT);

/**
 * What sh (dash) itself writes to the job's redirected stderr when the program dies by a signal.
 * The shell version ran `"$OUT/$name" > "$OUT/$name.out" 2>&1`, so dash's "Trace/breakpoint trap"
 * line landed at the end of each .out file and in the printed report. Deno is not a shell and
 * writes no such line, so it is appended here to keep the recorded files and report identical.
 */
const SHELL_SIGNAL_TEXT: Record<number, string> = {
  4: "Illegal instruction", 5: "Trace/breakpoint trap", 6: "Aborted", 7: "Bus error",
  8: "Floating point exception", 9: "Killed", 11: "Segmentation fault",
};

console.log("== filcc version");
// `"$FILC" --version | head -2`
console.log((await run([FILC, "--version"])).out.split("\n").slice(0, 2).join("\n"));

console.log();
console.log("== sanity: hello world");
await Deno.writeTextFile(`${OUT}/hello.c`, '#include <stdio.h>\nint main(void){printf("hello from Fil-C\\n");return 0;}\n');
// `cc && ./hello; echo "exit=$?"`: the status is the compiler's if it failed, else the program's.
let code = await show([FILC, "-O2", "-g", "-o", `${OUT}/hello`, `${OUT}/hello.c`]);
if (code === 0) code = await show([`${OUT}/hello`]);
console.log(`exit=${code}`);

for (const name of ["oob_write", "use_after_free"]) {
  console.log();
  console.log("======================================================================");
  console.log(`== ${name}`);
  console.log("======================================================================");
  // The build log was the compiler's stderr only (`2>`); clang writes nothing to stdout here, so
  // capturing both is the same file.
  const build = await run([FILC, "-O2", "-g", "-o", `${OUT}/${name}`, `${REPO}/examples/${name}.c`], { outFile: `${OUT}/${name}.build.log` });
  if (build.code === 0) {
    console.log("-- compiled");
  } else {
    console.log("-- COMPILE FAILED");
    console.log((await Deno.readTextFile(`${OUT}/${name}.build.log`)).trimEnd());
    continue;
  }
  const r = await run([`${OUT}/${name}`], { outFile: `${OUT}/${name}.out` });
  const sig = r.code > 128 ? SHELL_SIGNAL_TEXT[r.code - 128] : undefined;
  if (sig) await Deno.writeTextFile(`${OUT}/${name}.out`, `${sig}\n`, { append: true });
  console.log(`-- exit=${r.code}`);
  console.log("-- output:");
  await Deno.stdout.write(await Deno.readFile(`${OUT}/${name}.out`));
}
