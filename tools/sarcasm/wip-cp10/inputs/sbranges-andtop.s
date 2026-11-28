# zilc's own input for tools/sarcasm/check-stages.ts (stage xframe): the frame-top rule's `and`
# exemption (upstream x86_64_frame.luau 4754-4784). The prologue is `mov %rsp,%r11; and $-32,%rsp;
# sub $256,%rsp` (an and note, no pushed registers), and the store at 256(%rsp) grows the frame
# extent to 264. The buffer [192, 264) reaches past the pad's top (256) exactly to the extent:
# accepted. (andtop_push: the same with a pushed register: the pad is not empty, no exemption:
# rejected; they are separate files so each is judged on its own.)
	.text
	.globl	and_top
	.type	and_top, @function
and_top:                        ;! long(long, long)
	movq	%rsp, %r11
	andq	$-32, %rsp
	subq	$256, %rsp
	movq	%rdi, 256(%rsp)
	movl	(%rsp,%rsi), %eax #! stack buffer (t, %rsp + 192, %rsp + 264)
	movq	%r11, %rsp
	ret
	.size	and_top, .-and_top
	.section	.note.GNU-stack,"",@progbits
