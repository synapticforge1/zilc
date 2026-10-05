# tools/p3 — runtime scoping probes (2026-09-30)

Read-only probes of Fil-C 0.685's runtime ABI, for P3 (a runtime written in Zig). They compile a
one-line `write()` program with Fil-C and inspect the **post-pass IR**, the prebuilt libraries and
the public headers. They never read the runtime's source. Findings: `cmem/filc-abi.md`.

| script | what it shows |
| --- | --- |
| `abi-probe.ts` | how pass-compiled code calls into the runtime, `libpizlo`'s `pizlonated_zsys_write`, the link line, `NEEDED`/interpreter, and whether the symbol can be overridden |
| `cc-decode.ts` | the IR types, a full call through the fast and generic paths, `pizlonated_runtime.h`, and the capability vocabulary in `stdfil.h` |
| `write1.c` | the probe program |

Run from Windows (PowerShell mangles inline shell text, KI-1):

```powershell
deno run -A tools/p3/abi-probe.ts
```

They expect Fil-C at `~/zilc-work/tools/filc-0.685-linux-x86_64`, as set up in `roadmap.md` P1.
