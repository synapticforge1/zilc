// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception OR MIT
// Tests for tools/release/github-tag.ts against a mock of GitHub's REST API (`bun test
// tools/release/`, run by CI's `checks`). The mock records every request, so each refusal case
// asserts that nothing was written.
import { afterAll, beforeAll, expect, test } from "bun:test";
import { join } from "node:path";

const SCRIPT = join(import.meta.dir, "github-tag.ts");
const REPO = "owner/repo";
const TAG = "v0.15.2-0.687.9";
const SHA = "a".repeat(40);
const OTHER = "b".repeat(40);
const TAGOBJ = "c".repeat(40);
const NEWOBJ = "d".repeat(40);

type State = {
  ref: null | { type: "commit" | "tag"; sha: string }; // refs/tags/<TAG>'s object
  tagObjects: Record<string, { type: string; sha: string }>; // annotated tag objects by sha
  tagPostStatus?: number;
  refPostStatus?: number; // 422 = the ref appeared meanwhile
  refAppearsAt?: string; // with 422: where the concurrent ref points
  readBackAt?: string; // the ref's commit as read back after the POST
  stallMs?: number;
};

let state: State;
let requests: { method: string; path: string; body: any }[] = [];
let server: ReturnType<typeof Bun.serve>;

beforeAll(() => {
  server = Bun.serve({
    port: 0,
    async fetch(req) {
      const url = new URL(req.url);
      const body = req.method === "POST" ? await req.json() : null;
      requests.push({ method: req.method, path: url.pathname, body });
      if (state.stallMs) await Bun.sleep(state.stallMs);
      const json = (status: number, v: unknown) => new Response(JSON.stringify(v), { status });
      if (req.method === "GET" && url.pathname === `/repos/${REPO}/git/ref/tags/${TAG}`) {
        return state.ref ? json(200, { object: state.ref }) : json(404, { message: "Not Found" });
      }
      const m = url.pathname.match(new RegExp(`^/repos/${REPO}/git/tags/([0-9a-f]{40})$`));
      if (req.method === "GET" && m && state.tagObjects[m[1]]) return json(200, { object: state.tagObjects[m[1]] });
      if (req.method === "POST" && url.pathname === `/repos/${REPO}/git/tags`) {
        const status = state.tagPostStatus ?? 201;
        if (status !== 201) return json(status, { message: "Validation Failed" });
        state.tagObjects[NEWOBJ] = { type: "commit", sha: body.object };
        return json(201, { sha: NEWOBJ, tag: body.tag });
      }
      if (req.method === "POST" && url.pathname === `/repos/${REPO}/git/refs`) {
        const status = state.refPostStatus ?? 201;
        if (status === 422) {
          state.ref = { type: "commit", sha: state.refAppearsAt ?? SHA };
          return json(422, { message: "Reference already exists" });
        }
        if (status !== 201) return json(status, { message: "boom" });
        state.ref = state.readBackAt ? { type: "commit", sha: state.readBackAt } : { type: "tag", sha: body.sha };
        return json(201, { ref: body.ref });
      }
      return json(404, { message: `unmocked ${req.method} ${url.pathname}` });
    },
  });
});

afterAll(() => server.stop(true));

async function run(env: Record<string, string> = {}, args: string[] = []) {
  requests = [];
  const p = Bun.spawn([process.execPath, SCRIPT, ...args], {
    env: {
      ...process.env,
      GITHUB_REPOSITORY: REPO,
      RELEASE_TAG: TAG,
      RELEASE_SHA: SHA,
      GITHUB_TOKEN: "t",
      GITHUB_API_URL: `http://127.0.0.1:${server.port}`,
      RELEASE_TIMEOUT_MS: "2000",
      ...env,
    },
    stdout: "pipe",
    stderr: "pipe",
  });
  const [out, err, code] = await Promise.all([new Response(p.stdout).text(), new Response(p.stderr).text(), p.exited]);
  return { code, out: out + err };
}

const posts = () => requests.filter((r) => r.method === "POST");

