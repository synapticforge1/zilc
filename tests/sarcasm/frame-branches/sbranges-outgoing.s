# zilc's own input for tools/sarcasm/check-stages.ts (stage xframe): a buffer must not overlap the
# outgoing call-argument area (upstream x86_64_frame.luau 4838-4842). The call passes 8 integer
# arguments, so the two stack words fill [0, 16); the buffer names [8, 24).
	.text
	.globl	og
	.type	og, @function
og:                             ;! long(long)
	pushq	%rbx
	subq	$64, %rsp
	movq	%rdi, %rbx
	movq	%rbx, (%rsp)
	movq	%rbx, 8(%rsp)
	movl	(%rsp,%rbx), %eax #! stack buffer (x, %rsp + 8, %rsp + 24)
	call	callee ;! long(long, long, long, long, long, long, long, long)
	addq	$64, %rsp
	popq	%rbx
	ret
	.size	og, .-og
	.section	.note.GNU-stack,"",@progbits
