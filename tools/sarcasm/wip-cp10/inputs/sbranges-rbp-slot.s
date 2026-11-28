# zilc's own input for tools/sarcasm/check-stages.ts (stage xframe): with an established frame
# pointer (usesRbp) a pushed %rbp is the saved frame pointer and is skipped by the save-slot check
# (upstream x86_64_frame.luau 4823). The second `pushq %rbp` sits in a mid-function inner frame (the
# call ends the prologue scan), so the push-pad rule does not see its slot; the buffer
# [-64, -48) over it is accepted.
	.text
	.globl	rbp_slot
	.type	rbp_slot, @function
rbp_slot:                       ;! long(size_t)
	pushq	%rbp
	movq	%rsp, %rbp
	call	helper ;! void()
	subq	$48, %rsp
	pushq	%rbp
	movl	(%rsp,%rdi), %eax #! stack buffer (x, %rsp, %rsp + 16)
	popq	%rbp
	addq	$48, %rsp
	popq	%rbp
	ret
	.size	rbp_slot, .-rbp_slot
helper:                         ;! void()
	ret
	.section	.note.GNU-stack,"",@progbits
