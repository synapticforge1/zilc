; Hand-written module in Fil-C's dialect: does the pass accept IR that did NOT
; come from Fil-C's own frontend, when the layout is exactly right?
target datalayout = "e-m:e-ni:0-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target datalayout_after_filc = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

define void @store_int(ptr %p, i64 %i, i32 %v) {
entry:
  %addr = getelementptr inbounds i32, ptr %p, i64 %i
  store i32 %v, ptr %addr, align 4
  ret void
}
