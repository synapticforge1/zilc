# zilc's own input for tools/sarcasm/check-stages.ts (stage xframe): the post-`and` frame extent
# (upstream x86_64_frame.luau 4545-4591) with a DEPTH-0 note, the `mov %rsp,%r11; and $-32,%rsp`
# prologue shape (frameAndSeen true, frameAndDepth 0, no sub): the gate is frameAndSeen (4565), not
# `frameAndDepth ~= 0`, so the post-and store at 0(%rsp) still grows the frame from 0 to 8.
	.text
	.globl	pa_depth0
	.type	pa_depth0, @function
pa_depth0:                      ;! long(long)
	movq	%rsp, %r11
	andq	$-32, %rsp
	movq	%rdi, 0(%rsp)
	movq	0(%rsp), %rax
	movq	%r11, %rsp
	ret
	.size	pa_depth0, .-pa_depth0
	.section	.note.GNU-stack,"",@progbits
