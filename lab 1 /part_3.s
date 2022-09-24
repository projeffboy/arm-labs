.global _start

size: .word 5
array: .word -1, 23, 0, 12, -7

_start:
ldr r1, size
sub r1, r1, #1 // size - 1
ldr r2, =array
	
mov r3, #0 // step	
loop:
cmp r3, r1
bge end
mov r4, #0 // i
	inner_loop:
	sub r5, r1, r3 // (size - 1) - step
	cmp r4, r5
	bge inner_loop_done	
		add r6, r2, r4, LSL#2 // left ptr
		add r7, r6, #4 // right ptr
		ldr r8, [r6] // left ptr value
		ldr r9, [r7] // right ptr value
		cmp r8, r9
		ble if_done // (bge for desc order)
			str r8, [r7]
			str r9, [r6]
		if_done:
		add r4, r4, #1
		b inner_loop
	inner_loop_done:
	add r3, r3, #1
	b loop
	
end: b end