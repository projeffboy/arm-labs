.equ PIXEL_BUFF, 0xc8000000
.equ CHAR_BUFF, 0xc9000000

x .req r0
y .req r1
color .req r2
char .req r2
mem .req r3

.global _start
_start:
  bl      draw_test_screen
end:
  b       end

draw_test_screen:
  push    {r4, r5, r6, r7, r8, r9, r10, lr}
  bl      VGA_clear_pixelbuff_ASM
  bl      VGA_clear_charbuff_ASM
  mov     r6, #0
  ldr     r10, .draw_test_screen_L8
  ldr     r9, .draw_test_screen_L8+4
  ldr     r8, .draw_test_screen_L8+8
  b       .draw_test_screen_L2
.draw_test_screen_L7:
  add     r6, r6, #1
  cmp     r6, #320
  beq     .draw_test_screen_L4
.draw_test_screen_L2:
  smull   r3, r7, r10, r6
  asr     r3, r6, #31
  rsb     r7, r3, r7, asr #2
  lsl     r7, r7, #5
  lsl     r5, r6, #5
  mov     r4, #0
.draw_test_screen_L3:
  smull   r3, r2, r9, r5
  add     r3, r2, r5
  asr     r2, r5, #31
  rsb     r2, r2, r3, asr #9
  orr     r2, r7, r2, lsl #11
  lsl     r3, r4, #5
  smull   r0, r1, r8, r3
  add     r1, r1, r3
  asr     r3, r3, #31
  rsb     r3, r3, r1, asr #7
  orr     r2, r2, r3
  mov     r1, r4
  mov     r0, r6
  bl      VGA_draw_point_ASM
  add     r4, r4, #1
  add     r5, r5, #32
  cmp     r4, #240
  bne     .draw_test_screen_L3
  b       .draw_test_screen_L7
.draw_test_screen_L4:
  mov     r2, #72
  mov     r1, #5
  mov     r0, #20
  bl      VGA_write_char_ASM
  mov     r2, #101
  mov     r1, #5
  mov     r0, #21
  bl      VGA_write_char_ASM
  mov     r2, #108
  mov     r1, #5
  mov     r0, #22
  bl      VGA_write_char_ASM
  mov     r2, #108
  mov     r1, #5
  mov     r0, #23
  bl      VGA_write_char_ASM
  mov     r2, #111
  mov     r1, #5
  mov     r0, #24
  bl      VGA_write_char_ASM
  mov     r2, #32
  mov     r1, #5
  mov     r0, #25
  bl      VGA_write_char_ASM
  mov     r2, #87
  mov     r1, #5
  mov     r0, #26
  bl      VGA_write_char_ASM
  mov     r2, #111
  mov     r1, #5
  mov     r0, #27
  bl      VGA_write_char_ASM
  mov     r2, #114
  mov     r1, #5
  mov     r0, #28
  bl      VGA_write_char_ASM
  mov     r2, #108
  mov     r1, #5
  mov     r0, #29
  bl      VGA_write_char_ASM
  mov     r2, #100
  mov     r1, #5
  mov     r0, #30
  bl      VGA_write_char_ASM
  mov     r2, #33
  mov     r1, #5
  mov     r0, #31
  bl      VGA_write_char_ASM
  pop     {r4, r5, r6, r7, r8, r9, r10, pc}
.draw_test_screen_L8:
  .word   1717986919
  .word   -368140053
  .word   -2004318071
  
@ TODO: Insert VGA driver functions here.
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