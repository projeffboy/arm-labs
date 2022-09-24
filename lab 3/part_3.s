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

@ TODO: adapt this function to draw a real-life flag of your choice.
draw_real_life_flag:
  push    {r4, lr}
  bl      draw_china_flag
  pop     {r4, pc}

@ TODO: adapt this function to draw an imaginary flag of your choice.
draw_imaginary_flag:
  push    {r4, lr}
  bl      draw_shield_flag
  pop     {r4, pc}

draw_texan_flag:
  push    {r4, lr}
  sub     sp, sp, #8
  ldr     r3, .flags_L32
  str     r3, [sp]
  mov     r3, #240
  mov     r2, #106
  mov     r1, #0
  mov     r0, r1
  bl      draw_rectangle
  ldr     r4, .flags_L32+4
  mov     r3, r4
  mov     r2, #43
  mov     r1, #120
  mov     r0, #53
  bl      draw_star
  str     r4, [sp]
  mov     r3, #120
  mov     r2, #214
  mov     r1, #0
  mov     r0, #106
  bl      draw_rectangle
  ldr     r3, .flags_L32+8
  str     r3, [sp]
  mov     r3, #120
  mov     r2, #214
  mov     r1, r3
  mov     r0, #106
  bl      draw_rectangle
  add     sp, sp, #8
  pop     {r4, pc}
.flags_L32:
  .word   2911
  .word   65535
  .word   45248

draw_china_flag:
  push {r4, lr}
  sub sp, sp, #8 // apparently it's not sp-4 because of how draw rectangle is written
  // red background
  mov r0, #0
  mov r1, #0
  mov r2, #320
  mov r3, #240
  ldr r4, .china_red
  str r4, [sp]
  bl draw_rectangle
  // big yellow star
  mov r0, #55
  mov r1, #65
  mov r2, #38
  ldr r3, .china_gold
  bl draw_star
  // small yellow stars
  mov r0, #125
  mov r1, #25
  mov r2, #16
  ldr r3, .china_gold
  bl draw_star
  mov r0, #155
  mov r1, #55
  mov r2, #16
  ldr r3, .china_gold
  bl draw_star
  mov r0, #155
  mov r1, #95
  mov r2, #16
  ldr r3, .china_gold
  bl draw_star
  mov r0, #125
  mov r1, #130
  mov r2, #16
  ldr r3, .china_gold
  bl draw_star

  add sp, sp, #8
  pop {r4, pc}
.china_red:
  .word 0b1110100011100100 // rgb: 238/28/37 -> 29/7/4
.china_gold:
  .word 0b1111111111100000 // rgb: 255/255/0

draw_shield_flag:
  push {r4, lr}
  sub sp, sp, #8 // apparently it's not sp-4 because of how draw rectangle is written
  // red, white, red, then blue background
  mov r0, #0
  mov r1, #0
  mov r2, #320
  mov r3, #240
  ldr r4, .shield_red
  str r4, [sp]
  bl draw_rectangle
  mov r0, #35
  mov r1, #22
  mov r2, #250
  mov r3, #196
  ldr r4, .shield_white
  str r4, [sp]
  bl draw_rectangle
  mov r0, #70
  mov r1, #44
  mov r2, #180
  mov r3, #152
  ldr r4, .shield_red
  str r4, [sp]
  bl draw_rectangle
  mov r0, #105
  mov r1, #66
  mov r2, #110
  mov r3, #106
  ldr r4, .shield_blue
  str r4, [sp]
  bl draw_rectangle
  // center white star
  mov r0, #160
  mov r1, #117
  mov r2, #54
  ldr r3, .shield_white
  bl draw_star

  add sp, sp, #8
  pop {r4, pc}
.shield_red:
  .word 0b1010100010100101 // rgb: 170,20,40
.shield_white:
  .word 0b1111111111111111 // rgb: 255/255/255
.shield_blue:
  .word 0b0000000000001000 // rgb: 0,0,66

