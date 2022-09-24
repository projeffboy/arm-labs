.equ LOAD, 0xfffec600
.equ COUNTER, 0xfffec604
.equ INTERRUPT_STATUS, 0xfffec60c
// clock freq 200 MHz
.equ LOAD_VALUE_1s, 200000000
.equ LOAD_VALUE_10ms, 2000000

.global _start
_start:
	b stopwatch

stopwatch:
  mov r0, #0b111111
  mov r1, #0
  bl HEX_write_ASM
  bl PB_clear_edgecp_ASM
  
  mov r4, #0 // 10ms
  mov r5, #0 // 100ms
  mov r6, #0 // 1s
  mov r7, #0 // 10s
  mov r8, #0 // 1min
  mov r9, #0 // 10min

  // 1. start timer
  ldr r0, =LOAD_VALUE_10ms
  mov r1, #1 // E bit field
  bl ARM_TIM_config_ASM
  // 2. update time registers

while2:
  // reset
  mov r0, #4
  bl PB_edgecp_is_pressed_ASM
  cmp r0, #1
    beq stopwatch

  // stop
  mov r0, #2
  bl PB_edgecp_is_pressed_ASM
  cmp r0, #1
    bleq PB_clear_edgecp_ASM
    beq while2

  // start
  mov r0, #1
  bl PB_edgecp_is_pressed_ASM
  cmp r0, #1
    bne while2

  bl ARM_TIM_read_INT_ASM
  cmp r0, #1 // F bit field
  bne while2
	  // 1. start timer
	  ldr r0, =LOAD_VALUE_10ms
	  mov r1, #1 // E bit field
	  bl ARM_TIM_config_ASM
	  // 2. update time registers
    mov r10, #1 // tells you which of r4-r9 got changed

    add r4, r4, #1

	  cmp r4, #10
    bne incr_1s
	  	mov r4, #0
      add r5, r5, #1
      add r10, r10, #2
    incr_1s:
	  cmp r5, #10
    bne incr_10s
	  	mov r5, #0
      add r6, r6, #1
      add r10, r10, #4
    incr_10s:
	  cmp r6, #10
    bne incr_1min
	  	mov r6, #0
      add r7, r7, #1
      add r10, r10, #8
    incr_1min:
	  cmp r7, #6
    bne incr_10min
	  	mov r7, #0
      add r8, r8, #1
      add r10, r10, #16
    incr_10min:
	  cmp r8, #10
    bne check_reset
	  	mov r8, #0
      add r9, r9, #1
      add r10, r10, #32
    check_reset:
	  cmp r9, #10
	    bleq stopwatch
    // 3. update hex
    mov r0, #0b000001
    mov r1, r4
      blne HEX_write_ASM
    tst r10, #2
      movne r0, #0b000010
      movne r1, r5
      blne HEX_write_ASM
    tst r10, #4
      movne r0, #0b000100
      movne r1, r6
      blne HEX_write_ASM
    tst r10, #8
      movne r0, #0b001000
      movne r1, r7
      blne HEX_write_ASM
    tst r10, #16
      movne r0, #0b010000
      movne r1, r8
      blne HEX_write_ASM
    tst r10, #32
      movne r0, #0b100000
      movne r1, r9
      blne HEX_write_ASM
	  // 4. clear F
	  bl ARM_TIM_clear_INT_ASM
  b while2

// 0. init: hex write 0, clear F, counter
// do-while (counter <= 15) if (F bit field == 1)
// 1. start timer
// 2. update hex
// 3. clear F
test:
  // 0. init: hex write 0, clear F, counter
  mov r0, #1
  mov r1, #0
  bl HEX_write_ASM
  mov r4, #0 // counts to 15
  bleq ARM_TIM_clear_INT_ASM
  b do
while:
  bl ARM_TIM_read_INT_ASM
  cmp r0, #1 // F bit field
  bne while
	  do:
	  // 1. start timer
	  ldr r0, =LOAD_VALUE_1s
	  mov r1, #1 // E bit field
	  bl ARM_TIM_config_ASM
	  // 2. update hex
	  mov r0, #1
	  mov r1, r4
	  bl HEX_write_ASM
	  add r4, r4, #1
	  // 3. clear F
	  bl ARM_TIM_clear_INT_ASM
  cmp r4, #15
  movgt r4, #0
  b while

// INPUT: r0 initial count, r1 config bits
ARM_TIM_config_ASM:
  ldr r2, =LOAD
  str r0, [r2]
  str r1, [r2, #8] // write to CONTROL
  bx lr

// OUTPUT: F bit field
ARM_TIM_read_INT_ASM:
  ldr r0, =INTERRUPT_STATUS
  ldr r0, [r0]
  and r0, r0, #1
  bx lr

ARM_TIM_clear_INT_ASM:
  ldr r0, =INTERRUPT_STATUS
  mov r1, #1
  str r1, [r0]
  bx lr
  
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