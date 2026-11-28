# zilc's own input for tools/sarcasm/check-stages.ts (stage xframe): the lea rejection tests the
# mnemonic `lea` exactly (upstream x86_64_frame.luau 4924); an annotated `leaq` is accepted and
# its declaration recorded.
	.text
	.globl	leaq_ann
	.type	leaq_ann, @function
leaq_ann:                       ;! long(long)
	subq	$64, %rsp
	movq	$0, (%rsp)
	leaq	8(%rsp), %rax #! stack buffer (x, %rsp, %rsp + 16)
	movq	(%rax), %rax
	addq	$64, %rsp
	ret
	.size	leaq_ann, .-leaq_ann
	.section	.note.GNU-stack,"",@progbits
