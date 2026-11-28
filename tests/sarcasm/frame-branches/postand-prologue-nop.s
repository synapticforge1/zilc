# zilc's own input for tools/sarcasm/check-stages.ts (stage xframe): the post-`and` frame extent
# (upstream x86_64_frame.luau 4545-4591) skips x86_prologue statements (4567). A `nopl 256(%rsp)`
# between the sub and the prologue `and` is transparent to the prologue scan (the nop arm sits before
# the frame-touch arm) yet carries a plain rsp memory operand at depth 72 = frameAndDepth, 256 bytes
# above a 64-byte frame: only the prologue skip keeps it from growing the frame.
	.text
	.globl	pa_prologue
	.type	pa_prologue, @function
pa_prologue:                    ;! long(long)
	pushq	%rbx
	subq	$64, %rsp
	nopl	256(%rsp)
	andq	$-64, %rsp
	movq	%rdi, 0(%rsp)
	movq	0(%rsp), %rax
	addq	$64, %rsp
	popq	%rbx
	ret
	.size	pa_prologue, .-pa_prologue
	.section	.note.GNU-stack,"",@progbits
