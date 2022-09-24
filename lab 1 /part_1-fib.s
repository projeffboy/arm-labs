.global _start

_start:
	mov r0, #7 // n Outputs: 1, 1, 2, 3, 5, 8, 13, ...
	bl fib
	b end

fib:
	push {r1, r2, lr}
	
	cmp r0, #3
	bge else
		// Base Case
		mov r0, #1
		pop {r1, r2, lr}
		bx lr

	else:
		mov r1, r0 // k, 3 <= k <= n
		sub r0, r1, #1 // k - 1
		bl fib // fib(k - 1)

		mov r2, r0 // stores fib(k - 1)
		sub r0, r1, #2 // k - 2
		bl fib // fib(k - 2)

		add r0, r2, r0 // fib(k - 1) + fib(k - 2)
		pop {r1, r2, lr}
		bx lr
	
end: b end

// Very helpful: https://www.cl.cam.ac.uk/teaching/2002/CompDesig/lecture4.pdf