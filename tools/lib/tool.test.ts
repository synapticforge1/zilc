// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
// Tests for tools/lib/tool.ts (`bun test tools/lib/`, run locally by release.ts).
import { afterAll, describe, expect, test } from "bun:test";
import { mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

const dir = mkdtempSync(join(tmpdir(), "zilc-tool-test-"));
afterAll(() => rmSync(dir, { recursive: true, force: true }));
// envInt exits the process on a bad value, so it runs in a child: a script that prints its result.
const script = join(dir, "env-int.ts");
writeFileSync(script, `import { envInt } from ${JSON.stringify(join(import.meta.dir, "tool.ts"))};\nconsole.log(envInt("N", 7, Number(process.env.MIN ?? 1)));\n`);
const envInt = (value: string | undefined, min = 1) => {
  const env: Record<string, string> = { ...process.env, MIN: String(min) } as Record<string, string>;
  if (value === undefined) delete env.N;
  else env.N = value;
  const p = Bun.spawnSync(["bun", script], { env, stdout: "pipe", stderr: "pipe" });
  return { code: p.exitCode, out: p.stdout.toString().trim(), err: p.stderr.toString() };
};

describe("envInt (review 1, H15)", () => {
  test("unset is the fallback; a whole number is itself", () => {
    expect(envInt(undefined)).toMatchObject({ code: 0, out: "7" });
    expect(envInt("12")).toMatchObject({ code: 0, out: "12" });
    expect(envInt("0", 0)).toMatchObject({ code: 0, out: "0" });
  });
  for (const bad of ["abc", "0", "-3", "1.5", "1e3", " 4", "99999999999999999999"]) {
    test(`"${bad}" is refused by name, exit 2`, () => {
      const r = envInt(bad);
      expect(r.code).toBe(2);
      expect(r.err).toContain("N must be a whole number of at least 1");
    });
  }
});
