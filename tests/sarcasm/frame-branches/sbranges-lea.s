# zilc's own input for tools/sarcasm/check-stages.ts (stage xframe): a `stack buffer` annotation on
# a lea is rejected (upstream x86_64_frame.luau 4924-4928): a lea takes no memory access. Only the
# suffix-less spelling reaches the check (the test is `mnemonic == "lea"`: a `leaq` is accepted).
	.text
	.globl	lea_ann
	.type	lea_ann, @function
lea_ann:                        ;! long(long)
	subq	$64, %rsp
	movq	$0, (%rsp)
	lea	8(%rsp), %rax #! stack buffer (x, %rsp, %rsp + 16)
	movq	(%rax), %rax
	addq	$64, %rsp
	ret
	.size	lea_ann, .-lea_ann
	.section	.note.GNU-stack,"",@progbits
