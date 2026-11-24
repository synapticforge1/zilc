# zilc's own input for tools/sarcasm/check-stages.ts (stage xframe): the direct-carrier hatch
# finds no carrier recovery in the clone (upstream x86_64_frame.luau 4160-4162). The shared tail
# tears its frame down with a constant `addq`, but frame-touching traffic between the `addq` and
# the `ret` (the shape of Fil-C's sarcasm-reject-b2-epi-traffic-att, here without pushes) breaks
# the verified teardown span, so the clone returns at depth 0 with no span and no carrier:
# rejected as unbalanced.
	.text
	.globl	b2_jump
	.type	b2_jump, @function
b2_jump:                        ;! long(long)
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
	subq	$64, %rsp
	nop
.Lshared:
	movq	%rdi, %rax
	addq	$64, %rsp
	movq	$0, 0(%rsp)
	ret
	.size	b2_owner, .-b2_owner
	.section	.note.GNU-stack,"",@progbits
