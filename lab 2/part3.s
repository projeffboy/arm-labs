.section .vectors, "ax"
B _start
B SERVICE_UND       // undefined instruction vector
B SERVICE_SVC       // software interrupt vector
B SERVICE_ABT_INST  // aborted prefetch vector
B SERVICE_ABT_DATA  // aborted data vector
.word 0 // unused vector
B SERVICE_IRQ       // IRQ interrupt vector
B SERVICE_FIQ       // FIQ interrupt vector

.data
PB_int_flag:
    .word 0x0
tim_int_flag:
    .word 0x0

.text
.global _start

_start:
    /* Set up stack pointers for IRQ and SVC processor modes */
    MOV        R1, #0b11010010      // interrupts masked, MODE = IRQ
    MSR        CPSR_c, R1           // change to IRQ mode
    LDR        SP, =0xFFFFFFFF - 3  // set IRQ stack to A9 onchip memory
    /* Change to SVC (supervisor) mode with interrupts disabled */
    MOV        R1, #0b11010011      // interrupts masked, MODE = SVC
    MSR        CPSR, R1             // change to supervisor mode
    LDR        SP, =0x3FFFFFFF - 3  // set SVC stack to top of DDR3 memory
    BL     CONFIG_GIC               // configure the ARM GIC
    // To DO: write to the pushbutton KEY interrupt mask register
    // Or, you can call enable_PB_INT_ASM subroutine from previous task
    LDR        R0, =0xFF200050      // pushbutton KEY base address
    MOV        R1, #0xF             // set interrupt mask bits
    STR        R1, [R0, #0x8]       // interrupt mask register (base + 8)
    // to enable interrupt for ARM A9 private timer, use ARM_TIM_config_ASM subroutine
    ldr r0, =LOAD_VALUE_1s
	mov r1, #0b101 // I and E bit field
    bl ARM_TIM_config_ASM
    // enable IRQ interrupts in the processor
    MOV        R0, #0b01010011      // IRQ unmasked, MODE = SVC
    MSR        CPSR_c, R0

IDLE:
    B stopwatch // This is where you write your objective task


stopwatch:
  mov r0, #0b111111
  mov r1, #0
  bl HEX_write_ASM
  bl PB_int_flag_clear_ASM
  
  mov r4, #0 // 10ms
  mov r5, #0 // 100ms
  mov r6, #0 // 1s
  mov r7, #0 // 10s
  mov r8, #0 // 1min
  mov r9, #0 // 10min
  mov r11, #0 //

  // 1. start timer
  ldr r0, =LOAD_VALUE_10ms
  mov r1, #0b101 // I and E bit field
  bl ARM_TIM_config_ASM
  // 2. update time registers

while2:
  // reset
  mov r0, #4
  bl PB_int_flag_is_pressed_ASM
  cmp r0, #1
    beq stopwatch

  // stop
  mov r0, #2
  bl PB_int_flag_is_pressed_ASM
  cmp r0, #1
    bleq PB_int_flag_clear_ASM
    beq while2

  // start
  mov r0, #1
  bl PB_int_flag_is_pressed_ASM
  cmp r0, #1
    bne while2

  bl tim_int_flag_read_ASM
  cmp r0, #1 // F bit field
  bne while2
	  // 1. start timer
	  ldr r0, =LOAD_VALUE_10ms
	  mov r1, #0b101 // I and E bit field
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
	bl tim_int_flag_clear_ASM
  b while2

PB_int_flag_is_pressed_ASM:
	ldr r1, =PB_int_flag
	ldr r1, [r1]
	tst r0, r1
		moveq r0, #0
		movne r0, #1
    bx lr

PB_int_flag_clear_ASM:
	ldr r1, =PB_int_flag
	mov r0, #0
	str r0, [r1]
    bx lr

tim_int_flag_read_ASM:
	ldr r0, =tim_int_flag
	ldr r0, [r0]
	and r0, r0, #1
	bx lr
	
tim_int_flag_clear_ASM:
	ldr r0, =tim_int_flag
	mov r1, #0
	str r1, [r0]
	bx lr

test2:
	mov r3, #0
	mov r4, #0
	mov r2, #0
loop2:
	mov r0, #1
	bl PB_int_flag_is_pressed_ASM
	cmp r0, #1
		addeq r2, r2, #1
		bleq PB_int_flag_clear_ASM
	bl tim_int_flag_read_ASM
	cmp r0, #1
		addeq r4, r4, #1
		bleq tim_int_flag_clear_ASM
	b loop2

test:
	mov r3, #0
	mov r4, #0
	mov r2, #0
loop:
	ldr r0, =PB_int_flag
	ldr r1, [r0]
	cmp r1, #0
		addne r2, r2, #1
		strne r3, [r0]
	ldr r0, =tim_int_flag
	ldr r1, [r0]
	cmp r1, #0
		addne r4, r4, #1
		strne r3, [r0]
	b loop

/*--- Undefined instructions --------------------------------------*/
SERVICE_UND:
    B SERVICE_UND
/*--- Software interrupts ----------------------------------------*/
SERVICE_SVC:
    B SERVICE_SVC
/*--- Aborted data reads ------------------------------------------*/
SERVICE_ABT_DATA:
    B SERVICE_ABT_DATA
/*--- Aborted instruction fetch -----------------------------------*/
SERVICE_ABT_INST:
    B SERVICE_ABT_INST
/*--- IRQ ---------------------------------------------------------*/
SERVICE_IRQ:
    PUSH {R0-R7, LR}
/* Read the ICCIAR from the CPU Interface */
    LDR R4, =0xFFFEC100
    LDR R5, [R4, #0x0C] // read from ICCIAR
/* To Do: Check which interrupt has occurred (check interrupt IDs)
   Then call the corresponding ISR
   If the ID is not recognized, branch to UNEXPECTED
   See the assembly example provided in the De1-SoC Computer_Manual on page 46 */
Timer_check:
    CMP R5, #29
    BEQ Timer
Pushbutton_check:
    CMP R5, #73
UNEXPECTED:
    BNE UNEXPECTED      // if not recognized, stop here
    BL KEY_ISR
    B EXIT_IRQ

Timer:
    BL ARM_TIM_ISR

EXIT_IRQ:
/* Write to the End of Interrupt Register (ICCEOIR) */
    STR R5, [R4, #0x10] // write to ICCEOIR
    POP {R0-R7, LR}
SUBS PC, LR, #4
/*--- FIQ ---------------------------------------------------------*/
SERVICE_FIQ:
    B SERVICE_FIQ

CONFIG_GIC:
    PUSH {LR}
/* To configure the FPGA KEYS interrupt (ID 73):
* 1. set the target to cpu0 in the ICDIPTRn register
* 2. enable the interrupt in the ICDISERn register */
/* CONFIG_INTERRUPT (int_ID (R0), CPU_target (R1)); */
/* To Do: you can configure different interrupts
   by passing their IDs to R0 and repeating the next 3 lines */
    MOV R0, #73            // KEY port (Interrupt ID = 73)
    MOV R1, #1             // this field is a bit-mask; bit 0 targets cpu0
    BL CONFIG_INTERRUPT
    MOV R0, #29 // timer ID
    MOV R1, #1
    BL CONFIG_INTERRUPT

/* configure the GIC CPU Interface */
    LDR R0, =0xFFFEC100    // base address of CPU Interface
/* Set Interrupt Priority Mask Register (ICCPMR) */
    LDR R1, =0xFFFF        // enable interrupts of all priorities levels
    STR R1, [R0, #0x04]
/* Set the enable bit in the CPU Interface Control Register (ICCICR).
* This allows interrupts to be forwarded to the CPU(s) */
    MOV R1, #1
    STR R1, [R0]
/* Set the enable bit in the Distributor Control Register (ICDDCR).
* This enables forwarding of interrupts to the CPU Interface(s) */
    LDR R0, =0xFFFED000
    STR R1, [R0]
    POP {PC}

/*
* Configure registers in the GIC for an individual Interrupt ID
* We configure only the Interrupt Set Enable Registers (ICDISERn) and
* Interrupt Processor Target Registers (ICDIPTRn). The default (reset)
* values are used for other registers in the GIC
* Arguments: R0 = Interrupt ID, N
* R1 = CPU target
*/
CONFIG_INTERRUPT:
    PUSH {R4-R5, LR}
/* Configure Interrupt Set-Enable Registers (ICDISERn).
* reg_offset = (integer_div(N / 32) * 4
* value = 1 << (N mod 32) */
    LSR R4, R0, #3    // calculate reg_offset
    BIC R4, R4, #3    // R4 = reg_offset
    LDR R2, =0xFFFED100
    ADD R4, R2, R4    // R4 = address of ICDISER
    AND R2, R0, #0x1F // N mod 32
    MOV R5, #1        // enable
    LSL R2, R5, R2    // R2 = value
/* Using the register address in R4 and the value in R2 set the
* correct bit in the GIC register */
    LDR R3, [R4]      // read current register value
    ORR R3, R3, R2    // set the enable bit
    STR R3, [R4]      // store the new register value
/* Configure Interrupt Processor Targets Register (ICDIPTRn)
* reg_offset = integer_div(N / 4) * 4
* index = N mod 4 */
    BIC R4, R0, #3    // R4 = reg_offset
    LDR R2, =0xFFFED800
    ADD R4, R2, R4    // R4 = word address of ICDIPTR
    AND R2, R0, #0x3  // N mod 4
    ADD R4, R2, R4    // R4 = byte address in ICDIPTR
/* Using register address in R4 and the value in R2 write to
* (only) the appropriate byte */
    STRB R1, [R4]
    POP {R4-R5, PC}

KEY_ISR:
    LDR R0, =0xFF200050    // base address of pushbutton KEY port
    LDR R1, [R0, #0xC]     // read edge capture register
	MOV R2, #0xF
	STR R2, [R0, #0xC] // clear the interrupt

    LDR R0, =PB_int_flag
    STR R1, [R0] // store edgecp reg
    BX LR

ARM_TIM_ISR:
    LDR R0, =INTERRUPT_STATUS
    MOV R1, #1
    STR R1, [R0] // clear the interrupt
    LDR R0, =tim_int_flag
    STR R1, [R0] // write to tim flag
    BX LR

/* TIMER FUNCTIONS */

.equ LOAD, 0xfffec600
.equ COUNTER, 0xfffec604
.equ INTERRUPT_STATUS, 0xfffec60c
// clock freq 200 MHz
.equ LOAD_VALUE_1s, 200000000
.equ LOAD_VALUE_10ms, 2000000

// INPUT: r0 initial count, r1 config bits
ARM_TIM_config_ASM:
  ldr r2, =LOAD
  str r0, [r2]
  str r1, [r2, #8] // write to CONTROL
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