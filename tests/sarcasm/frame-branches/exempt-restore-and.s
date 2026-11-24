# zilc's own input for tools/sarcasm/check-stages.ts (stage xframe): x86_64_frame's pre/post-`and`
# walks, the dropRestore crossing exemption (upstream x86_64_frame.luau 3959-3986). The restore
# `movq -8(%r12), %rbx` reloads the pushed %rbx through %r12, which parked the ENTRY rsp (depth 0)
# before any mid-function `and`: its parking site is reached from no and, and the carrier depth
# minus the displacement names the %rbx save, so the access after the and is legal (no rejection).
	.text
	.globl	exempt
	.type	exempt, @function
exempt:                         ;! long(long)
	movq	%rsp, %r12
	pushq	%rbx
	subq	$64, %rsp
	jmp	.Lb1
.Lb1:
	and	$-32, %rsp
	movq	%rdi, %rax
	movq	-8(%r12), %rbx
	movq	%r12, %rsp
	ret
	.size	exempt, .-exempt
	.section	.note.GNU-stack,"",@progbits
