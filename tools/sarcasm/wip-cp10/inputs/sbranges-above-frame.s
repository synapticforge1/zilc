# zilc's own input for tools/sarcasm/check-stages.ts (stage xframe): the push-pad / frame-top rule
# applies only to a buffer that starts BELOW the frame base (upstream x86_64_frame.luau 4754: `homeLo
# < D0`). This buffer starts exactly at D0, on the return-address word and the caller's stack
# arguments above it, and is accepted; a `<=` would hit the frame-top rejection.
	.text
	.globl	above_frame
	.type	above_frame, @function
above_frame:                    ;! long(size_t)
	subq	$64, %rsp
	movq	%rdi, (%rsp)
	movl	(%rsp,%rdi), %eax #! stack buffer (x, %rsp + 64, %rsp + 80)
	addq	$64, %rsp
	ret
	.size	above_frame, .-above_frame
	.section	.note.GNU-stack,"",@progbits
