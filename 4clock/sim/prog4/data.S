# Define constants
.section .rodata
.align 2

.global frs_pos_0
.global frs_pos_1
.global frs_pos_2
.global frs_neg_0
.global frs_neg_1
.global frs_neg_2

frs_pos_0:
  .float 99.8888
frs_pos_1:
  .float 90.134575
frs_pos_2:
  .float 87.8787
frs_neg_0:
  .float -99.8888
frs_neg_1:
  .float -90.134575
frs_neg_2:
  .float -87.8787

.global Negative_Infinity
.global Negative_Normal
.global Negative_Subnormal
.global Negative_Zero
.global Positive_Zero
.global Positive_Subnormal
.global Positive_Normal
.global Positive_Infinity
.global Signaling_NaN
.global Quiet_NaN

Negative_Infinity:
  .word 0xFF800000  # -Infinity
Negative_Normal:
  .word 0x80800000  # Negative Normal
Negative_Subnormal:
  .word 0x80000001  # Negative Subnormal
Negative_Zero:
  .word 0x80000000  # -0.0
Positive_Zero:
  .word 0x00000000  # +0.0
Positive_Subnormal:
  .word 0x00000001  # Positive Subnormal
Positive_Normal:
  .word 0x3F800000  # +1.0
Positive_Infinity:
  .word 0x7F800000  # +Infinity
Signaling_NaN:
  .word 0x7F800001  # Signaling NaN
Quiet_NaN:
  .word 0x7FC00001  # Quiet NaN

.global pos_int_input
.global neg_int_input

pos_int_input:
  .word 0x7FFFFFFF
neg_int_input:
  .word 0x80000000