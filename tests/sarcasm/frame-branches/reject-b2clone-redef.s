# zilc's own input for tools/sarcasm/check-stages.ts (stage xframe): the direct-carrier hatch finds
# its recovery but no live carrier at the ret (upstream x86_64_frame.luau 4196-4210): the shared tail
# of b2clone-carrier-zero.s redefines the carrier register (`xorl %r11d, %r11d`) after the recovery,
# so the ret holds no carrier parked at the recovered save, and the clone is rejected as unbalanced.
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
	movq	%rdi, %rax
	leaq	8(%r11), %rsp
	xorl	%r11d, %r11d
	ret
	.size	b2_owner, .-b2_owner
	.section	.note.GNU-stack,"",@progbits
