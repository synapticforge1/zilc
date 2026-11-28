# zilc's own input for tools/sarcasm/check-stages.ts (stage xframe): the post-`and` frame extent
# (upstream x86_64_frame.luau 4545-4591) skips B2 clone statements (4568: clone traffic rides its own
# bands). The jumper has a prologue `and`; the shared tail it jumps to is cloned into it, and the
# clone's store at 256(%rsp) sits at depth 72 = frameAndDepth, above the 64-byte frame.
	.text
	.globl	pa_b2jump
	.type	pa_b2jump, @function
pa_b2jump:                      ;! long(long)
	pushq	%rbx
	subq	$64, %rsp
	andq	$-64, %rsp
	jmp	.Lpa_b2tail
	.size	pa_b2jump, .-pa_b2jump
	.globl	pa_b2tail
	.type	pa_b2tail, @function
pa_b2tail:                      ;! long(long)
	pushq	%rbx
	subq	$64, %rsp
	nop
.Lpa_b2tail:
	movq	%rdi, 256(%rsp)
	movq	256(%rsp), %rax
	addq	$64, %rsp
	popq	%rbx
	ret
	.size	pa_b2tail, .-pa_b2tail
	.section	.note.GNU-stack,"",@progbits
