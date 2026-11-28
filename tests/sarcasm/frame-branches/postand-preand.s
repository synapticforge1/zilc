# zilc's own input for tools/sarcasm/check-stages.ts (stage xframe): the post-`and` frame extent
# (upstream x86_64_frame.luau 4545-4591) skips x86_preAnd statements (4568). With a prologue `and`
# (frameAndSeen) AND a mid-function `and` after a label, the store at 256(%rsp) between them reaches
# the mid and (preAnd) at depth 72 = frameAndDepth, far above the 64-byte frame.
	.text
	.globl	pa_preand
	.type	pa_preand, @function
pa_preand:                      ;! long(long)
	pushq	%rbx
	subq	$64, %rsp
	andq	$-64, %rsp
	movq	%rdi, 256(%rsp)
	jmp	.Lpa_mid
.Lpa_mid:
	andq	$-32, %rsp
	movq	%rdi, %rax
	addq	$64, %rsp
	popq	%rbx
	ret
	.size	pa_preand, .-pa_preand
	.section	.note.GNU-stack,"",@progbits
