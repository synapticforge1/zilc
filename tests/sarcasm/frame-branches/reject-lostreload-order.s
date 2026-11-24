# zilc's own input for tools/sarcasm/check-stages.ts (stage xframe): checkLostReload's worklist
# order (upstream x86_64_frame.luau 3265-3295). After the pad pop of a redefined %rbx the flow
# splits; BOTH arms read %rbx, and the walk pops its worklist from the END, so the rejection names
# the fall-through arm's read (the successor order is [target, fall-through]). The Fil-C corpus has
# one reading successor per rejection (measured 2026-11-24: reversing the order changes nothing).
	.text
	.globl	foo
	.type	foo, @function
foo:                            ;! long(long)
	endbr64
	subq	$64, %rsp
	movl	$111, %ebx
	pushq	%rbx
	movl	$222, %ebx
	popq	%rbx
	testq	%rdi, %rdi
	je	.Larm
	movq	%rbx, %rax
	addq	$64, %rsp
	ret
.Larm:
	leaq	1(%rbx), %rax
	addq	$64, %rsp
	ret
	.size	foo, .-foo
	.section	.note.GNU-stack,"",@progbits
