# zilc's own input for tools/sarcasm/check-stages.ts (stage xframe): the stack-buffer scan's set-up
# (upstream x86_64_frame.luau 4647-4658) keeps the LARGEST outgoing stack-argument area. out_two
# calls a 9-integer-argument function (3 stack words, 24 bytes) and then a 7-integer one (8 bytes):
# a last-wins or minimum update differs. out_fp calls a function of 7 integers and 2 doubles: the
# floating-point words travel in registers, so only 1 stack word (8 bytes) counts.
	.text
	.globl	out_two
	.type	out_two, @function
out_two:                        ;! long(long)
	pushq	%rbx
	subq	$48, %rsp
	movq	%rdi, %rbx
	movq	%rbx, (%rsp)
	movq	%rbx, 8(%rsp)
	movq	%rbx, 16(%rsp)
	call	out_nine ;! long(long, long, long, long, long, long, long, long, long)
	movq	%rbx, (%rsp)
	call	out_seven ;! long(long, long, long, long, long, long, long)
	addq	$48, %rsp
	popq	%rbx
	ret
	.size	out_two, .-out_two
	.globl	out_fp
	.type	out_fp, @function
out_fp:                         ;! long(long)
	pushq	%rbx
	subq	$32, %rsp
	movq	%rdi, %rbx
	movq	%rbx, (%rsp)
	call	out_mixed ;! long(long, long, long, long, long, long, long, double, double)
	addq	$32, %rsp
	popq	%rbx
	ret
	.size	out_fp, .-out_fp
