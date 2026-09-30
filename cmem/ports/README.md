# Zig ports: one file per move to a new Zig line

**Purpose (owner, 2026-09-30):** every time zilc moves to a new Zig release, record what changed
and how it was fixed, so the next port reads the notes instead of rediscovering them. With notes
from the `0.16.1-1` port, `0.16.2-1` should go faster. How lines, bases and versions work:
`../releasing.md` "Two kinds of line". The procedure: `../upstream.md` stage B.

**Layout (owner, 2026-09-30):** these files live on **`main`** with the rest of `cmem/`, one per new
line, **named by the line's first release**: `ports/0.16.2-1.md`. Later changes carried to that
line are appended to the same file, each with the release it produced and its new basis.

**Per file:** the new line and its **basis**, the Zig versions from → to, each API change with its
fix and the sites it touched, anything that surprised us, and how long it took. Copy the template
below.

The version-sensitive surface is listed in `../design-decisions.md` invariant 4, with a baseline of
about 31 std sites plus `build.zig` (2026-09-30). Re-count it after each port.

---

## (template) `<new line>-1`, basis `<reference release>` — Zig `<from>` → `<to>`, YYYY-MM-DD

| API change | fix | sites |
| --- | --- | --- |
| | | |

Surprises: …  ·  Time taken: …  ·  Surface re-count: …

---

## Zig 0.16.0 → 0.15.2, 2026-09-18 (before the versioning scheme; a DOWNGRADE, recorded for its API list)

The repo started on 0.16.0 and moved to 0.15.2 to match Fil-C's LLVM 20 (KI-3). No line/basis
existed yet. Its API differences are the list a future 0.15.2 → 0.16 port will run into, **in
reverse**:

| API | 0.16 | 0.15.2 | sites |
| --- | --- | --- | --- |
| `main` and args | `std.process.Init` | `pub fn main() !void` + `std.process.argsAlloc(arena)` | `src/main.zig` |
| stdout / I/O | `std.Io` | `std.fs.File.stdout().writer(&buf)` → `.interface`, flush before return | `src/main.zig` |
| `build.zig` | `.root_module` form | same, **no change needed** | none |
| `build.zig.zon` | | `minimum_zig_version` moved | `build.zig.zon` |

Source: `design-decisions.md` "Zig 0.15.2 API notes" and KI-3. ⚠️ wazmrt (sibling project) is on
0.16 and is the nearest working example of the 0.16 APIs, but its code does not compile on 0.15.2.
