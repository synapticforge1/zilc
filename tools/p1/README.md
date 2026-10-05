# tools/p1 — the P1 feasibility scripts (2026-09-23)

What was actually run to produce the P1 findings in `cmem/roadmap.md` and `cmem/known-issues.md`
KI-4. Kept so the result is reproducible and so the next attempt starts from evidence.

The experiments are **Deno** tools since 2026-10-05 (converted from shell and checked to reproduce
the same results; `../README.md`). Run them from Windows or Linux:

```
deno run -A tools/p1/<tool>.ts
```

The one exception is **`setup-wsl.sh`**, which stays shell: it prepares a fresh Ubuntu before Deno
is installed there. Run it from Windows pointing at the file (never inline: PowerShell mangles shell
text passed to `wsl.exe`, KI-1):

```powershell
wsl.exe -e sh /mnt/c/<path>/setup-wsl.sh
```

| file | what it does |
| --- | --- |
| `setup-wsl.sh` | Installs Fil-C 0.685, Zig 0.15.2 (SHA-256 verified) and patchelf into `~/zilc-work/`. No root. Idempotent |
| `reference-behavior.ts` | Compiles `examples/*.c` with Fil-C and prints the panics. **This is where `cmem/testing.md`'s expected output came from** |
| `stock-llvm-validity.ts` | Which of Fil-C's IR features a stock LLVM rejects (the table in `cmem/known-issues.md` KI-4) |
| `zig-ir-spike.ts` | The experiment that settled the integration route: patches Fil-C's two data layouts into Zig-emitted IR and feeds it to the pass. Still fails (KI-4) — kept because re-running it is how we would notice upstream making it work |
| `zig_oob.zig` | Zig program that should trap: libc `malloc`, one-past-the-end store. No std, to isolate the question |
| `tiny.zig` | Two exported Zig functions, the smallest Zig IR we could get through the pass |

## 📌 Inputs that live outside the repo (record, 2026-10-05)

`zig-ir-spike.ts` reads two Zig-emitted IR files from `$WORK/p1` (`~/zilc-work/p1`), made on
2026-09-23 and **not in the repo** (≈12 MB each). If they are lost, regenerate them **inside
`$WORK/p1`** with Zig 0.15.2 from the committed sources:

```
zig build-obj -target x86_64-linux-gnu -femit-llvm-ir=tiny.ll -fno-emit-bin tiny.zig
zig build-exe -target x86_64-linux-gnu -lc -femit-llvm-ir=zig_oob-x86_64-linux-gnu.ll -fno-emit-bin zig_oob.zig
```

Verified 2026-10-05 against the originals: the same code; only 3 debug-info lines per file differ,
the build directory (twice; identical when built in `$WORK/p1`) and the hash of Zig's cache folder
for its generated `builtin.zig`, which varies per run. The spike then writes `tiny-ni2.ll`, which
`tools/p2/dialect-probe.ts` uses: the one phase-experiment input with no committed source of its own
(`../p2/README.md`).
