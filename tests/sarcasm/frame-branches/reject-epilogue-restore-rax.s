# zilc's own input for tools/sarcasm/check-stages.ts (stage xframe): x86_64_frame's epilogue
# movq-restore loads (upstream x86_64_frame.luau 4361-4422), the rsp-based form into the integer
# return register: `movq 0(%rsp), %rax` reloads the save slot of %rax (pushed after the prologue,
# so not a spill slot) which was REDEFINED after its push, in a function returning an integer:
# rejected outright (4409-4413), because the frame analysis does not model `ret`'s read of %rax.
	.text
	.globl	foo
	.type	foo, @function
foo:                            ;! long(long)
	testq	%rdi, %rdi
	je	.L1
.L1:
	pushq	%rax
	movl	$222, %eax
	movq	0(%rsp), %rax
	popq	%rax
	ret
	.size	foo, .-foo
	.section	.note.GNU-stack,"",@progbits
