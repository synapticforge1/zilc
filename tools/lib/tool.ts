// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//
// Shared helpers for zilc's tools (Deno), which replaced the shell scripts on 2026-10-05 so the
// tools run the same way on every OS (owner: "Can we make the bash scripts deno scripts so that
// are cross platform?").
//
// The one idea: a tool is written ONCE, as code for the platform its work needs.
//   * Tools whose work needs Linux (Fil-C exists only there) call `linuxOnly()` first. On Linux it
//     returns; on Windows it re-runs the same tool inside WSL, with the same arguments and zilc's
//     environment variables, and exits with its status. This replaces typing
//     `wsl.exe -e sh /mnt/d/…/tool.sh`, and the "pass shell text to WSL as a file" rule (KI-1):
//     arguments go to wsl.exe as an argument list, never through a shell's quoting.
//   * Tools that need no Linux (git, Windows' own Zig) just run, on any OS.
//
// Run a tool:   deno run -A tools/<group>/<tool>.ts [args]      (from Windows or from Linux)

import { copy } from "jsr:@std/fs@1/copy";
import { expandGlob } from "jsr:@std/fs@1/expand-glob";
import { dirname, fromFileUrl, join } from "jsr:@std/path@1";

export const isWindows = Deno.build.os === "windows";

/** Forward slashes on every OS (Windows accepts them), so tools can split paths on "/". */
export function slashes(p: string): string {
  return p.replaceAll("\\", "/");
}

/** The repository root (this file is tools/lib/tool.ts). */
export const REPO = slashes(join(dirname(fromFileUrl(import.meta.url)), "..", ".."));

/** An environment variable, or a default. */
export function env(name: string, fallback = ""): string {
  return Deno.env.get(name) ?? fallback;
}

export const HOME = env("HOME", env("USERPROFILE"));
/** zilc's Linux work area: tools, builds and results outside the repo (the repo is on exFAT). */
export const WORK = env("WORK", `${HOME}/zilc-work`);

/** The Zig that compiles user code, as installed in WSL. */
export const ZIG = env("ZILC_ZIG", `${WORK}/tools/zig-0.15.2/zig`);
export const FILC_PATCHED_TREE = `${WORK}/tools/filc-0.685-zilc`;
export const FILC_PREBUILT_TREE = `${WORK}/tools/filc-0.685-linux-x86_64`;

/** Fil-C's clang for zilc: ZILC_FILC, else the patched build (KI-22), else the prebuilt. */
export function filc(): string {
  const set = Deno.env.get("ZILC_FILC");
  if (set) return set;
  const patched = `${FILC_PATCHED_TREE}/build/bin/clang`;
  return existsSync(patched) ? patched : `${FILC_PREBUILT_TREE}/build/bin/clang`;
}

/** D:\a\b -> /mnt/d/a/b, the path WSL sees. */
export function wslPath(p: string): string {
  const m = p.replaceAll("\\", "/").match(/^([A-Za-z]):\/(.*)$/);
  return m ? `/mnt/${m[1].toLowerCase()}/${m[2]}` : p.replaceAll("\\", "/");
}

/** Variables a tool forwards into WSL (wsl.exe passes none by itself). */
const FORWARD = /^(ZILC_|ZIG_|FILC_|FUGC_)|^(JOBS|MODE|MODES|LANGS|OUTROOT|WORK|TBUILD|ZIGDIR|NS|N|RR|A|B|IN|SRC|DEST|VERBOSE)$/;

/**
 * For tools whose work needs Linux. Call it first in the tool's body, and, in a file other tools
 * IMPORT, only under `if (import.meta.main)`: imports run before the importer's body, so a
 * top-level call there would re-launch the imported file instead of the tool.
 * On Linux: returns. On Windows: runs this same tool inside WSL
 * (Deno at ~/.deno/bin/deno there) and exits with its status; the caller never continues.
 */
export async function linuxOnly(meta: ImportMeta): Promise<void> {
  if (Deno.build.os === "linux") return;
  if (!isWindows) throw new Error(`${meta.url}: needs Linux (Fil-C), or Windows with WSL`);
  const script = wslPath(slashes(fromFileUrl(meta.url)));
  const fwd = Object.entries(Deno.env.toObject()).filter(([k]) => FORWARD.test(k)).map(([k, v]) => `${k}=${v}`);
  const { code } = await new Deno.Command("wsl.exe", {
    args: ["-e", "env", ...fwd, "sh", "-c", 'exec "$HOME/.deno/bin/deno" run -A "$0" "$@"', script, ...Deno.args],
    stdin: "inherit", stdout: "inherit", stderr: "inherit",
  }).output();
  Deno.exit(code);
}

export interface RunOptions {
  cwd?: string;
  /** Added to (or, with `cleanEnv`, instead of) the current environment. */
  env?: Record<string, string>;
  /** Start from an empty environment: only `env` is set. */
  cleanEnv?: boolean;
  /** Text written to the program's stdin (else it gets none). */
  stdin?: string;
  /** Seconds; then the program is killed and `timedOut` is set (like `timeout`, exit 124). */
  timeout?: number;
  /** Stream output to this terminal instead of capturing it. */
  inherit?: boolean;
  /** Write stdout and stderr, interleaved as produced, to this file (like `> file 2>&1`). */
  outFile?: string;
  /** Append instead of truncating `outFile`. */
  append?: boolean;
}

export interface RunResult {
  code: number;
  /** Captured stdout + stderr when neither `inherit` nor `outFile` is set. */
  out: string;
  timedOut: boolean;
}

