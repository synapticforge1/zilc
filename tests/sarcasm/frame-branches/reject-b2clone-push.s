# zilc's own input for tools/sarcasm/check-stages.ts (stage xframe): a push inside the clone
# stops the direct-carrier hatch (upstream x86_64_frame.luau 4172-4176): the shared tail of
# b2clone-carrier-zero.s with a push / pop pair before the carrier recovery. The clone returns
# at depth 0 with its entry at the jump-site depth, so the balance check rejects it.
	.text
	.globl	b2_jump
	.type	b2_jump, @function
b2_jump:                        ;! long(long)
	leaq	-8(%rsp), %r11
	subq	$64, %rsp
	testq	%rdi, %rdi
	jz	.Lskip_jump
	jmp	.Lshared
.Lskip_jump:
	xorl	%eax, %eax
	addq	$64, %rsp
	ret
	.size	b2_jump, .-b2_jump
	.globl	b2_owner
	.type	b2_owner, @function
b2_owner:                       ;! long(long)
	leaq	-8(%rsp), %r11
	subq	$64, %rsp
	nop
.Lshared:
	pushq	%rbx
	popq	%rbx
	movq	%rdi, %rax
	leaq	8(%r11), %rsp
	ret
	.size	b2_owner, .-b2_owner
	.section	.note.GNU-stack,"",@progbits
