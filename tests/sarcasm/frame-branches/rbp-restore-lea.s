# zilc's own input for tools/sarcasm/check-stages.ts (stage xframe): x86_64_frame's annotation
# pass, the rbp-derived restore-base lea (`leaq K(%rbp), %reg` with an established frame pointer,
# K above the frame; upstream x86_64_frame.luau 3564-3575): marked x86_leaSave for the rewrite's
# drop. No Fil-C test reaches it (measured 2026-11-24: 0 hits over the corpus).
	.text
	.globl	foo
	.type	foo, @function
foo:                            ;! long(long)
	pushq	%rbp
	movq	%rsp, %rbp
	subq	$32, %rsp
	leaq	8(%rbp), %rcx
	movq	%rdi, %rax
	addq	$32, %rsp
	popq	%rbp
	ret
	.size	foo, .-foo
	.section	.note.GNU-stack,"",@progbits
