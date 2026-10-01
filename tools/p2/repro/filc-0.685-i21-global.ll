; Fil-C 0.685: FilPizlonator.cpp:16714 Assertion `!(CSize % WordSize)' failed.
; cmem/known-issues.md KI-18. Any global whose value type is i17..i24 (a 3-byte
; store size) triggers it; i2, i9..i16, i25..i120 do not, nor { i21 }, [2 x i21],
; or i21 in locals, loads and stores. Reduced from Zig 0.15.2's
; `@unicode.replacement_character = internal unnamed_addr constant i21 65533`.
;
;   filc/build/bin/clang -c -o /dev/null filc-0.685-i21-global.ll   # abort, exit 134
target datalayout = "e-m:e-ni:0-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target datalayout_after_filc = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux5.10.0-musl"

@g = internal unnamed_addr constant i21 65533, align 4

define ptr @use() {
  ret ptr @g
}
