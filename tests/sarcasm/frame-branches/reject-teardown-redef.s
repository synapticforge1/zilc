# zilc's own input for tools/sarcasm/check-stages.ts (stage xframe): x86_64_frame's annotation
# pass, a pop inside a verified epilogue teardown at an UNKNOWN depth (two paths join at .L1 with
# different constant depths, so the depth merges to "dyn" while the save stack survives) whose
# paired save was REDEFINED after the push (upstream x86_64_frame.luau 3633-3637): the pop's reload
# is lost, so checkLostReload rejects the read of %rbx after the pop. No Fil-C test reaches it
# (measured 2026-11-24: 3 teardown pops at an unknown depth over the corpus, none of a redefined
# save).
	.text
	.globl	foo
	.type	foo, @function
foo:                            ;! long(long)
	endbr64
	pushq	%rbp
	pushq	%rbx
	movq	%rsp, %rbp
	subq	$16, %rsp
	testq	%rdi, %rdi
	je	.L1
	subq	$16, %rsp
.L1:
	movl	$7, %ebx
	addq	$16, %rsp
	popq	%rbx
	popq	%rbp
	movq	%rbx, %rax
	ret
	.size	foo, .-foo
	.section	.note.GNU-stack,"",@progbits
