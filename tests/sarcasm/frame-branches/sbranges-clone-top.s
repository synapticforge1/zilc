# zilc's own input for tools/sarcasm/check-stages.ts (stage xframe): a buffer declared inside a local
# subroutine clone must live in the clone's own sub-frame (upstream x86_64_frame.luau 4786-4797,
# checkRangeFits): `sub $160` allocates 160 bytes below the phantom return-address word, but the
# declaration names [0, 192), whose top lies 32 bytes above the clone's own frame.
	.text
	.globl	lc_top
	.type	lc_top, @function
lc_top:                         ;! long(long)
	pushq	%rbx
	subq	$32, %rsp
	movl	%edi, %r10d
	call	m1x1
	movq	%r9, %rax
	addq	$32, %rsp
	popq	%rbx
	ret
	.size	lc_top, .-lc_top
m1x1:
	subq	$160, %rsp
	movl	$0, (%rsp)
	movl	(%rsp,%r10,4), %r9d #! stack buffer (tab, %rsp, %rsp + 192)
	addq	$160, %rsp
	ret
	.section	.note.GNU-stack,"",@progbits
