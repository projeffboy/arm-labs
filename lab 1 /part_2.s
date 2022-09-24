.global _start

fx: .word 183, 207, 128, 30, 109, 0, 14, 52, 15, 210
	.word 228, 76, 48, 82, 179, 194, 22, 168, 58, 116
	.word 228, 217, 180, 181, 243, 65, 24, 127, 216, 118
	.word 64, 210, 138, 104, 80, 137, 212, 196, 150, 139
	.word 155, 154, 36, 254, 218, 65, 3, 11, 91, 95
	.word 219, 10, 45, 193, 204, 196, 25, 177, 188, 170
	.word 189, 241, 102, 237, 251, 223, 10, 24, 171, 71
	.word 0, 4, 81, 158, 59, 232, 155, 217, 181, 19
	.word 25, 12, 80, 244, 227, 101, 250, 103, 68, 46
	.word 136, 152, 144, 2, 97, 250, 47, 58, 214, 51

kx:
	.word 1,   1,  0,  -1,  -1
	.word 0,   1,  0,  -1,   0
	.word 0,   0,  1,   0,   0
	.word 0,  -1,  0,   1,   0
	.word -1, -1,  0,   1,   1

gx: .space 400 // 4 * 10 * 10

iwh: .word 10 // img width/height
kwh: .word 5 // kernel width/height

_start:
	ldr r11, =kx // &kx
	ldr r12, =fx // &fx

	ldr r1, iwh
	ldr r2, kwh
	// r3 used to be represented by kernel width/height stride
	// but using r2, lsr#1 saves a register
	
	mov r4, #0 // y
	ih_loop:
	cmp r4, r1
	bge end
	mov r5, #0 // x
		iw_loop:
		cmp r5, r1
		bge iw_loop_done
			mov r10, #0 // sum
			
			mov r6, #0 // i
			kw_loop:
			cmp r6, r2
			bge kw_loop_done
				mov r7, #0 // j
				kh_loop:
				cmp r7, r2
				bge kh_loop_done
					add r8, r5, r7
					sub r8, r8, r2, lsr#1 // temp1
					add r9, r4, r6
					sub r9, r9, r2, lsr#1 // temp2
					cmp r8, #0
					blt if_done
					cmp r8, #9
					bgt if_done
					cmp r9, #0
					blt if_done
					cmp r9, #9
					bgt if_done
					// Kernel cell
					mla r0, r7, r2, r6 // j * kwh + i
					lsl r0, #2
					add r0, r0, r11 // add kx -> &kx[j][i]
					ldr r0, [r0] // kx[j][i]
					// Image cell
					mla r3, r8, r1, r9 // temp1 * iwh + temp2
					lsl r3, #2
					add r3, r3, r12 // add fx -> &fx[temp1][temp2]
					ldr r3, [r3] // fx[temp1][temp2]
					// Mult then add to sum
					mla r10, r0, r3, r10
					if_done:
					add r7, r7, #1 // j++
					b kh_loop
				kh_loop_done:
				add r6, r6, #1 // i++
				b kw_loop
			kw_loop_done:
			ldr r0, =gx // &gx (overwrite)
			mov r3, #0 // overwite
			mla r3, r5, r1, r4 // x * iwh + y
			lsl r3, #2
			add r0, r0, r3 // gx[x][y]
			str r10, [r0]
			
			add r5, r5, #1 // x++
			b iw_loop
		iw_loop_done:
		add r4, r4, #1 // y++
		b ih_loop

end: b end