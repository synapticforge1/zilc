# zilc's own input for tools/sarcasm/check-stages.ts (stage xframe): the B2 clone coordinate bands
# (upstream x86_64_frame.luau 4424-4543), which the Fil-C corpus reaches only with ONE clone per
# function (clone index 1). bands_jump jumps to two shared tails, so its clones are indexed 1 and
# 2 and the second band's base is laid out after the first's (4502-4510): the first tail's
# accesses (8, 0, then 56 from rsp) move the extent's lo and hi, and the 56 matters to the
# second base; the second tail sits under an inner `subq $32` (depth 96 != D0 = 64: the 4486
# shift), its first access at the extent's top and its second at the bottom. bands_jump2 has an
# escaping frame address, so the frame is promoted to a region [0, 64) and the clone's accesses
# inside it are skipped (4480). bands_jump3's tail parks the stack pointer in %r11 inside the clone
# and accesses through it: the carrier access is banded like the rsp spellings (4472, 4526).
	.text
	.globl	bands_jump
	.type	bands_jump, @function
bands_jump:                     ;! long(long)
	subq	$64, %rsp
	testq	%rdi, %rdi
	jz	.Lbj_second
	jmp	.Lbands_a
.Lbj_second:
	jmp	.Lbands_b
	.size	bands_jump, .-bands_jump
	.globl	bands_a
	.type	bands_a, @function
bands_a:                        ;! long(long)
	subq	$64, %rsp
	nop
.Lbands_a:
	movq	%rdi, 8(%rsp)
	movq	%rdi, 0(%rsp)
	movq	56(%rsp), %rax
	addq	$64, %rsp
	ret
	.size	bands_a, .-bands_a
	.globl	bands_b
	.type	bands_b, @function
bands_b:                        ;! long(long)
	subq	$64, %rsp
	nop
.Lbands_b:
	subq	$32, %rsp
	movq	%rdi, 32(%rsp)
	movq	%rdi, (%rsp)
	movq	(%rsp), %rax
	addq	$32, %rsp
	addq	$64, %rsp
	ret
	.size	bands_b, .-bands_b
	.globl	bands_jump2
	.type	bands_jump2, @function
bands_jump2:                    ;! long(long)
	subq	$64, %rsp
	leaq	16(%rsp), %rdi
	call	bands_helper ;! long(ptr)
	jmp	.Lbands_a
	.size	bands_jump2, .-bands_jump2
	.globl	bands_jump3
	.type	bands_jump3, @function
bands_jump3:                    ;! long(long)
	subq	$64, %rsp
	jmp	.Lbands_c
	.size	bands_jump3, .-bands_jump3
	.globl	bands_c
	.type	bands_c, @function
bands_c:                        ;! long(long)
	subq	$64, %rsp
	nop
.Lbands_c:
	movq	%rsp, %r11
	movq	%rdi, 24(%r11)
	movq	24(%r11), %rax
	addq	$64, %rsp
	ret
	.size	bands_c, .-bands_c
	.section	.note.GNU-stack,"",@progbits
