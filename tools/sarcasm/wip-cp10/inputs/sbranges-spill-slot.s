# zilc's own input for tools/sarcasm/check-stages.ts (stage xframe): the declaring statement's own
# outstanding saves (upstream x86_64_frame.luau 4812-4836) skip a SPILL slot: `pushq %rcx` (a
# caller-saved register) is a spill, an ordinary slot, so the buffer [-56, -40) over it is
# accepted. The call ends the prologue scan, so the push + sub below are a mid-function inner frame
# (negative normalized offsets) and the push-pad rule does not see the slot.
	.text
	.globl	spill_slot
	.type	spill_slot, @function
spill_slot:                     ;! long(size_t)
	call	helper ;! void()
	subq	$48, %rsp
	pushq	%rcx
	movl	(%rsp,%rdi), %eax #! stack buffer (x, %rsp, %rsp + 16)
	popq	%rcx
	addq	$48, %rsp
	ret
	.size	spill_slot, .-spill_slot
helper:                         ;! void()
	ret
	.section	.note.GNU-stack,"",@progbits
