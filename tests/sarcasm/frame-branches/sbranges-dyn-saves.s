# zilc's own input for tools/sarcasm/check-stages.ts (stage xframe): a buffer declared at a
# statement whose outstanding-save state cannot be proven is rejected (upstream x86_64_frame.luau
# 4814-4822). The join after the conditional `pushq %rbx` has paths with and without the push, so
# the save stack is "dyn" there; the frame pointer is established, so the %rbp-based declaration
# still resolves (a %rsp-based one would die earlier, at the unprovable depth).
	.text
	.globl	dyn_saves
	.type	dyn_saves, @function
dyn_saves:                      ;! long(long)
	pushq	%rbp
	movq	%rsp, %rbp
	subq	$64, %rsp
	testq	%rdi, %rdi
	jz	.Lskip
	pushq	%rbx
.Lskip:
	movl	(%rbp,%rdi), %eax #! stack buffer (x, %rbp - 64, %rbp - 48)
	movq	%rbp, %rsp
	popq	%rbp
	ret
	.size	dyn_saves, .-dyn_saves
	.section	.note.GNU-stack,"",@progbits
