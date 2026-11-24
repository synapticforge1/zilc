# zilc's own input for tools/sarcasm/check-stages.ts (stage xframe): the governing-`and` dataflow
# (upstream x86_64_frame.luau 3859-3926) joins two paths that arrive at .L2 with the SAME governing
# `and` (the Fil-C corpus merges only unequal ones: gandJoin's equal arm, 3860).
	.text
	.globl	andjoin
	.type	andjoin, @function
andjoin:                        ;! long(long)
	pushq	%rbx
	subq	$64, %rsp
	jmp	.Lb1
.Lb1:
	and	$-32, %rsp
	testq	%rdi, %rdi
	je	.L2
	movq	%rdi, %rax
.L2:
	movq	%rdi, %rax
	addq	$64, %rsp
	popq	%rbx
	ret
	.size	andjoin, .-andjoin
	.section	.note.GNU-stack,"",@progbits
