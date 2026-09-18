# tools/

Developer tooling for zilc. Empty for now.

Scripts here are written for **Deno** or **Bun** (`.ts` / `.mjs`), not Python. That's the owner's
preference (2026-09-18), in keeping with the project's memory-safety goal. Build logic stays in
`build.zig`.

Planned (see `cmem/roadmap.md`):

- an upstream-sync helper that diffs the tracked Fil-C paths between two pinned SHAs (`cmem/upstream.md`)
- a bug-example gate runner that checks each `examples/*.c` panics with the expected fault (`cmem/testing.md`)
