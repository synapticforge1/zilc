# zilc's own input for tools/sarcasm/check-stages.ts (stage xframe): the same inner frame as
# sbranges-spill-slot.s with a callee-saved push: `pushq %rbx` is a real save, so the buffer
# [-56, -40) overlapping its slot is rejected (upstream x86_64_frame.luau 4826-4834).
	.text
	.globl	push_slot
	.type	push_slot, @function
push_slot:                     ;! long(size_t)
	call	helper ;! void()
	subq	$48, %rsp
	pushq	%rbx
	movl	(%rsp,%rdi), %eax #! stack buffer (x, %rsp, %rsp + 16)
	popq	%rbx
	addq	$48, %rsp
	ret
	.size	push_slot, .-push_slot
helper:                         ;! void()
	ret
	.section	.note.GNU-stack,"",@progbits
