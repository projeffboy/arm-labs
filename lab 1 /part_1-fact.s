.global _start

_start:
	mov r1, #6 // n
	bl fact
	b end

fact: // NOTE: input is r1, not r0
	cmp r1, #2
	bge else
		// Base case
		mov r0, #1
		bx lr
	
	else:
		// Recursive case
		push {r1, lr}
		sub r1, r1, #1
		bl fact

		// When popping a past copy LR from the stack, it starts here
		// (unless it's the last LR)
		pop {r1}
		mul r0, r0, r1
		pop {lr}
		bx lr
	
end: b end

// Very helpful: https://www.quora.com/How-do-I-create-a-recursion-in-ARM-architecture-assembly-language