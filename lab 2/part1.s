.global _start
_start:
	// flood HEX 4 and 5
	mov r0, #0b110000
	bl HEX_flood_ASM
	mov r10, #1 // for reflooding, are they on?
endless_loop:
	// Poll slider switches
	bl read_slider_switches_ASM
	// If SW9 is pressed then clear
	tst r0, #0b1000000000
	beq else
		mov r0, #0b111111
		bl HEX_clear_ASM
		bl PB_clear_edgecp_ASM
		mov r10, #0 // for reflooding
		b endless_loop
	else:
		// This is for reflooding
		cmp r10, #0
		// flood HEX 4 and 5
		moveq r0, #0b110000
		bleq HEX_flood_ASM
		moveq r10, #1

		and r4, r0, #0b1111 // safekeep SW0-3
		bl write_LEDs_ASM
		// Check if a push button was just released
		bl read_PB_edgecp_ASM
		cmp r0, #0
		beq endless_loop
			// update HEX
			mov r1, r4
			mov r5, r0 // safekeep PB0-3
			bl HEX_write_ASM
			// clear edgecapture
			mov r0, r5
			bl PB_clear_edgecp_ASM
	b endless_loop

end:
  b end

/* SWITCH AND LED FUNCTIONS */

.equ SW_MEMORY, 0xff200040
.equ LED_MEMORY, 0xff200000

// OUTPUT: on-switch indices
read_slider_switches_ASM:
    ldr r1, =SW_MEMORY
    ldr r0, [r1]
    bx  lr

// INPUT: r0 indices of LEDs to turn on
write_LEDs_ASM:
    ldr r1, =LED_MEMORY
    str r0, [r1]
    bx  lr

/* HEX FUNCTIONS */

.equ HEX0_BASE, 0xff200020
.equ HEX4_BASE, 0xff200030

// INPUT: r0 HEX indices
HEX_clear_ASM:
	push {r4, r5}
	
	// Error checking
	cmp r0, #0
	beq HEX_clear_return

	mov r2, #0 // nth display (0 <= n <= 5)
	
	HEX_clear_while:
	cmp r0, #0
	beq HEX_clear_return
	cmp r2, #5
	bgt HEX_clear_return
		tst r0, #1
		beq HEX_clear_fi
			mov r4, r2 // copy r2 for decrementing
			ldr r1, =HEX0_BASE // HEX0_BASE
			cmp r2, #3
			ble HEX_clear_fi2
				ldr r1, =HEX4_BASE
				sub r4, r4, #4
			HEX_clear_fi2:
			
			ldr r3, [r1] // display info
			mov r5, #0xffffff00 // clearing method
			
			HEX_clear_while2:
			cmp r4, #0
			beq HEX_clear_done2
				lsl r5, r5, #8
				add r5, r5, #0xff
				sub r4, r4, #1
				b HEX_clear_while2
			HEX_clear_done2:
			
			and r3, r3, r5
			str r3, [r1]
					
		HEX_clear_fi:
		lsr r0, r0, #1
		add r2, r2, #1
	B HEX_clear_while
HEX_clear_return:
	pop {r4, r5}
	bx lr

// INPUT: r0, HEX indices
// NOTE: r0 is unchanged
HEX_flood_ASM:
	push {r4, r5}
	
	cmp r0, #0
	beq HEX_flood_return

	mov r2, #0 // nth display (0 <= n <= 5)
	
	HEX_flood_while:
	cmp r0, #0
	beq HEX_flood_return
	cmp r2, #5
	bgt HEX_flood_return
		tst r0, #1
		beq HEX_flood_fi
			mov r4, r2 // copy r2 for decrementing
			ldr r1, =HEX0_BASE // HEX0_BASE
			cmp r2, #3
			ble HEX_flood_fi2
				ldr r1, =HEX4_BASE
				sub r4, r4, #4
			HEX_flood_fi2:
			
			ldr r3, [r1] // display info
			mov r5, #0x000000ff // flooding method
			
			HEX_flood_while2:
			cmp r4, #0
			beq HEX_flood_done2
				lsl r5, r5, #8
				sub r4, r4, #1
				b HEX_flood_while2
			HEX_flood_done2:
			
			orr r3, r3, r5
			str r3, [r1]
					
		HEX_flood_fi:
		lsr r0, r0, #1
		add r2, r2, #1
	b HEX_flood_while
HEX_flood_return:
	pop {r4, r5}
	bx lr

