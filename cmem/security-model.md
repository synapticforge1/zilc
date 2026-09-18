# Security Model

## What zilc is meant to guarantee (target, inherited from Fil-C)

| Property | Mechanism | Bug class stopped |
| --- | --- | --- |
| **Spatial safety** | Every pointer carries an InvisiCap (bounds + type info). Every access is checked | Buffer overflow/underflow, OOB read/write |
| **Temporal safety** | `free()` marks objects freed, and FUGC reclaims only unreachable memory. Escaping stack allocas move to the GC heap | Use-after-free, double free, stack-use-after-return |
| **Type confusion on pointers** | Capabilities distinguish pointer slots from data. Integers cannot be forged into usable pointers | Pointer forging, `int → ptr` smuggling |
| **Race safety of the above** | Pointer + capability updated atomically | Pointer tearing under data races |

**A violation is a deterministic panic**, never silent corruption. Fil-C's precise formulation is
"GIMSO" (see upstream `gimso_semantics.md`). Quote that, not the "100% exploit-proof" summary.

## Explicitly NOT guaranteed (to be confirmed as P1 reads the docs)

- Logic bugs, integer overflow that stays in bounds, and data races on *non-pointer* data.
- Code outside the safe target: uninstrumented libraries, inline assembly, the runtime itself (the
  trusted computing base).
- Denial of service (panics *are* the safety mechanism), and memory exhaustion from GC retention.

## The trusted computing base

The pass, `zilc_runtime`, the "yolo" (trusted) libc layer, and the Zig/LLVM compiler itself. Keeping
the TCB small and written in Zig (with Zig's own safety checks enabled in the runtime's build mode)
is a motivating reason for the Zig runtime.

## Open

- **The FFI boundary** (Zig ⇄ C ⇄ uninstrumented code) is the vision's headline feature and the
  least-defined part of the model. See `architecture.md`.
