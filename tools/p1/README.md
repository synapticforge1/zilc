# tools/p1 — the P1 feasibility scripts (2026-09-23)

What was actually run to produce the P1 findings in `cmem/roadmap.md` and `cmem/known-issues.md`
KI-4. Kept so the result is reproducible and so the next attempt starts from evidence.

These are **POSIX shell**, not Deno — they provision and drive a Linux toolchain inside WSL, where
shell is the native idiom and a TypeScript wrapper would only spawn the same commands. Project
scripts that process data still go in Deno/Bun (`../README.md`).

Run from Windows, pointing at a file (never inline: PowerShell mangles shell text passed to
`wsl.exe` — KI-1):

```powershell
wsl.exe -e sh /mnt/c/<path>/setup-wsl.sh
```

| script | what it does |
| --- | --- |
| `setup-wsl.sh` | Installs Fil-C 0.685, Zig 0.15.2 (SHA-256 verified) and patchelf into `~/zilc-work/`. No root. Idempotent |
| `reference-behavior.sh` | Compiles `examples/*.c` with Fil-C and prints the panics. **This is where `cmem/testing.md`'s expected output came from** |
| `zig-ir-spike.sh` | The experiment that settled the integration route: patches Fil-C's two data layouts into Zig-emitted IR and feeds it to the pass. Still fails (KI-4) — kept because re-running it is how we would notice upstream making it work |
| `zig_oob.zig` | Zig program that should trap: libc `malloc`, one-past-the-end store. No std, to isolate the question |
| `tiny.zig` | Two exported Zig functions, the smallest Zig IR we could get through the pass |
