# zilc's own input for tools/sarcasm/check-stages.ts (stage xframe): the post-`and` frame extent
# (upstream x86_64_frame.luau 4545-4591) skips local-call clone statements (4568). The caller has a
# prologue `and`; the clone's store at 256(%rsp) (the +8 rule keys it to the caller's 248) is
# above the 64-byte frame.
	.text
	.globl	pa_local
	.type	pa_local, @function
pa_local:                       ;! long(long)
	pushq	%rbx
	subq	$64, %rsp
	andq	$-64, %rsp
	movq	$5, 0(%rsp)
	call	pa_sub
	movq	0(%rsp), %rax
	addq	$64, %rsp
	popq	%rbx
	ret
	.size	pa_local, .-pa_local
	.type	pa_sub, @function
pa_sub:
	movq	$77, 256(%rsp)
	ret
	.size	pa_sub, .-pa_sub
	.section	.note.GNU-stack,"",@progbits
