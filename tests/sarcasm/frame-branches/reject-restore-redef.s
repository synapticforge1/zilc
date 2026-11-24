# zilc's own input for tools/sarcasm/check-stages.ts (stage xframe): x86_64_frame's annotation
# pass, a dropped movq-restore load of a save whose register was REDEFINED after the push (upstream
# x86_64_frame.luau 3406-3421): the load cannot be modeled, so checkLostReload walks on from it and
# rejects the first read of the register (here `movq %rbx, %rax`). No Fil-C test reaches the
# rejection (measured 2026-11-24: 18 redefined restore loads over the corpus, none rejected).
# %r12 parks the stack pointer (a live carrier); the save stack holds %rbx at the carrier's depth.
	.text
	.globl	foo
	.type	foo, @function
foo:                            ;! long(long)
	pushq	%rbx
	movq	%rsp, %r12
	movl	$222, %ebx
	movq	0(%r12), %rbx
	movq	%rbx, %rax
	movq	%r12, %rsp
	popq	%rbx
	ret
	.size	foo, .-foo
	.section	.note.GNU-stack,"",@progbits
