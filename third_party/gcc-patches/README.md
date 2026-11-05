# third_party/gcc-patches/

**Upstream GCC backports, applied unchanged** by the maintainer-only `zig build gcc-reference`
(`build/gcc_reference.zig`, `tools/gcc-reference.zig`), which builds the GCC versions Fil-C's
release was built with (11.4.0, 12.3.0) as the reference for zilc's comparison chain. Users never
build GCC (`cmem/design-decisions.md`).

| file | upstream | why |
| --- | --- | --- |
| `gcc-11.4.0-PR111632-safe-ctype.patch` | releases/gcc-11 `5a419c22`, backport of master `9970b576` (PR middle-end/111632); first in GCC 11.5.0 | `zig c++` uses libc++, whose `<map>` reaches `<locale>`; GCC 11.4's `system.h` included it after `safe-ctype.h`'s poisoning macros |
| `gcc-12.3.0-PR111632-safe-ctype.patch` | releases/gcc-12 `a995fded`, the same backport; first in GCC 12.4.0 | the same |

- **License:** `GPL-3.0-or-later`, as the GCC file they change. They are separate files, not part
  of zilc's own code, and not linked into anything zilc ships (`third_party/LICENSES.md`,
  `gcc-reference`).
- **Form:** each file is a header written by zilc (provenance, reason, test) followed by the
  upstream commit's diff, byte for byte as GitHub's `.patch` view serves it. The header replaces the
  format-patch mail headers, which carried e-mail addresses.
- **Nothing to submit:** GCC already has the change; on a move to GCC 11.5+ / 12.4+ these files go.
