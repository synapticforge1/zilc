// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
//
// Shared helpers for zilc's tools (Bun). They replaced the shell scripts on 2026-10-05 as Deno
// tools, so the tools run the same way on every OS (owner: "Can we make the bash scripts deno
// scripts so that are cross platform?"), and moved to Bun on 2026-10-22 (owner: Bun only, Deno is
// going away). They use Node's APIs (`node:*`, `process`) plus `Bun.spawn`/`Bun.Glob`.
//
// The one idea: a tool is written ONCE, as code for the platform its work needs.
//   * Tools whose work needs Linux (Fil-C exists only there) call `linuxOnly()` first. On Linux it
//     returns; on Windows it re-runs the same tool inside WSL, with the same arguments and zilc's
//     environment variables, and exits with its status. This replaces typing
//     `wsl.exe -e sh /mnt/d/…/tool.sh`, and the "pass shell text to WSL as a file" rule (KI-1):
//     arguments go to wsl.exe as an argument list, never through a shell's quoting.
//   * Tools that need no Linux (git, Windows' own Zig) just run, on any OS.
//
// Run a tool:   bun tools/<group>/<tool>.ts [args]      (from Windows or from Linux)

import { statSync } from "node:fs";
import { cp, mkdir, open, rm, stat } from "node:fs/promises";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

export const isWindows = process.platform === "win32";

/** The tool's arguments (what follows the script on the command line). */
export const ARGS = process.argv.slice(2);

/** Forward slashes on every OS (Windows accepts them), so tools can split paths on "/". */
export function slashes(p: string): string {
  return p.replaceAll("\\", "/");
}

/** The repository root (this file is tools/lib/tool.ts). */
export const REPO = slashes(join(dirname(fileURLToPath(import.meta.url)), "..", ".."));

/** An environment variable, or a default. */
export function env(name: string, fallback = ""): string {
  return process.env[name] ?? fallback;
}

export const HOME = env("HOME", env("USERPROFILE"));
/** zilc's Linux work area: tools, builds and results outside the repo (the repo is on exFAT). */
export const WORK = env("WORK", `${HOME}/zilc-work`);

/** The Zig that compiles user code, as installed in WSL. */
export const ZIG = env("ZILC_ZIG", `${WORK}/tools/zig-0.15.2/zig`);
/**
 * The Fil-C release zilc builds on, and the commit its clang names in `clang --version` (the
 * source zilc's patched clang is built from). Change both together with src/root.zig's
 * `filc_release`; every tree, archive and tag name below follows. (0.685 → 0.686 on 2026-10-05.)
 */
export const FILC_VERSION = "0.686";
export const FILC_SHA = "163fae598eaf249b74065b0156f3a7e7ba8c0e5a";
/** The URL the source's `origin` must have: clang's version string prints it (build-patched-clang.ts). */
export const FILC_SOURCE_URL = "git@github.com:pizlonator/fil-c.git";

/** A release's stock prebuilt, as setup-wsl.sh unpacks it. */
export function filcPrebuiltTree(version: string): string {
  return `${WORK}/tools/filc-${version}-linux-x86_64`;
}
export const FILC_PATCHED_TREE = `${WORK}/tools/filc-${FILC_VERSION}-zilc`;
export const FILC_PREBUILT_TREE = filcPrebuiltTree(FILC_VERSION);
/**
 * Fil-C 0.685's prebuilt: the phase experiments (tools/p1–p3) RECORD what that release did, so they
 * keep running it after zilc moved on. Kept installed for them.
 */
export const FILC_0685_PREBUILT_TREE = filcPrebuiltTree("0.685");

