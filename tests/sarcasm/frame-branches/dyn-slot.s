# zilc's own input for tools/sarcasm/check-stages.ts (stage xframe): a saved-rsp carrier stored
# into a stack slot while the depth is unknown ("dyn"), which keys the slot carrier in "D"-space,
# and clearDynSlots, which drops such carriers at any rsp write (upstream x86_64_frame.luau
# 1572–1580, 2175–2185). No Fil-C test reaches it (measured 2026-11-07: a fault there changes
# nothing over the 1,431 corpus files). `dynslot` pushes after the store (the carrier is cleared);
# `dynkeep` does not (it survives to the recovery).
	.text
	.globl	dynslot
	.type	dynslot, @function
dynslot:                        ;! long(long)
	pushq	%rbx
	movq	%rsp, %rbx
	subq	%rdi, %rsp
	movq	%rbx, 8(%rsp)
	pushq	%rcx
	popq	%rcx
	movq	%rbx, %rsp
	popq	%rbx
	ret
	.size	dynslot, .-dynslot

	.globl	dynkeep
	.type	dynkeep, @function
dynkeep:                        ;! long(long)
	pushq	%rbx
	movq	%rsp, %rbx
	subq	%rdi, %rsp
	movq	%rbx, 8(%rsp)
	movq	%rbx, %rsp
	popq	%rbx
	ret
	.size	dynkeep, .-dynkeep
	.section	.note.GNU-stack,"",@progbits
