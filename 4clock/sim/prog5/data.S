# Define constants
.section .rodata
.align 2
.global vdata_start
.global vadd64_data

vdata_start:
  .word 0x30201000
  .word 0x70605040
  .word 0xb0a09080
  .word 0xf0e0d0c0
  .word 0x00000087

vadd64_data:
  .word 0x55555555
  .word 0x00005555
  .word 0x12345678
  .word 0x00edcba9