draw_rectangle:
  push    {r4, r5, r6, r7, r8, r9, r10, lr}
  ldr     r7, [sp, #32]
  add     r9, r1, r3
  cmp     r1, r9
  popge   {r4, r5, r6, r7, r8, r9, r10, pc}
  mov     r8, r0
  mov     r5, r1
  add     r6, r0, r2
  b       .flags_L2
.flags_L5:
  add     r5, r5, #1
  cmp     r5, r9
  popeq   {r4, r5, r6, r7, r8, r9, r10, pc}
.flags_L2:
  cmp     r8, r6
  movlt   r4, r8
  bge     .flags_L5
.flags_L4:
  mov     r2, r7
  mov     r1, r5
  mov     r0, r4
  bl      VGA_draw_point_ASM
  add     r4, r4, #1
  cmp     r4, r6
  bne     .flags_L4
  b       .flags_L5
should_fill_star_pixel:
  push    {r4, r5, r6, lr}
  lsl     lr, r2, #1
  cmp     r2, r0
  blt     .flags_L17
  add     r3, r2, r2, lsl #3
  add     r3, r2, r3, lsl #1
  lsl     r3, r3, #2
  ldr     ip, .flags_L19
  smull   r4, r5, r3, ip
  asr     r3, r3, #31
  rsb     r3, r3, r5, asr #5
  cmp     r1, r3
  blt     .flags_L18
  rsb     ip, r2, r2, lsl #5
  lsl     ip, ip, #2
  ldr     r4, .flags_L19
  smull   r5, r6, ip, r4
  asr     ip, ip, #31
  rsb     ip, ip, r6, asr #5
  cmp     r1, ip
  bge     .flags_L14
  sub     r2, r1, r3
  add     r2, r2, r2, lsl #2
  add     r2, r2, r2, lsl #2
  rsb     r2, r2, r2, lsl #3
  ldr     r3, .flags_L19+4
  smull   ip, r1, r3, r2
  asr     r3, r2, #31
  rsb     r3, r3, r1, asr #5
  cmp     r3, r0
  movge   r0, #0
  movlt   r0, #1
  pop     {r4, r5, r6, pc}
.flags_L17:
  sub     r0, lr, r0
  bl      should_fill_star_pixel
  pop     {r4, r5, r6, pc}
.flags_L18:
  add     r1, r1, r1, lsl #2
  add     r1, r1, r1, lsl #2
  ldr     r3, .flags_L19+8
  smull   ip, lr, r1, r3
  asr     r1, r1, #31
  sub     r1, r1, lr, asr #5
  add     r2, r1, r2
  cmp     r2, r0
  movge   r0, #0
  movlt   r0, #1
  pop     {r4, r5, r6, pc}
.flags_L14:
  add     ip, r1, r1, lsl #2
  add     ip, ip, ip, lsl #2
  ldr     r4, .flags_L19+8
  smull   r5, r6, ip, r4
  asr     ip, ip, #31
  sub     ip, ip, r6, asr #5
  add     r2, ip, r2
  cmp     r2, r0
  bge     .flags_L15
  sub     r0, lr, r0
  sub     r3, r1, r3
  add     r3, r3, r3, lsl #2
  add     r3, r3, r3, lsl #2
  rsb     r3, r3, r3, lsl #3
  ldr     r2, .flags_L19+4
  smull   r1, ip, r3, r2
  asr     r3, r3, #31
  rsb     r3, r3, ip, asr #5
  cmp     r0, r3
  movle   r0, #0
  movgt   r0, #1
  pop     {r4, r5, r6, pc}
.flags_L15:
  mov     r0, #0
  pop     {r4, r5, r6, pc}
.flags_L19:
  .word   1374389535
  .word   954437177
  .word   1808407283
draw_star:
  push    {r4, r5, r6, r7, r8, r9, r10, fp, lr}
  sub     sp, sp, #12
  lsl     r7, r2, #1
  cmp     r7, #0
  ble     .flags_L21
  str     r3, [sp, #4]
  mov     r6, r2
  sub     r8, r1, r2
  sub     fp, r7, r2
  add     fp, fp, r1
  sub     r10, r2, r1
  sub     r9, r0, r2
  b       .flags_L23
.flags_L29:
  ldr     r2, [sp, #4]
  mov     r1, r8
  add     r0, r9, r4
  bl      VGA_draw_point_ASM
.flags_L24:
  add     r4, r4, #1
  cmp     r4, r7
  beq     .flags_L28
.flags_L25:
  mov     r2, r6
  mov     r1, r5
  mov     r0, r4
  bl      should_fill_star_pixel
  cmp     r0, #0
  beq     .flags_L24
  b       .flags_L29
.flags_L28:
  add     r8, r8, #1
  cmp     r8, fp
  beq     .flags_L21
.flags_L23:
  add     r5, r10, r8
  mov     r4, #0
  b       .flags_L25
.flags_L21:
  add     sp, sp, #12
  pop     {r4, r5, r6, r7, r8, r9, r10, fp, pc}

input_loop:
  push    {r4, r5, r6, r7, lr}
  sub     sp, sp, #12
  bl      VGA_clear_pixelbuff_ASM
  bl      draw_texan_flag
  mov     r6, #0
  mov     r4, r6
  mov     r5, r6
  ldr     r7, .flags_L52
  b       .flags_L39
.flags_L46:
  bl      draw_real_life_flag
.flags_L39:
  strb    r5, [sp, #7]
  add     r0, sp, #7
  bl      read_PS2_data_ASM
  cmp     r0, #0
  beq     .flags_L39
  cmp     r6, #0
  movne   r6, r5
  bne     .flags_L39
  ldrb    r3, [sp, #7]    @ zero_extendqisi2
  cmp     r3, #240
  moveq   r6, #1
  beq     .flags_L39
  cmp     r3, #28
  subeq   r4, r4, #1
  beq     .flags_L44
  cmp     r3, #35
  addeq   r4, r4, #1
.flags_L44:
  cmp     r4, #0
  blt     .flags_L45
  smull   r2, r3, r7, r4
  sub     r3, r3, r4, asr #31
  add     r3, r3, r3, lsl #1
  sub     r4, r4, r3
  bl      VGA_clear_pixelbuff_ASM
  cmp     r4, #1
  beq     .flags_L46
  cmp     r4, #2
  beq     .flags_L47
  cmp     r4, #0
  bne     .flags_L39
  bl      draw_texan_flag
  b       .flags_L39
.flags_L45:
  bl      VGA_clear_pixelbuff_ASM
.flags_L47:
  bl      draw_imaginary_flag
  mov     r4, #2
  b       .flags_L39
.flags_L52:
  .word   1431655766