/**
 * Runs a program with arguments (no shell parsing). A missing program is exit 127, as in a shell.
 *
 * ⚠️ Captured and `outFile` output is stdout and stderr MERGED IN ORDER, like `> file 2>&1`. Read
 * through two pipes, a program that writes to both (39_logging) came out with its lines in a
 * different order every run (found 2026-10-05 by the output comparison). So on Linux the child's
 * stderr is pointed at its stdout before it starts (`sh -c 'exec "$@" 2>&1'`: one stream, one
 * order). Windows has no `sh`; there the two pipes remain.
 */
export async function run(argv: string[], o: RunOptions = {}): Promise<RunResult> {
  const capture = !o.inherit && !o.outFile;
  const merge = !o.inherit && !isWindows;
  if (merge) argv = ["sh", "-c", 'exec "$@" 2>&1', "sh", ...argv];
  let file: Deno.FsFile | undefined;
  if (o.outFile) file = await Deno.open(o.outFile, { write: true, create: true, append: !!o.append, truncate: !o.append });
  let child: Deno.ChildProcess;
  try {
    child = new Deno.Command(argv[0], {
      args: argv.slice(1),
      cwd: o.cwd,
      env: o.env,
      clearEnv: !!o.cleanEnv,
      stdin: o.stdin !== undefined ? "piped" : "null",
      stdout: o.inherit ? "inherit" : "piped",
      stderr: o.inherit ? "inherit" : "piped",
    }).spawn();
  } catch (e) {
    file?.close();
    if (e instanceof Deno.errors.NotFound) return { code: 127, out: `${argv[0]}: not found\n`, timedOut: false };
    throw e;
  }
  let timedOut = false;
  const timer = o.timeout ? setTimeout(() => { timedOut = true; try { child.kill("SIGKILL"); } catch { /* gone */ } }, o.timeout * 1000) : undefined;
  if (o.stdin !== undefined) {
    const w = child.stdin.getWriter();
    await w.write(new TextEncoder().encode(o.stdin)).catch(() => {});
    await w.close().catch(() => {});
  }
  const chunks: Uint8Array[] = [];
  const sink = async (s: ReadableStream<Uint8Array> | null) => {
    if (!s) return;
    for await (const c of s) {
      if (file) await file.write(c);
      else chunks.push(c);
    }
  };
  if (!o.inherit) await Promise.all([sink(child.stdout), sink(child.stderr)]);
  const status = await child.status;
  if (timer) clearTimeout(timer);
  file?.close();
  const out = capture ? new TextDecoder().decode(concat(chunks)) : "";
  // `exec` replaced the sh, so a missing program is sh's 127, as before.
  return { code: timedOut ? 124 : status.code, out, timedOut };
}

/** Like `run`, but throws unless the program exits 0; returns its output. */
export async function must(argv: string[], o: RunOptions = {}): Promise<string> {
  const r = await run(argv, o);
  if (r.code !== 0) {
    if (r.out) console.error(r.out.trimEnd());
    throw new Error(`failed (exit ${r.code}): ${argv.join(" ")}`);
  }
  return r.out;
}

/** Runs a program with its output on this terminal; returns its exit code. */
export async function show(argv: string[], o: RunOptions = {}): Promise<number> {
  return (await run(argv, { ...o, inherit: true })).code;
}

/** For the few places a shell is the right tool (a pipeline of Unix programs). */
export async function sh(script: string, o: RunOptions = {}): Promise<RunResult> {
  return run(["sh", "-c", script], o);
}

/** Runs `fn` on every item, at most `jobs` at a time; results in input order. */
export async function pool<T, R>(items: T[], jobs: number, fn: (item: T, index: number) => Promise<R>): Promise<R[]> {
  const out = new Array<R>(items.length);
  let next = 0;
  const worker = async () => {
    while (next < items.length) {
      const i = next++;
      out[i] = await fn(items[i], i);
    }
  };
  await Promise.all(Array.from({ length: Math.max(1, Math.min(jobs, items.length)) }, worker));
  return out;
}

/** Paths matching a glob, sorted (like the shell's expansion). */
export async function glob(pattern: string): Promise<string[]> {
  const found: string[] = [];
  for await (const e of expandGlob(pattern)) found.push(slashes(e.path));
  return found.sort();
}

export function existsSync(p: string): boolean {
  try {
    Deno.statSync(p);
    return true;
  } catch {
    return false;
  }
}
export async function exists(p: string): Promise<boolean> {
  return (await Deno.stat(p).catch(() => null)) !== null;
}
export async function rmrf(p: string): Promise<void> {
  await Deno.remove(p, { recursive: true }).catch(() => {});
}
export async function mkdirp(p: string): Promise<void> {
  await Deno.mkdir(p, { recursive: true });
}
/** `cp -r src dest` (dest must not exist). */
export async function copyTree(src: string, dest: string): Promise<void> {
  await copy(src, dest, { overwrite: true, preserveTimestamps: true });
}
export async function size(p: string): Promise<number | null> {
  return (await Deno.stat(p).catch(() => null))?.size ?? null;
}
export function basename(p: string): string {
  return p.replace(/\/+$/, "").split("/").pop() ?? p;
}
/** Seconds since `t0` (from `Date.now()`), one decimal. */
export function since(t0: number): string {
  return ((Date.now() - t0) / 1000).toFixed(1);
}
/** Integer from an environment variable, or a default. */
export function envInt(name: string, fallback: number): number {
  const v = Deno.env.get(name);
  return v ? Number(v) : fallback;
}
/** The program's first line matching `re`, or "". */
export function firstMatch(text: string, re: RegExp): string {
  for (const line of text.split("\n")) if (re.test(line)) return line;
  return "";
}

function concat(chunks: Uint8Array[]): Uint8Array {
  const all = new Uint8Array(chunks.reduce((n, c) => n + c.length, 0));
  let at = 0;
  for (const c of chunks) {
    all.set(c, at);
    at += c.length;
  }
  return all;
}