test("no tag yet: the annotated tag is created on the commit and read back", async () => {
  state = { ref: null, tagObjects: {} };
  const r = await run();
  expect(r.code).toBe(0);
  expect(posts().map((p) => p.path)).toEqual([`/repos/${REPO}/git/tags`, `/repos/${REPO}/git/refs`]);
  expect(posts()[0].body).toEqual({ tag: TAG, message: `zilc ${TAG}`, object: SHA, type: "commit" });
  expect(posts()[1].body).toEqual({ ref: `refs/tags/${TAG}`, sha: NEWOBJ });
  expect(r.out).toContain(`tag ${TAG} created on ${SHA}`);
});

test("the tag already on this commit: done, no write (a re-run is safe)", async () => {
  state = { ref: { type: "commit", sha: SHA }, tagObjects: {} };
  const r = await run();
  expect(r.code).toBe(0);
  expect(r.out).toContain("already exists");
  expect(posts()).toHaveLength(0);
});

test("an annotated tag already on this commit is peeled: done, no write", async () => {
  state = { ref: { type: "tag", sha: TAGOBJ }, tagObjects: { [TAGOBJ]: { type: "commit", sha: SHA } } };
  const r = await run();
  expect(r.code).toBe(0);
  expect(posts()).toHaveLength(0);
});

test("the tag at another commit is refused — a published tag never moves", async () => {
  state = { ref: { type: "commit", sha: OTHER }, tagObjects: {} };
  const r = await run();
  expect(r.code).toBe(1);
  expect(r.out).toContain("never moves");
  expect(posts()).toHaveLength(0);
});

test("a refused tag-object POST fails, and no ref is written", async () => {
  state = { ref: null, tagObjects: {}, tagPostStatus: 403 };
  const r = await run();
  expect(r.code).toBe(1);
  expect(r.out).toContain("POST git/tags");
  expect(posts().filter((p) => p.path.endsWith("/git/refs"))).toHaveLength(0);
});

test("a concurrent run made the ref on this commit (422): accepted after the read-back", async () => {
  state = { ref: null, tagObjects: {}, refPostStatus: 422, refAppearsAt: SHA };
  const r = await run();
  expect(r.code).toBe(0);
  expect(r.out).toContain("appeared meanwhile");
});

test("a concurrent ref at another commit (422) fails the read-back", async () => {
  state = { ref: null, tagObjects: {}, refPostStatus: 422, refAppearsAt: OTHER };
  const r = await run();
  expect(r.code).toBe(1);
  expect(r.out).toContain("read-back");
});

test("any other refusal of the ref POST fails", async () => {
  state = { ref: null, tagObjects: {}, refPostStatus: 500 };
  const r = await run();
  expect(r.code).toBe(1);
  expect(r.out).toContain("POST git/refs");
});

test("a read-back at another commit fails", async () => {
  state = { ref: null, tagObjects: {}, readBackAt: OTHER };
  const r = await run();
  expect(r.code).toBe(1);
  expect(r.out).toContain(`peels to ${OTHER}`);
});

test("a server that does not answer hits the time limit, no write", async () => {
  state = { ref: null, tagObjects: {}, stallMs: 3000 };
  const r = await run({ RELEASE_TIMEOUT_MS: "300" });
  expect(r.code).toBe(1);
  expect(r.out).toContain("timed out after 300 ms");
  expect(posts()).toHaveLength(0);
});

test("no token: the read runs, the write is refused", async () => {
  state = { ref: null, tagObjects: {} };
  const r = await run({ GITHUB_TOKEN: "" });
  expect(r.code).toBe(1);
  expect(r.out).toContain("GITHUB_TOKEN is not set");
  expect(posts()).toHaveLength(0);
});

test("--dry-run reads and writes nothing", async () => {
  state = { ref: null, tagObjects: {} };
  const r = await run({}, ["--dry-run"]);
  expect(r.code).toBe(0);
  expect(r.out).toContain("dry-run: would create");
  expect(posts()).toHaveLength(0);
});

test("a tag that is not zilc's form is refused before any request", async () => {
  state = { ref: null, tagObjects: {} };
  for (const bad of ["v1.2.3", "0.15.2-0.687.1", "v0.15.2-0.687", "v0.15.2-0.687.1-rc"]) {
    const r = await run({ RELEASE_TAG: bad });
    expect(r.code).toBe(1);
    expect(r.out).toContain("is not a v<Zig>-<Fil-C>.<N> tag");
    expect(requests).toHaveLength(0);
  }
});
