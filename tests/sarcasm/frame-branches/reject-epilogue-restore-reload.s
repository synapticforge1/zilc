# zilc's own input for tools/sarcasm/check-stages.ts (stage xframe): x86_64_frame's epilogue
# movq-restore loads (upstream x86_64_frame.luau 4361-4422), the lost-reload rejection: the rsp
# slot of %rbx (pushed after the prologue) was REDEFINED after the push, the load `movq 0(%rsp),
# %rbx` cannot be modeled, so checkLostReload (4414-4420) rejects the first read of %rbx after it.
	.text
	.globl	foo
	.type	foo, @function
foo:                            ;! long(long)
	testq	%rdi, %rdi
	je	.L1
.L1:
	pushq	%rbx
	movl	$222, %ebx
	movq	0(%rsp), %rbx
	movq	%rbx, %rax
	popq	%rbx
	ret
	.size	foo, .-foo
	.section	.note.GNU-stack,"",@progbits
