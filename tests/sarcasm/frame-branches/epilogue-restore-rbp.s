# zilc's own input for tools/sarcasm/check-stages.ts (stage xframe): x86_64_frame's epilogue
# movq-restore loads (upstream x86_64_frame.luau 4361-4422), the rbp-based form: with an established
# frame pointer, `movq -8(%rbp), %rbx` reloads the save slot of %rbx (normalized offset
# rbpNorm + disp), which was REDEFINED after its push; no later read of %rbx, so the load is marked
# x86_dropRestore. The prologue here holds one callee-saved push below the frame pointer, so rbpNorm
# is not 0 (the rbp-relative slot shifts by it).
	.text
	.globl	foo
	.type	foo, @function
foo:                            ;! long(long)
	pushq	%rbp
	movq	%rsp, %rbp
	pushq	%rbx
	movl	$222, %ebx
	movq	-8(%rbp), %rbx
	movq	%rdi, %rax
	popq	%rbx
	popq	%rbp
	ret
	.size	foo, .-foo
	.section	.note.GNU-stack,"",@progbits