/** Fil-C's clang for zilc: ZILC_FILC, else the patched build (KI-22), else the prebuilt. */
export function filc(): string {
  const set = process.env.ZILC_FILC;
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
 * (Bun at ~/.bun/bin/bun there, installed by tools/p1/setup-wsl.sh) and exits with its status;
 * the caller never continues.
 */
export async function linuxOnly(meta: ImportMeta): Promise<void> {
  if (process.platform === "linux") return;
  if (!isWindows) throw new Error(`${meta.url}: needs Linux (Fil-C), or Windows with WSL`);
  const script = wslPath(slashes(fileURLToPath(meta.url)));
  const fwd = Object.entries(process.env).filter(([k]) => FORWARD.test(k)).map(([k, v]) => `${k}=${v}`);
  const child = Bun.spawn(["wsl.exe", "-e", "env", ...fwd, "sh", "-c", 'exec "$HOME/.bun/bin/bun" "$0" "$@"', script, ...ARGS], {
    stdin: "inherit", stdout: "inherit", stderr: "inherit",
  });
  process.exit(await child.exited);
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
  const file = o.outFile ? await open(o.outFile, o.append ? "a" : "w") : undefined;
  let child: Bun.Subprocess<"ignore" | Uint8Array, "inherit" | "pipe", "inherit" | "pipe">;
  try {
    child = Bun.spawn(argv, {
      cwd: o.cwd,
      // Bun.spawn's `env` replaces the environment; Deno's added to it, and the tools expect that.
      env: o.cleanEnv ? (o.env ?? {}) : { ...process.env, ...o.env },
      stdin: o.stdin !== undefined ? new TextEncoder().encode(o.stdin) : "ignore",
      stdout: o.inherit ? "inherit" : "pipe",
      stderr: o.inherit ? "inherit" : "pipe",
    });
  } catch (e) {
    await file?.close();
    // Bun throws (code ENOENT) when the program does not exist, before anything runs.
    if ((e as NodeJS.ErrnoException).code === "ENOENT") return { code: 127, out: `${argv[0]}: not found\n`, timedOut: false };
    throw e;
  }
  let timedOut = false;
  const timer = o.timeout ? setTimeout(() => { timedOut = true; try { child.kill("SIGKILL"); } catch { /* gone */ } }, o.timeout * 1000) : undefined;
  const chunks: Uint8Array[] = [];
  const sink = async (s: ReadableStream<Uint8Array> | number | undefined) => {
    if (!s || typeof s === "number") return;
    for await (const c of s) {
      if (file) await file.write(c);
      else chunks.push(c);
    }
  };
  if (!o.inherit) await Promise.all([sink(child.stdout), sink(child.stderr)]);
  // A signal reads as 128 + its number (SIGSEGV 139), as Deno reported it and as a shell does.
  const code = await child.exited;
  if (timer) clearTimeout(timer);
  await file?.close();
  const out = capture ? new TextDecoder().decode(concat(chunks)) : "";
  // `exec` replaced the sh, so a missing program is sh's 127, as before.
  return { code: timedOut ? 124 : code, out, timedOut };
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

/**
 * Paths matching a glob, sorted (like the shell's expansion). The pattern is absolute; Bun.Glob
 * scans from a directory, so the literal leading directories become that directory.
 */
export async function glob(pattern: string): Promise<string[]> {
  const parts = slashes(pattern).split("/");
  const wild = parts.findIndex((s) => /[*?[{]/.test(s));
  if (wild < 0) return existsSync(pattern) ? [slashes(pattern)] : [];
  const base = parts.slice(0, wild).join("/") || "/";
  if (!existsSync(base)) return [];
  const found: string[] = [];
  for await (const p of new Bun.Glob(parts.slice(wild).join("/")).scan({ cwd: base, onlyFiles: false })) {
    found.push(`${base}/${slashes(p)}`);
  }
  return found.sort();
}

export function existsSync(p: string): boolean {
  try {
    statSync(p);
    return true;
  } catch {
    return false;
  }
}
export async function exists(p: string): Promise<boolean> {
  return (await stat(p).catch(() => null)) !== null;
}
export async function rmrf(p: string): Promise<void> {
  await rm(p, { recursive: true, force: true });
}
export async function mkdirp(p: string): Promise<void> {
  await mkdir(p, { recursive: true });
}
/** `cp -r src dest` (dest must not exist). Symlinks are copied as links, as @std/fs's copy did. */
export async function copyTree(src: string, dest: string): Promise<void> {
  await cp(src, dest, { recursive: true, force: true, preserveTimestamps: true, verbatimSymlinks: true });
}
export async function size(p: string): Promise<number | null> {
  return (await stat(p).catch(() => null))?.size ?? null;
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
  const v = process.env[name];
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
