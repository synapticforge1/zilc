# zilc's own input for tools/sarcasm/check-stages.ts (stage xframe): x86_64_frame's smap merge
# of two LIVE carriers that agree on depth but were parked by DIFFERENT statements (the saveIdx
# merge, upstream x86_64_frame.luau 2659–2672). No Fil-C test reaches that branch (measured
# 2026-11-07: 0 hits over the 1,431 corpus files). Two paths park %rsp into %rbx at the same
# depth, then join. The merge KEEPS the entry already at the join when its saveIdx is the smaller
# (mergeA, mergeB) and REWRITES it to the smaller when not (mergeC: the depth fixpoint's worklist
# takes a fall-through first, so the fall-through save — placed AFTER the branch target's, behind
# a backward jump — reaches the join first with the larger index).
	.text
	.globl	mergeA
	.type	mergeA, @function
mergeA:                         ;! long(int)
	pushq	%rbx
	testl	%edi, %edi
	je	.LaA
	movq	%rsp, %rbx
	jmp	.LjA
.LaA:
	movq	%rsp, %rbx
.LjA:
	movq	%rbx, %rsp
	popq	%rbx
	ret
	.size	mergeA, .-mergeA

	.globl	mergeB
	.type	mergeB, @function
mergeB:                         ;! long(int)
	pushq	%rbx
	testl	%edi, %edi
	je	.LaB
	movq	%rsp, %rbx
.LjB:
	movq	%rbx, %rsp
	popq	%rbx
	ret
.LaB:
	movq	%rsp, %rbx
	jmp	.LjB
	.size	mergeB, .-mergeB

	.globl	mergeC
	.type	mergeC, @function
mergeC:                         ;! long(int)
	pushq	%rbx
	jmp	.LsC
.LaC:
	movq	%rsp, %rbx
	jmp	.LjC
.LsC:
	testl	%edi, %edi
	je	.LaC
	movq	%rsp, %rbx
.LjC:
	movq	%rbx, %rsp
	popq	%rbx
	ret
	.size	mergeC, .-mergeC
	.section	.note.GNU-stack,"",@progbits
