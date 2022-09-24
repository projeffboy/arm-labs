.global _start
_start:
  bl      input_loop
end:
  b       end

@ TODO: insert PS/2 driver here.
.equ PS2_DATA, 0xff200100

base .req r3

read_PS2_data_ASM:
	ldr base, =PS2_DATA // base address
	ldr base, [base] // base word
	mov r2, #1
	lsl r2, r2, #15
	and r1, base, r2 // (1 << 15) is bit 15 in bits 31...0; rvalid
	// r1 is positive if rvalid = 1

	cmp r1, #0
	beq invalid
		and r1, base, #0xff // get bits 7..0; first byte; data field
		strb r1, [r0]
		mov r0, #1 // valid
		bx lr
	invalid:
	mov r0, #0 // invalid
	bx lr

@ TODO: copy VGA driver here.
.equ PIXEL_BUFF, 0xc8000000
.equ CHAR_BUFF, 0xc9000000

x .req r0
y .req r1
color .req r2
char .req r2
mem .req r3

// Input: r0 x, r1 y, r2 color
VGA_draw_point_ASM:
  // mem = 0xc8000000 | (y << 10) | (x << 1)
	ldr mem, =PIXEL_BUFF
	add mem, mem, y, lsl#10
	orr mem, mem, x, lsl#1
	strh color, [mem]
	bx lr
	
VGA_clear_pixelbuff_ASM: // same basic outline as the clear charbuff code
  ldr mem, =PIXEL_BUFF
  mov x, #0
  mov y, #0
  mov r2, #0 // for storing 0
  while_pb:
  cmp y, #240
  beq done_pb
    while_2_pb:
    cmp x, #320
    beq done_2_pb
      strh r2, [mem]
      add mem, mem, #2
      add x, x, #1
      b while_2_pb
    done_2_pb:
    add y, y, #1
	mov x, #0
    ldr mem, =PIXEL_BUFF
    orr mem, mem, y, lsl#10
    b while_pb
  done_pb:
  bx lr
	
// Input: r0 x, r1 y, r2 char (ascii code)
VGA_write_char_ASM:
  // mem = 0xc8000000 | (y << 10) | (x << 1)
  ldr mem, =CHAR_BUFF
  add mem, mem, y, lsl#7
  orr mem, mem, x
  strb char, [mem]
  bx lr
	
VGA_clear_charbuff_ASM: // same basic outline as the clear pixelbuff code
  ldr mem, =CHAR_BUFF
  mov x, #0
  mov y, #0
  mov r2, #0 // for storing 0
  while_cc:
  cmp y, #60
  beq done_cc
    while_2_cc:
    cmp x, #80
    beq done_2_cc
      strb r2, [mem]
      add mem, mem, #1
      add x, x, #1
      b while_2_cc
    done_2_cc:
    add y, y, #1
	mov x, #0
    ldr mem, =CHAR_BUFF
    orr mem, mem, y, lsl#7
    b while_cc
  done_cc:
  bx lr

write_hex_digit:
  push    {r4, lr}
  cmp     r2, #9
  addhi   r2, r2, #55
  addls   r2, r2, #48
  and     r2, r2, #255
  bl      VGA_write_char_ASM
  pop     {r4, pc}
write_byte:
  push    {r4, r5, r6, lr}
  mov     r5, r0
  mov     r6, r1
  mov     r4, r2
  lsr     r2, r2, #4
  bl      write_hex_digit
  and     r2, r4, #15
  mov     r1, r6
  add     r0, r5, #1
  bl      write_hex_digit
  pop     {r4, r5, r6, pc}
input_loop:
  push    {r4, r5, lr}
  sub     sp, sp, #12
  bl      VGA_clear_pixelbuff_ASM
  bl      VGA_clear_charbuff_ASM
  mov     r4, #0
  mov     r5, r4
  b       .input_loop_L9
.input_loop_L13:
  ldrb    r2, [sp, #7]
  mov     r1, r4
  mov     r0, r5
  bl      write_byte
  add     r5, r5, #3
  cmp     r5, #79
  addgt   r4, r4, #1
  movgt   r5, #0
.input_loop_L8:
  cmp     r4, #59
  bgt     .input_loop_L12
.input_loop_L9:
  add     r0, sp, #7
  bl      read_PS2_data_ASM
  cmp     r0, #0
  beq     .input_loop_L8
  b       .input_loop_L13
.input_loop_L12:
  add     sp, sp, #12
  pop     {r4, r5, pc}