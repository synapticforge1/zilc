# zilc's own input for tools/sarcasm/check-stages.ts (stage xframe): x86_64_frame's annotation
# pass, a dropped movq-restore load into %rax of a save whose register was REDEFINED after the push,
# in a function that returns an integer (upstream x86_64_frame.luau 3409-3414): rejected outright,
# because the frame analysis does not model `ret`'s read of %rax. No Fil-C test reaches it
# (measured 2026-11-24: 0 hits over the corpus).
	.text
	.globl	foo
	.type	foo, @function
foo:                            ;! long(long)
	pushq	%rax
	movq	%rsp, %r12
	movl	$222, %eax
	movq	0(%r12), %rax
	movq	%r12, %rsp
	popq	%rax
	ret
	.size	foo, .-foo
	.section	.note.GNU-stack,"",@progbits
