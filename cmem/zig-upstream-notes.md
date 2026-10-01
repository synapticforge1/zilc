# Zig upstream notes: behaviours we may need to report

**Purpose (owner, 2026-09-30: "Please thoroughly note that behaviour in case we need to report it to
the Zig team").** Every Zig std or compiler behaviour that zilc has to work around goes here: what
it is, where (file:line, version), how it was found, whether it is really a Zig bug, its status in
newer Zig, and a reproduction. Report drafts live in `tools/zig-reports/<name>/`. The counterpart for
Fil-C is `tools/p2/repro/UPSTREAM-REPORT.md` (KI-4).

| # | behaviour | Zig bug? | status | report |
| --- | --- | --- | --- | --- |
| Z-1 | `std.mem.indexOfSentinel` over-reads past the string's object (SIMD, up to the page end) | **Yes, arguably**: reads outside the object; upstream already special-cases Valgrind for it | ✅ **fixed in 0.16.0** (scalar `findSentinel`); ✅ **backported into zilc's 0.15.2 std overlay** (`src/stdpatch.zig`) | `tools/zig-reports/sentinel-overread/` (draft, not filed) |
| Z-2 | `PageAllocator` passes the previous mapping's end as an `mmap` hint | **No**: a hint is advisory, and this is valid OS usage. Fil-C's `mmap` treats the hint pointer's capability strictly | still in 0.16.0 (`addr_hint`) | none; zilc overrides the page allocator |
| Z-3 | std on Linux uses raw `syscall` asm even with libc linked (gettid, futex, clock_nanosleep, statx, …) | **No**: a design choice. It conflicts with any libc-only environment (Fil-C) | see KI-7 | none; zilc reroutes them (`ir.rewriteSyscalls`) |
| Z-4 | std's panic handler captures registers with inline asm (`getcontext`) | **No**: a native-only technique | see KI-7 | none; zilc overrides `panic` |
| Z-5 | `DebugAllocator` passes a page address across a function boundary as an integer (`BucketHeader.fromPage(page_addr: usize, …)`) | **No**: valid Zig, but it discards provenance. **Worth suggesting upstream** as a provenance-friendly change: pass the pointer | same code in 0.16.0 | none; zilc std-overlay patch (KI-13 #2) |
| Z-6 | Safe-mode `+ - *` compile to `llvm.*.with.overflow` + `extractvalue`, which hides integer-pointer provenance from analyses that track plain arithmetic | **No**: correct LLVM. A Fil-C interaction. 0.16 moved `fromPage` to wrapping `+% -%` | — | none; zilc folds the value field (`ir.foldOverflowValues`, KI-13 #1) |
| Z-7 | Debug defaults to Valgrind client requests (inline asm) | **No** | — | none; zilc passes `-fno-valgrind` (KI-14) |
| Z-8 | Debug `DebugAllocator` captures a stack trace per allocation by walking raw frame pointers, probing with `process_vm_readv`; `std.Options` has no switch, and `sys_can_stack_trace` is a fixed per-arch constant | **No** (native technique). **Possible upstream suggestion:** a `std.Options` knob to disable stack capture, for capability or sandboxed targets | — | none; ❓ zilc fix pending owner decision (KI-15) |

## Z-1 in detail: `indexOfSentinel` over-read (found 2026-09-30)

- **Where:** `lib/std/mem.zig:1092`–`1140` in 0.15.2. The trap is at `:1118:48`, the first
  16-byte block load. The comment at `:1100`: *"assumes that reading past the end of the buffer
  is valid, as long as we don't read into a new page."*
- **Reached by:** `std.mem.len`, `span`, `sliceTo`, `lenSliceTo`, so `std.posix.getenv`,
  `std.process.getEnvVarOwned`, and any C-string handling.
- **When it fires under Fil-C:** when fewer than 16 bytes remain between the string start and its
  object's end. Example: a value pointer 4 bytes into a 16-byte `"FOO=…"` entry (`upper - ptr = 12`).
  A string at the start of a 16-byte object does not fire, which is why the first repro attempt
  passed.
- **Found by:** `tests/basics/zig-0.15.2/67_environment-variables` under zilc. **Minimal repro:**
  `tools/zig-reports/sentinel-overread/repro.zig`: natively `len = 11` silently; under zilc the
  identical fault at `mem.zig:1118:48`.
- **Upstream:** Valgrind special case via `std.debug.inValgrind()` (issue #17717), which needs
  `-fvalgrind` *and* a real Valgrind run. **0.16.0 replaced the function with a scalar loop**
  (`findSentinel`), so no report is needed unless 0.15.x gets a maintenance release.
- **zilc on 0.15.2:** ✅ backported upstream's 0.16.0 body through the std overlay (`src/stdpatch.zig`, KI-11, ledger `zig-std-backports`). Remove the patch when the reference line moves to 0.16.

## Z-2 in detail: `mmap` address hint (found 2026-09-30)

- **Where:** `lib/std/heap/PageAllocator.zig:94`–`112` (0.15.2) passes `std.heap.next_mmap_addr_hint`,
  set to `result_ptr + aligned_len` after each mapping, i.e. one past the end of the previous one.
  0.16.0 keeps hinting (`addr_hint`, disabled only on OpenBSD).
- **Under Fil-C:** `cannot write pointer with ptr >= upper (ptr = 0x…4000, lower 0x…3000, upper 0x…4000,
  mmap, aligned(4096))` inside `zsys_mmap`. The hint carries the previous mapping's capability and
  points exactly at its upper bound. Found by `69_http-client` (`http.Client.request` →
  certificate bundle → `DebugAllocator` → `PageAllocator.map`).
- **Verdict:** not a Zig bug. zilc avoids it with std's official hook: the entry shim declares
  `root.os.heap.page_allocator`, backed by Fil-C's malloc.
