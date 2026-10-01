# `std.mem.indexOfSentinel` reads past the end of the string (Zig 0.15.2)

**Status (2026-09-30): already fixed upstream in Zig 0.16.0**, where the function is renamed
`findSentinel` and is a plain scalar loop. This draft is kept in case the behaviour needs reporting
for a 0.15.x maintenance release, or reappears. **No report filed.**

## Summary

On x86, x86_64 and aarch64, Zig 0.15.2's `std.mem.indexOfSentinel`, which is behind
`std.mem.len`, `std.mem.span`, `std.mem.sliceTo` and therefore `std.posix.getenv` and others, scans
for the sentinel with **16-byte SIMD loads**. The first load may extend past the end of the string's
allocation, up to the page boundary. The code says so:

```zig
// lib/std/mem.zig:1100 (0.15.2)
// The below branch assumes that reading past the end of the buffer is valid, as long
// as we don't read into a new page. ...
```

Natively nothing faults, because the bytes are mapped. But the read is **outside the object**, so
any byte-precise memory checker flags it. Upstream already treats Valgrind this way: the vector path
is skipped when `std.debug.inValgrind()` (issue #17717). That check only works when the program is
built with `-fvalgrind` and is actually running under Valgrind. Other byte-precise environments, such
as Fil-C, CHERI-style capabilities, ASan-like checkers, or Valgrind on a build without
`-fvalgrind`, all see an out-of-bounds read.

## Reproduction

`repro.zig` (beside this file): a `"FOO=hello world"` entry in a 16-byte `malloc` object, and a
`[*:0]` pointer to the value, 4 bytes in, which is the shape `getenv` produces. Then `std.mem.span`.

| run | result |
| --- | --- |
| native, Zig 0.15.2 `-O ReleaseSafe -lc -target x86_64-linux-musl` | prints `len = 11`, **no error** (the over-read is silent) |
| zilc (Fil-C 0.685) | `filc safety error: cannot read 16 bytes when upper - ptr = 12.` at **`mem.zig:1118:48: mem.indexOfSentinel`** ← `mem.len` ← `mem.span` ← `repro.zig:24:30` |
| Valgrind memcheck on the native ReleaseSafe build | expected `Invalid read of size 16` (not run here: no Valgrind in this WSL) |

First seen in the wild: `tests/basics/zig-0.15.2/67_environment-variables` under zilc,
`std.process.getEnvVarOwned` → `posix.getenv` → `mem.sliceTo` → `indexOfSentinel`.

## Versions

| Zig | behaviour |
| --- | --- |
| 0.15.2 | vectorised, reads past the end (`mem.zig:1092`–`1140`) |
| **0.16.0** | **scalar:** `pub fn findSentinel(...) { var i: usize = 0; while (p[i] != sentinel) i += 1; return i; }`, with `indexOfSentinel` kept as a deprecated alias. A test named "findSentinel vector paths" remains, now exercising the scalar loop |

## If it ever needs filing

- **Where:** Codeberg `ziglang/zig` (Zig moved off GitHub). Check first whether the 0.16 change has
  its own issue or PR to cite, or whether #17717 covers it.
- **Ask:** a backport to 0.15.x, if a 0.15.3 is planned; otherwise nothing, since it's fixed.
- **Key point:** the over-read is outside the object, not just past the sentinel. It is invisible
  natively and fatal under any byte-precise checker. Valgrind's special case shows upstream already
  considered it a correctness issue for checkers.
