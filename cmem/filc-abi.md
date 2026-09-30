# Fil-C's runtime ABI, as OBSERVED (Fil-C 0.685, x86_64) — P3 scoping, 2026-09-30

**What a Zig runtime has to match, byte for byte.** Everything here was read from **post-pass IR**
(`filc clang -O1 -S -emit-llvm` on a one-line `write()` program), from `objdump`/`readelf` of the
prebuilt libraries, and from the public headers in `pizfix/stdfil-include/`. **Nothing was read from
the runtime's source** (`libpas/`, `filc_runtime.c`). That matters for open question #3: a
clean-room runtime needs a spec like this one (`design-decisions.md`).

Scripts: `tools/p3/abi-probe.sh` and `tools/p3/cc-decode.sh` (run with `wsl.exe -e sh`).
Legend: ✅ observed directly · 🔸 inferred, **verify before building on it**.

## 1. Pointers in flight

| type (from the IR) | layout | meaning |
| --- | --- | --- |
| `%filc_flight_ptr` | `{ ptr, ptr }` | ✅ a pointer **plus its capability**: `{ ptr, lower }`. Two machine words, in `rax:rdx` when returned |
| `%filc_object` | `{ ptr, ptr }`, 16 bytes **before** `lower` | ✅ the object header. `lower = &header + 16` |

**The header word at `lower − 8`** (✅ from the call check):
- bits 0–47: **aux pointer** (mask `0xFFFF_FFFF_FFFF`)
- bits 55–58: **object kind** (mask `0x0780_0000_0000_0000`). **Function = `0x0080_0000_0000_0000`**
  (kind 1)
- bits 48–54: 🔸 other flags, probably including *freed*. Unknown.

🔸 `lower − 16` is probably **upper**, and for data objects aux points to the **aux allocation**
holding the capabilities of pointers stored *inside* the object (the "invisible capabilities" of
InvisiCap). The cc buffers below follow the same payload + aux pattern, which supports this.
Upstream's `invisicap.txt` should confirm it; read it before relying on this.

## 2. Functions

| symbol | what it is |
| --- | --- |
| `pizlonated_<name>` | ✅ **a GETTER, not the function.** `(thread, ptr) -> filc_flight_ptr`, returning a capability to the function object. In `libpizlo`, `pizlonated_zsys_write` is literally `lea function_object_zsys_write+16, rax; mov rax, rdx; ret` |
| `pizlonatedFO_<name>` | ✅ the **function object**: a `%filc_object` header, then `%filc_function` |
| `%filc_function` | ✅ `{ fast_entry, generic_entry, signature_hash: i64 }` at `lower + 0 / 8 / 16` |
| `pizlonatedFI<hash>_<name>` | ✅ the caller-side stub, weak and hidden, emitted per call signature (`write` → hash **27932**) |
| `pizlonatedFIP<n>_<name>` | ✅ a defined function's fast entry (`main` → `FIP2`) |
| `pizlonatedGP_` / `GS_` / `DO_` | ✅ global pointer / global slow-path initialiser / data object |

**A call, step by step** (✅ from `pizlonatedFI27932_write`):
1. Call the getter to get `{ptr, lower}`. Null lower → `filc_check_function_call_fail`.
2. Check that the header's kind is *function* and its aux pointer equals `ptr`. Otherwise fail.
3. If **`signature_hash` equals the caller's expectation** → **fast call**:
   `fast_entry(thread, lower, <args in registers, typed per signature>) -> { i1 exception, i64 ret }`.
4. Otherwise → **generic call**: marshal the arguments into the thread's **cc buffers**, then
   `generic_entry(thread, lower, arg_bytes) -> { i1 exception, i64 ret_bytes }` and read the result
   back from the buffer. Too few return bytes → `filc_cc_rets_check_failure`.

🔑 **Scoping consequence:** a replacement function needs only a **generic entry**, plus a fast entry
whose hash never matches. Then it never needs Fil-C's signature-hash algorithm, a pass detail we
haven't seen. The cost is speed, which is fine for a first cut. 🔸 Verify that a never-matching
hash is accepted.

## 3. The thread (every function's first argument)

| offset | field |
| --- | --- |
| `+0` | ✅ **stack limit**. Every function entry does `cmp rsp, [thread]; jae filc_stack_overflow_failure` |
| `+16` | ✅ **top frame**. Each function pushes a frame `{ parent, origin, [0 x ptr] }` and pops it on return: a **shadow stack, which is how FUGC finds roots precisely**. `origin` is the source location used in panic traces |
| `+128` | ✅ **cc payload buffer**: arguments/results, 8 bytes per word |
| `+384` | ✅ **cc aux buffer**: one capability (`lower`) per payload word, 0 for a non-pointer; 64-byte aligned |

Example (✅): `write(1, s, 3)` through the generic path stores `1, s.ptr, 3` at `+128/+136/+144`
and `0, s.lower, 0` at `+384/+392/+400`, then calls with `arg_bytes = 24`.

## 4. Globals

✅ Globals are reached through **getters with lazy initialisation**: `filc_global_initialization_start`
/ `_end` wrap building a global's data object the first time it is touched.

## 5. Linking and loading

| fact | detail |
| --- | --- |
| ✅ **dynamic by default** | a program NEEDs `libc.so`, `libpizlo.so` and `libyoloc.so`, with RUNPATH to `pizfix/lib` |
| ✅ **Fil-C's own loader** | interpreter `pizfix/lib/ld-fil1-x86_64.so` |
| ✅ link order | `crt… filc_crt.o <objects> -lc -lpizlo -lyolort -lyoloc -lyolom -lyolort -lyolounwind crt…` |
| ✅ **overridable** | `pizlonated_zsys_write` is `GLOBAL DEFAULT` in `libpizlo.so`, with no `DT_SYMBOLIC`. `libc.so` imports it by name (`UND`) |

🔑 **So `--runtime zig` should work by putting a `libzilc_rt.so` before `-lpizlo`**, or by
defining the symbols in the executable. Under standard ELF symbol lookup, the first definition
found wins. 🔸 One real run must confirm that `ld-fil1` follows standard lookup order (it is
presumably musl's loader).

## 6. What this changes in the P3 plan

- ❗ **The layers are less separable than the symbol counts suggested.** Even one `zsys_*`
  replacement must build a **function object** (header + kind + `{fast, generic, hash}`), speak the
  **generic calling convention** through the thread's cc buffers, and **read capabilities** to
  bounds-check its buffer argument. That means the object-header format, which is shared with
  the GC, comes **first**, not last.
- ❓ **Unknown, and likely important:** does a blocking system call have to tell the GC it is leaving
  managed code? With soft handshakes, a thread stuck in `write()` must not stall a collection. Look
  for an enter/exit pair in `libpizlo`'s exports and in `invisicap.txt`/`gimso_semantics.md`.
- ✅ **This spec was built entirely from observation**: the pass's output, public headers and
  binaries. That is evidence that a **clean-room runtime is feasible** (open question #3). The
  remaining gaps can likely be closed from upstream's **design docs** without reading
  `libpas`'s source.
