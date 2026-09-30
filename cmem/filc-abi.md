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

**The header is `struct filc_object { size_t size; uintptr_t aux; }`**, 16 bytes immediately
before `lower` (📄 `invisicap.txt`; matches the IR):
- **`lower − 16`: `size`**, the payload size rounded up to 8. **Upper = lower + size.** (Corrects the
  earlier guess that this word was upper.) **Specials, including functions, have size 0**, so no
  loads or stores are possible through them.
- **`lower − 8`: `aux`**. ✅📄 **Bits 0–47: aux pointer. Bits 48–63: flags**, including
  **READONLY** (checked on every write) and the **object kind**: ✅ bits 55–58, where
  **function = `0x0080_0000_0000_0000`**.
- **For a function object, aux points at the actual function**, which is why the call check tests
  `aux == ptr` (✅📄). For other specials, aux says where the pointer is allowed to point.
- **For a data object, aux points at the AUX ARRAY** (📄): the same size as the payload, one 8-byte
  entry per payload word. **0 for an integer. The capability (its `lower`) for a pointer stored
  there. Or a `filc_atomic_box*` tagged with bit 0** for a pointer accessed atomically
  (`box = { lower, ptr }`, 16-byte aligned, 128-bit atomics). Aux is created **lazily, on the first
  pointer store, with one CAS**. Int-only objects never get one. The cc buffers (§3) use the same
  payload + aux pattern.
- **New memory is always zeroed** (payload and aux) (📄).
- **`free()`** moves upper down to lower, so size becomes 0 and the freed flag is set. Every alias
  sees it, because capabilities are shared objects, not copies (📄 `gimso_semantics.md`,
  `stdfil.h`). FUGC later **repoints capabilities of freed objects to a "free singleton"** so it
  need not mark them (📄 Manifesto).

📄 = from upstream's **design docs** (`invisicap.txt`, `gimso_semantics.md`, `Manifesto.md` at
`deluge` `14a3ce9`, read 2026-09-30). Docs, not runtime source. ⚠️ `invisicap.txt` calls itself a
"possible replacement" design. The header, aux and function-object facts match what 0.685 actually
emits (✅), but treat details it alone states as likely rather than certain.

### The checks, exactly (📄 `invisicap.txt`)

- **Int read:** misaligned (where required) → fail; `lower == 0` → fail; `ptr − lower >= size` → fail.
- **Int write:** the same, plus READONLY → fail.
- **Pointer read:** the int checks, then take the capability from `aux[ptr − lower]`. No aux array
  → **null capability**. Tagged → load atomically from the box.
- **Pointer write:** the int-write checks, create aux if missing, **run the GC store barrier on the
  object being stored**, write the lower into aux and the raw pointer into the payload.
- On x86, int/float alignment is not checked (the annotation is dropped); **pointer and vector
  alignment is** (📄 `gimso_semantics.md`).

### `inttoptr`: where capabilities are lost (📄 `gimso_semantics.md`) 🔑 for P4

An integer turned into a pointer gets a **null capability**, *unless* a simple abstract interpreter
proves, **within one function**, that it came from exactly one pointer via `ptrtoint` (through
arithmetic, `phi` and `select`). **Integers that come from a call or a load are always BOTTOM, so
they get a null capability.** A pointer that crosses a function boundary or passes through memory
*as an integer* is therefore dead. That explains KI-10 (a `pthread_t` held as an integer) and every
`@ptrFromInt` in std (KI-5).

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

## 5b. The GC protocol a runtime must implement (📄 `Manifesto.md`, FUGC)

FUGC is **parallel, concurrent, on-the-fly, grey-stack, Dijkstra, accurate, non-moving**. What that
demands from a runtime and from compiled code:

| piece | what it is |
| --- | --- |
| **pollchecks** | emitted by the pass often enough to bound progress between them. Fast path: load and branch. Slow path: run the **pollcheck callback** (GC work, such as scanning this thread's shadow stack, §3) |
| **soft handshakes** | the collector asks every thread to run the callback and waits. **No stop-the-world**, except for `fork(2)` and the `FUGC_STW=1` debug mode |
| **enter / exit** ✅ answers the open question | **a thread that blocks must EXIT first** (a system call or a long runtime function). While exited, the collector runs that thread's callbacks itself. **The only ways to block** are looping while entered (a pollcheck each iteration) or calling into the runtime and exiting |
| **store barrier** | Dijkstra: while marking, storing a pointer to an unmarked object marks it (a relaxed CAS on the slow path). **No load barrier**, because stacks are rescanned to a fixpoint |
| **black allocation** | objects allocated during a collection are pre-marked |
| **safe signal delivery** | signals are delivered at safepoints (see `zincrement_signal_deferral_depth` in `pizlonated_runtime.h`) |
| **safepoint guarantee** | a pointer loaded from the heap is safe to use until the next pollcheck or exit, so it only has to be visible to stack scanning by then |

⚠️ **KI-7 is a GC problem, not only a policy one:** a raw `futex` or `clock_nanosleep` blocks without
exiting, so every soft handshake would wait on that thread forever. Routing those calls through
libc's `syscall()` (which exits) is **required**, not a workaround.

## 6. What this changes in the P3 plan

- ❗ **The layers are less separable than the symbol counts suggested.** Even one `zsys_*`
  replacement must build a **function object** (header + kind + `{fast, generic, hash}`), speak the
  **generic calling convention** through the thread's cc buffers, and **read capabilities** to
  bounds-check its buffer argument. That means the object-header format, which is shared with
  the GC, comes **first**, not last.
- ✅ **Answered from the docs:** yes, a blocking system call must **exit** (§5b). Every `zsys_*`
  replacement that can block must exit before the call and enter after it. So step 0 also needs the
  **thread state machine** (entered/exited), **pollcheck callbacks** and **soft handshakes**. Even
  a "just write()" replacement needs part of the GC.
- ✅ **This spec was built entirely from observation plus the published design docs**: the pass's
  output, public headers, binaries, `invisicap.txt`, `gimso_semantics.md` and `Manifesto.md`. It is
  evidence that a **clean-room runtime is feasible** (open question #3). Still unspecified: the
  exact **flag-bit** values besides *function*, the **pollcheck word's location** in the thread
  (not in the IR we probed, which had no loops), and the **enter/exit entry points**. The next probe
  is a loop plus a blocking call, reading the pass's output as before.
