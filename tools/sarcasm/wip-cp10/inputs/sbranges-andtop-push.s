# zilc's own input for tools/sarcasm/check-stages.ts (stage xframe): the `and` exemption of the
# frame-top rule needs an EMPTY push pad (upstream x86_64_frame.luau 4768: `frameAndSeen and
# maxSaves == 0`). Here a pushed register keeps the pad, so the buffer [0, 128) crossing the pad's
# top (64) is rejected although the post-and store at 256(%rsp) grows the frame extent to 264.
	.text
	.globl	and_top_push
	.type	and_top_push, @function
and_top_push:                   ;! long(long, long)
	pushq	%rbx
	subq	$64, %rsp
	andq	$-64, %rsp
	movq	%rdi, 256(%rsp)
	movl	(%rsp,%rsi), %eax #! stack buffer (t, %rsp, %rsp + 128)
	addq	$64, %rsp
	popq	%rbx
	ret
	.size	and_top_push, .-and_top_push
	.section	.note.GNU-stack,"",@progbits