// INPUT: r0 HEX indices, r1 what to display
HEX_write_ASM:
	push {r4-r7, lr}
	
	// Error checking
	cmp r0, #0
	beq HEX_write_return
	cmp r1, #15
	bgt HEX_write_return

	mov r6, r1 // parameter 2 
	mov r7, r0 // safekeep r0
	bl HEX_clear_ASM
	mov r0, r7

	mov r2, #0 // nth display (0 <= n <= 5)
	
	HEX_write_while:
	cmp r0, #0
	beq HEX_write_return
	cmp r2, #5
	bgt HEX_write_return
		tst r0, #1
		beq HEX_write_fi
			mov r4, r2 // copy r2 for decrementing
			ldr r1, =HEX0_BASE // HEX0_BASE
			cmp r2, #3
			ble HEX_write_0
				ldr r1, =HEX4_BASE
				sub r4, r4, #4
			HEX_write_0:
			cmp r6, #0
			bne HEX_write_1
				mov r5, #0b0111111 // digit encoding, 7 out of 8 bits for the 7 segments
				b HEX_write_break
			HEX_write_1:
			cmp r6, #1
			bne HEX_write_2
				mov r5, #0b0000110
				b HEX_write_break
			HEX_write_2:
			cmp r6, #2
			bne HEX_write_3
				mov r5, #0b1011011
				b HEX_write_break
			HEX_write_3:
			cmp r6, #3
			bne HEX_write_4
				mov r5, #0b1001111
				b HEX_write_break
			HEX_write_4:
			cmp r6, #4
			bne HEX_write_5
				mov r5, #0b1100110
				b HEX_write_break
			HEX_write_5:
			cmp r6, #5
			bne HEX_write_6
				mov r5, #0b1101101
				b HEX_write_break
			HEX_write_6:
			cmp r6, #6
			bne HEX_write_7
				mov r5, #0b1111101
				b HEX_write_break
			HEX_write_7:
			cmp r6, #7
			bne HEX_write_8
				mov r5, #0b0000111
				b HEX_write_break
			HEX_write_8:
			cmp r6, #8
			bne HEX_write_9
				mov r5, #0b1111111
				b HEX_write_break
			HEX_write_9:
			cmp r6, #9
			bne HEX_write_A
				mov r5, #0b1101111
				b HEX_write_break
			HEX_write_A:
			cmp r6, #10
			bne HEX_write_b
				mov r5, #0b1110111
				b HEX_write_break
			HEX_write_b:
			cmp r6, #11
			bne HEX_write_C
				mov r5, #0b1111100
				b HEX_write_break
			HEX_write_C:
			cmp r6, #12
			bne HEX_write_D
				mov r5, #0b0111001
				b HEX_write_break
			HEX_write_D:
			cmp r6, #13
			bne HEX_write_E
				mov r5, #0b1011110
				b HEX_write_break
			HEX_write_E:
			cmp r6, #14
			bne HEX_write_F
				mov r5, #0b1111001
				b HEX_write_break
			HEX_write_F:
			cmp r6, #15
			bne HEX_write_return
				mov r5, #0b1110001
			HEX_write_break:
			
			ldr r3, [r1] // display info
			
			HEX_write_while2:
			cmp r4, #0
			beq HEX_write_done2
				lsl r5, r5, #8
				sub r4, r4, #1
				b HEX_write_while2
			HEX_write_done2:
			
			orr r3, r3, r5
			str r3, [r1]
					
		HEX_write_fi:
		lsr r0, r0, #1
		add r2, r2, #1
	B HEX_write_while
HEX_write_return:
	pop {r4-r7, lr}
	bx lr

/* PUSHBUTTON FUNCTIONS */

.equ PB_DATA_REG, 0xFF200050
.equ PB_EDGECP_REG, 0xFF20005C

// OUTPUT: on-PB indices
read_PB_data_ASM:
	ldr r0, =PB_DATA_REG
	ldr r0, [r0]
	bx lr

// INPUT: r0 PB index
// OUTPUT: is the index PB on
PB_data_is_pressed_ASM:
	ldr r1, =PB_DATA_REG
	ldr r1, [r1]
	tst r0, r1
	moveq r0, #0
	movne r0, #1
	bx lr

// OUTPUT: on-edgecp PB indices
read_PB_edgecp_ASM:
	ldr r0, =PB_EDGECP_REG
	ldr r0, [r0]
	bx lr

// INPUT: r0 PB index
// OUTPUT: is the index PB edgecp on
PB_edgecp_is_pressed_ASM:
	ldr r1, =PB_EDGECP_REG
	ldr r1, [r1]
	tst r0, r1
	moveq r0, #0
	movne r0, #1
	bx lr

PB_clear_edgecp_ASM:
	ldr r1, =PB_EDGECP_REG
	mov r0, #0b1111
	str r0, [r1]
	bx lr
	
enable_PB_INT_ASM:
	ldr r1, =PB_DATA_REG
	mov r0, #0b1111
	str r0, [r1, #8]
	bx lr

disable_PB_INT_ASM:
	ldr r1, =PB_DATA_REG
	mov r0, #0
	str r0, [r1, #8]
	bx lr