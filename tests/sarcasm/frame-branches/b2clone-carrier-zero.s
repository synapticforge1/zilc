# zilc's own input for tools/sarcasm/check-stages.ts (stage xframe): the clone subframe balance
# check's direct-carrier hatch (upstream x86_64_frame.luau 4143-4210, used at 4331). The poly1305
# avx512 -> avx2 shape: both bodies park the entry rsp once (`leaq -8(%rsp), %r11`) and the shared
# tail recovers it directly (`leaq 8(%r11), %rsp`) with no pushes or pops. In the jumper's clone the
# ret sits at depth 0 while its clone entry sits at the jump-site depth (64), so only the hatch
# accepts it. The second pair recovers through a `movq %r11, %rsp` of a carrier parked by
# `movq %rsp, %r11` (the other recovery form, 4184-4192).
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
	ret
	.size	b2_owner, .-b2_owner
	.globl	b2_jump2
	.type	b2_jump2, @function
b2_jump2:                       ;! long(long)
	movq	%rsp, %r11
	subq	$64, %rsp
	testq	%rdi, %rdi
	jz	.Lskip_jump2
	jmp	.Lshared2
.Lskip_jump2:
	xorl	%eax, %eax
	addq	$64, %rsp
	ret
	.size	b2_jump2, .-b2_jump2
	.globl	b2_owner2
	.type	b2_owner2, @function
b2_owner2:                      ;! long(long)
	movq	%rsp, %r11
	subq	$64, %rsp
	nop
.Lshared2:
	movq	%rdi, %rax
	movq	%r11, %rsp
	ret
	.size	b2_owner2, .-b2_owner2
	.section	.note.GNU-stack,"",@progbits
