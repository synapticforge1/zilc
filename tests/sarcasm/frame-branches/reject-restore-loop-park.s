# zilc's own input for tools/sarcasm/check-stages.ts (stage xframe): the dropRestore crossing
# exemption is narrow (upstream x86_64_frame.luau 3959-3986): the carrier parks the entry rsp (depth
# 0), but its parking site is reached from the mid-function `and` around the loop, so the parked
# value may carry the and's slack and the restore `movq -8(%r12), %rbx` stays rejected.
	.text
	.globl	looppark
	.type	looppark, @function
looppark:                       ;! long(long)
.Ltop:
	movq	%rsp, %r12
	and	$-32, %rsp
	movq	%r12, %rsp
	testq	%rdi, %rdi
	jne	.Ltop
	pushq	%rbx
	movq	-8(%r12), %rbx
	popq	%rbx
	ret
	.size	looppark, .-looppark
	.section	.note.GNU-stack,"",@progbits
