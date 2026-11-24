# zilc's own input for tools/sarcasm/check-stages.ts (stage xframe): the B2-clone buffer probe of
# an sp-based lea (upstream x86_64_frame.luau 1957-1975 in the fixpoint, 3486-3500 in the
# annotation pass). Fil-C's b2clone.s with `leaq 0(%rsp), %rdx` added to the shared tail, read as
# memory and used as a value (the toggle idiom): in each jumper's clone its raw displacement 0 is
# tested against the clone's own declared raw range [0, 64).
	.text
	.globl	fnA
	.type	fnA, @function
fnA:                            ;! long(size_t)
	jmp	.LfnB_body
	.size	fnA, .-fnA

	.globl	fnA2
	.type	fnA2, @function
fnA2:                           ;! long(size_t)
	testq	%rdi, %rdi
	jz	.La2_zero
	jmp	.LfnB_body
.La2_zero:
	xorl	%eax, %eax
	ret
	.size	fnA2, .-fnA2

	.globl	fnB
	.type	fnB, @function
fnB:                            ;! long(size_t)
.LfnB_entry:
.LfnB_body:
	subq	$64, %rsp
	movl	$0x11111111, 0(%rsp)
	movl	$0x22222222, 4(%rsp)
	movl	$0x33333333, 8(%rsp)
	movl	$0x55555555, 60(%rsp)
.LfnB_tail:
	leaq	0(%rsp), %rdx
	movl	(%rsp,%rdi), %eax #! stack buffer (ks, %rsp, %rsp + 64)
	movl	4(%rdx), %ecx
	addl	%ecx, %eax
	addq	%rdx, %rax
	addq	$64, %rsp
	ret
	.size	fnB, .-fnB
	.section	.note.GNU-stack,"",@progbits
