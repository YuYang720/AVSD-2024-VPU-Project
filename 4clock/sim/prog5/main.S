.section .text
.align  2
.globl  main

main:
    addi    sp, sp, -4
    sw      s0, 0(sp)
    la      s0, _test_start
    # Include test from ../unit_test/alu/vadd8.S
vadd_e8m8:
    li              t0, 34
    vsetvli         x0, t0, e8, m8, tu, mu
    li              t1, 0xffffffff # -1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vse8.v          v0, (s0)
    addi            s0, s0, 36

vadd_e8m4:
    li              t0, 29
    vsetvli         x0, t0, e8, m4, tu, mu
    li              t0, 5
    li              t1, 0xfffffffe # -2
    vadd.vx         v0, v0, t0
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vse8.v          v0, (s0)
    addi            s0, s0, 32

vadd_e8m2:
    li              t0, 16
    vsetvli         x0, t0, e8, m2, tu, mu
    li              t0, 10
    li              t1, 4
    vadd.vx         v0, v0, t0
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vse8.v          v0, (s0)
    addi            s0, s0, 16

vadd_e8m1:
    li              t0, 5
    vsetvli         x0, t0, e8, m1, tu, mu
    li              t0, 0xffffffec
    li              t1, 5
    vadd.vx         v0, v0, t0
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vse8.v          v0, (s0)
    addi            s0, s0, 8

    # Include test from ../unit_test/alu/vadd16.S
vadd_e16m8:
    li              t0, 20
    li              t1, 5
    vsetvli         x0, t0, e16, m8, tu, mu
    vmv.v.i         v0, 2
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vse16.v         v0, (s0)
    addi            s0, s0, 40

vadd_e16m4:
    li              t0, 10
    li              t1, 9
    vsetvli         x0, t0, e16, m4, tu, mu
    vmv.v.i         v0, 2
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vse16.v         v0, (s0)
    addi            s0, s0, 20

vadd_e16m2:
    li              t0, 5
    li              t1, 5
    vsetvli         x0, t0, e16, m2, tu, mu
    vmv.v.i         v0, 8
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vse16.v         v0, (s0)
    addi            s0, s0, 12

vadd_e16m1:
    li              t0, 2
    li              t1, 0xffffffff
    vsetvli         x0, t0, e16, m1, tu, mu
    vmv.v.i         v0, 2
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vse16.v         v0, (s0)
    addi            s0, s0, 4

    # Include test from ../unit_test/alu/vadd32.S
vadd_e32m8:
    li              t0, 20
    li              t1, 5
    vsetvli         x0, t0, e16, m8, tu, mu
    vmv.v.i         v0, 2
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vse16.v         v0, (s0)
    addi            s0, s0, 40

vadd_e32m4:
    li              t0, 10
    li              t1, 9
    vsetvli         x0, t0, e16, m4, tu, mu
    vmv.v.i         v0, 2
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vse16.v         v0, (s0)
    addi            s0, s0, 20

vadd_e32m2:
    li              t0, 5
    li              t1, 5
    vsetvli         x0, t0, e16, m2, tu, mu
    vmv.v.i         v0, 8
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vse16.v         v0, (s0)
    addi            s0, s0, 12

vadd_e32m1:
    li              t0, 2
    li              t1, 0xffffffff
    vsetvli         x0, t0, e16, m1, tu, mu
    vmv.v.i         v0, 2
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vse16.v         v0, (s0)
    addi            s0, s0, 4

    # Include test from ../unit_test/alu/vadd64.S
vadd_e64m8:
    li              t0, 8
    li              t1, 10
    vsetvli         x0, t0, e64, m8, tu, mu
    vmv.v.i         v0, 1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vse64.v         v0, (s0)
    addi            s0, s0, 64

vadd_e64m4:
    li              t0, 4
    li              t1, 15
    vsetvli         x0, t0, e64, m4, tu, mu
    vmv.v.i         v0, 3
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vse64.v         v0, (s0)
    addi            s0, s0, 32

vadd_e64m2:
    li              t0, 2
    li              t1, 20
    vsetvli         x0, t0, e64, m2, tu, mu
    vmv.v.i         v0, 5
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vse64.v         v0, (s0)
    addi            s0, s0, 16

vadd_e64m1:
    li              t0, 1
    li              t1, 0xfffffffa
    vsetvli         x0, t0, e64, m1, tu, mu
    vmv.v.i         v0, 5
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vse64.v         v0, (s0)
    addi            s0, s0, 8

    # Include test from ../unit_test/alu/vsub8.S
vsub_e8m1:
    li              t0, 6
    vsetvli         x0, t0, e8, m1, tu, mu
    li              t1, 0xffffffff # -1
    vmv.v.i         v0, 0
    vmv.v.i         v1, 0
    vsub.vx         v0, v0, t1
    vsub.vx         v1, v1, t1
    vsub.vv         v1, v1, v0
    vsub.vx         v1, v1, t1
    vse8.v          v1, (s0)
    addi            s0, s0, 8

    # Include test from ../unit_test/alu/vsub16.S
vsub_e16m8:
    li              t0, 16
    li              t1, 20
    vsetvli         x0, t0, e16, m8, tu, mu
    vmv.v.i         v0, 10
    vmv.v.i         v8, 5
    vsub.vv         v0, v0, v8
    vsub.vx         v0, v0, t1
    vse16.v         v0, (s0)
    addi            s0, s0, 32

vsub_e16m4:
    li              t0, 8
    li              t1, 30
    vsetvli         x0, t0, e16, m4, tu, mu
    vmv.v.i         v0, 2
    vmv.v.i         v8, 7
    vsub.vv         v0, v0, v8
    vsub.vx         v0, v0, t1
    vse16.v         v0, (s0)
    addi            s0, s0, 16

vsub_e16m2:
    li              t0, 4
    li              t1, 15
    vsetvli         x0, t0, e16, m2, tu, mu
    vmv.v.i         v0, 3
    vmv.v.i         v8, 10
    vsub.vv         v0, v0, v8
    vsub.vx         v0, v0, t1
    vse16.v         v0, (s0)
    addi            s0, s0, 8

vsub_e16m1:
    li              t0, 2
    li              t1, 0xffffffff # -1
    vsetvli         x0, t0, e16, m1, tu, mu
    vmv.v.i         v0, 0
    vmv.v.i         v1, 0
    vsub.vx         v0, v0, t1
    vsub.vx         v1, v1, t1
    vsub.vv         v1, v1, v0
    vsub.vx         v1, v1, t1
    vse16.v         v1, (s0)
    addi            s0, s0, 4

    # Include test from ../unit_test/alu/vsub32.S
vsub_e32m1:
    li              t0, 2
    li              t1, 0xffffffff # -1
    vsetvli         x0, t0, e32, m1, tu, mu
    vmv.v.i         v0, 0
    vmv.v.i         v1, 0
    vsub.vx         v0, v0, t1
    vsub.vx         v1, v1, t1
    vsub.vv         v1, v1, v0
    vsub.vx         v1, v1, t1
    vse32.v         v1, (s0)
    addi            s0, s0, 8

    # Include test from ../unit_test/alu/vsub64.S
vsub_e64m1:
    li              t0, 1
    li              t1, 0xffffffff# -1
    vsetvli         x0, t0, e64, m1, tu, mu
    vmv.v.i         v0, 0
    vmv.v.i         v1, 0
    vsub.vx         v0, v0, t1
    vsub.vx         v1, v1, t1
    vsub.vv         v1, v1, v0
    vsub.vx         v1, v1, t1
    vse64.v         v1, (s0)
    addi            s0, s0, 8

    # Include test from ../unit_test/alu/vrsub8.S
vrsub_e8m1:
    li              t0, 6
    vsetvli         x0, t0, e8, m1, tu, mu
    li              t1, 0xffffffff # -1
    vmv.v.i         v0, 0
    vrsub.vi        v0, v0, 2
    vrsub.vx        v0, v0, t1
    vse8.v          v0, (s0)
    addi            s0, s0, 8

    # Include test from ../unit_test/alu/vrsub16.S
vrsub_e16m1:
    li              t0, 3
    vsetvli         x0, t0, e16, m1, tu, mu
    li              t1, 0xffffffff # -1
    vmv.v.i         v0, 0
    vrsub.vi        v0, v0, 2
    vrsub.vx        v0, v0, t1
    vse16.v          v0, (s0)
    addi            s0, s0, 8

    # Include test from ../unit_test/alu/vrsub32.S
vrsub_e32m1:
    li              t0, 2
    vsetvli         x0, t0, e32, m1, tu, mu
    li              t1, 0xffffffff # -1
    vmv.v.i         v0, 0
    vrsub.vi        v0, v0, 2
    vrsub.vx        v0, v0, t1
    vse32.v         v0, (s0)
    addi            s0, s0, 8

    # Include test from ../unit_test/alu/vrsub64.S
vrsub_e64m1:
    li              t0, 1
    vsetvli         x0, t0, e64, m1, tu, mu
    li              t1, 0xffffffff # -1
    vmv.v.i         v0, 0
    vrsub.vi        v0, v0, 2
    vrsub.vx        v0, v0, t1
    vse64.v         v0, (s0)
    addi            s0, s0, 8

    # Include test from ../unit_test/alu/vand8.S
vand_e8m1:
    li              t0, 6
    vsetvli         x0, t0, e8, m1, tu, mu
    li              t0, 6
    vmv.v.i         v0, 7
    vmv.v.i         v1, 7
    vand.vv         v0, v1, v0
    vand.vx         v0, v0, t0
    vand.vi         v0, v0, 15
    vse8.v          v0, (s0)
    addi            s0, s0, 8

    # Include test from ../unit_test/alu/vand16.S
vand_e16m1:
    li              t0, 4
    vsetvli         x0, t0, e16, m1, tu, mu
    li              t0, 6
    vmv.v.i         v0, 7
    vmv.v.i         v1, 7
    vand.vv         v0, v1, v0
    vand.vx         v0, v0, t0
    vand.vi         v0, v0, 15
    vse16.v          v0, (s0)
    addi            s0, s0, 8

    # Include test from ../unit_test/alu/vand32.S
vand_e32m1:
    li              t0, 2
    vsetvli         x0, t0, e32, m1, tu, mu
    li              t0, 6
    vmv.v.i         v0, 7
    vmv.v.i         v1, 7
    vand.vv         v0, v1, v0
    vand.vx         v0, v0, t0
    vand.vi         v0, v0, 15
    vse32.v          v0, (s0)
    addi            s0, s0, 8

    # Include test from ../unit_test/alu/vand64.S
vand_e64m1:
    li              t0, 1
    vsetvli         x0, t0, e64, m1, tu, mu
    li              t0, 6
    vmv.v.i         v0, 7
    vmv.v.i         v1, 7
    vand.vv         v0, v1, v0
    vand.vx         v0, v0, t0
    vand.vi         v0, v0, 15
    vse64.v         v0, (s0)
    addi            s0, s0, 8

    # Include test from ../unit_test/alu/vor8.S
vor_e8m2:
    la              a0, vdata_start
    li              t0, 12
    vsetvli         x0, t0, e8, m2, tu, mu
    li              t0, 6
    vmv.v.i         v0, 7
    vle8.v          v2, (a0)
    vor.vv          v0, v2, v0
    vor.vx          v0, v0, t0
    vor.vi          v0, v0, 15
    vse8.v          v0, (s0)
    addi            s0, s0, 12

    # Include test from ../unit_test/alu/vor16.S
vor_e16m1:
    la              a0, vdata_start
    li              t0, 4
    vsetvli         x0, t0, e16, m1, tu, mu
    li              t0, 6
    vmv.v.i         v0, 7
    vle8.v          v2, (a0)
    vor.vv          v0, v2, v0
    vor.vx          v0, v0, t0
    vor.vi          v0, v0, 15
    vse16.v         v0, (s0)
    addi            s0, s0, 8

    # Include test from ../unit_test/alu/vor32.S
vor_e32m1:
    la              a0, vdata_start
    li              t0, 2
    vsetvli         x0, t0, e32, m1, tu, mu
    li              t0, 6
    vmv.v.i         v0, 7
    vle8.v          v2, (a0)
    vor.vv          v0, v2, v0
    vor.vx          v0, v0, t0
    vor.vi          v0, v0, 15
    vse32.v         v0, (s0)
    addi            s0, s0, 8

    # Include test from ../unit_test/alu/vor64.S
vor_e64m1:
    la              a0, vdata_start
    li              t0, 1
    vsetvli         x0, t0, e64, m1, tu, mu
    li              t0, 6
    vmv.v.i         v0, 7
    vle8.v          v2, (a0)
    vor.vv          v0, v2, v0
    vor.vx          v0, v0, t0
    vor.vi          v0, v0, 15
    vse64.v         v0, (s0)
    addi            s0, s0, 8

    # Include test from ../unit_test/alu/vxor8.S
vxor_e8m1:
    li              t0, 6
    vsetvli         x0, t0, e8, m1, tu, mu
    li              t0, 6
    vmv.v.i         v0, 7
    vmv.v.i         v1, 7
    vxor.vv         v0, v1, v0
    vxor.vx         v0, v0, t0
    vxor.vi         v0, v0, 15
    vse8.v          v0, (s0)
    addi            s0, s0, 8

    # Include test from ../unit_test/alu/vxor16.S
vxor_e16m1:
    li              t0, 4
    vsetvli         x0, t0, e16, m1, tu, mu
    li              t0, 6
    vmv.v.i         v0, 7
    vmv.v.i         v1, 7
    vxor.vv         v0, v1, v0
    vxor.vx         v0, v0, t0
    vxor.vi         v0, v0, 15
    vse16.v         v0, (s0)
    addi            s0, s0, 8

    # Include test from ../unit_test/alu/vxor32.S
vxor_e32m1:
    li              t0, 2
    vsetvli         x0, t0, e32, m1, tu, mu
    li              t0, 6
    vmv.v.i         v0, 7
    vmv.v.i         v1, 7
    vxor.vv         v0, v1, v0
    vxor.vx         v0, v0, t0
    vxor.vi         v0, v0, 15
    vse32.v         v0, (s0)
    addi            s0, s0, 8

    # Include test from ../unit_test/alu/vxor64.S
vxor_e64m1:
    li              t0, 1
    vsetvli         x0, t0, e64, m1, tu, mu
    li              t0, 6
    vmv.v.i         v0, 7
    vmv.v.i         v1, 7
    vxor.vv         v0, v1, v0
    vxor.vx         v0, v0, t0
    vxor.vi         v0, v0, 15
    vse64.v         v0, (s0)
    addi            s0, s0, 8

    # Include test from ../unit_test/alu/vmin8.S
vmin_e8m1:
    li              t0, 2
    vsetvli         x0, t0, e8, m1, tu, mu
    vmv.v.i         v0, 5
    vmv.v.i         v1, 7
    vmin.vv         v0, v1, v0
    vse8.v          v0, (s0)
    addi            s0, s0, 4

    # Include test from ../unit_test/alu/vmin16.S
vmin_e16m1:
    li              t0, 2
    vsetvli         x0, t0, e16, m1, tu, mu
    vmv.v.i         v0, 5
    vmv.v.i         v1, 7
    vmin.vv         v0, v1, v0
    vse16.v         v0, (s0)
    addi            s0, s0, 4

    # Include test from ../unit_test/alu/vmin32.S
vmin_e32m1:
    li              t0, 2
    vsetvli         x0, t0, e32, m1, tu, mu
    vmv.v.i         v0, 5
    vmv.v.i         v1, 7
    vmin.vv         v0, v1, v0
    vse32.v         v0, (s0)
    addi            s0, s0, 8

    # Include test from ../unit_test/alu/vmin64.S
vmin_e64m1:
    li              t0, 1
    vsetvli         x0, t0, e64, m1, tu, mu
    vmv.v.i         v0, 5
    vmv.v.i         v1, 7
    vmin.vv         v0, v1, v0
    vse64.v         v0, (s0)
    addi            s0, s0, 8

    # Include test from ../unit_test/alu/vmax8.S
vmax_e8m1:
    li              t0, 2
    vsetvli         x0, t0, e8, m1, tu, mu
    vmv.v.i         v0, 5
    vmv.v.i         v1, 7
    vmax.vv         v0, v1, v0
    vse8.v          v0, (s0)
    addi            s0, s0, 4

    # Include test from ../unit_test/alu/vmax16.S
vmax_e16m1:
    li              t0, 2
    vsetvli         x0, t0, e16, m1, tu, mu
    vmv.v.i         v0, 5
    vmv.v.i         v1, 7
    vmax.vv         v0, v1, v0
    vse16.v         v0, (s0)
    addi            s0, s0, 4

    # Include test from ../unit_test/alu/vmax32.S
vmax_e32m1:
    li              t0, 2
    vsetvli         x0, t0, e32, m1, tu, mu
    vmv.v.i         v0, 5
    vmv.v.i         v1, 7
    vmax.vv         v0, v1, v0
    vse32.v         v0, (s0)
    addi            s0, s0, 8

    # Include test from ../unit_test/alu/vmax64.S
vmax_e64m1:
    li              t0, 1
    vsetvli         x0, t0, e64, m1, tu, mu
    vmv.v.i         v0, 7
    vmv.v.i         v1, 7
    vmax.vv         v0, v1, v0
    vse64.v         v0, (s0)
    addi            s0, s0, 8

    # Include test from ../unit_test/mul/mul16.S
vmul_e16m1:
    li              t0, 3
    vsetvli         x0, t0, e16, m1, tu, mu
    li              t1, 0xffffffff # -1
    vmv.v.i         v0, 2
    vmul.vx         v0, v0, t1
    vse16.v         v0, (s0)
    addi            s0, s0, 8

    # Include test from ../unit_test/mul/mul32.S
vmul_e32m2:
    la              a0, vdata_start
    li              t0, 4
    vsetvli         x0, t0, e32, m2, tu, mu
    vmv.v.i         v8 , 0
    li              t0,  2
    vle32.v         v8, (a0)
    vmul.vx         v0, v8, t0
    vse32.v         v0, (s0)
    addi            s0, s0, 16

    # Include test from ../unit_test/mul/mul64.S
vmul_e64m2:
    la              a0, vdata_start
    li              t0, 2
    vsetvli         x0, t0, e64, m2, tu, mu
    vmv.v.i         v8 , 0
    li              t0,  2
    vle64.v         v8, (a0)
    vmul.vx         v0, v8, t0
    vse64.v         v0, (s0)
    addi            s0, s0, 16

    # Include test from ../unit_test/mul/mulh8.S
vmul_e8m1:
    li              t0, 6
    vsetvli         x0, t0, e8, m1, tu, mu
    li              t1, 0xffffffff # -1
    vmv.v.i         v0, 2
    vmulh.vx        v0, v0, t1
    vse8.v          v0, (s0)
    addi            s0, s0, 8

    # Include test from ../unit_test/mul/mulh16.S
vmulh_e16m1:
    li              t0, 3
    vsetvli         x0, t0, e16, m1, tu, mu
    li              t1, 0xffffffff # -1
    vmv.v.i         v0, 2
    vmulh.vx        v0, v0, t1
    vse16.v         v0, (s0)
    addi            s0, s0, 8

    # Include test from ../unit_test/mul/mulh32.S
vmulh_e32m2:
    la              a0, vdata_start
    li              t0, 4
    vsetvli         x0, t0, e32, m2, tu, mu
    vmv.v.i         v8 , 0
    li              t0,  2
    vle32.v         v8, (a0)
    vmulh.vx        v0, v8, t0
    vse32.v         v0, (s0)
    addi            s0, s0, 16

    # Include test from ../unit_test/mul/mulh64.S
vmulh_e64m2:
    la              a0, vdata_start
    li              t0, 2
    vsetvli         x0, t0, e64, m2, tu, mu
    vmv.v.i         v8 , 0
    li              t0,  2
    vle64.v         v8, (a0)
    vmulh.vx        v0, v8, t0
    vse64.v         v0, (s0)
    addi            s0, s0, 16

    # Include test from ../unit_test/sld/vslidedown.S
vslidedown_e8m2:
    la              a0, vdata_start
    li              t0, 16
    vsetvli         x0, t0, e8, m2, tu, mu
    vle8.v          v4, (a0)
    li              t0, 5
    vslidedown.vx   v4, v4, t0
    vse8.v          v4, (s0)
    addi            s0, s0, 16

vslidedown_e32m2:
    la              a0, vdata_start
    li              t0, 4
    vsetvli         x0, t0, e32, m2, tu, mu
    vle32.v         v4, (a0)
    vslidedown.vi   v4, v4, 2
    vse32.v         v4, (s0)
    addi            s0, s0, 16

vslide1down_e32m2:
    la              a0, vdata_start
    li              t0, 4
    li              t1, 5
    vsetvli         x0, t0, e32, m2, tu, mu
    vle32.v         v4, (a0)
    vslide1down.vx  v4, v4, t1
    vse32.v         v4, (s0)
    addi            s0, s0, 16

    # Include test from ../unit_test/sld/vslideup.S
vslideup_e8m2:
    la              a0, vdata_start
    li              t0, 16
    vsetvli         x0, t0, e8, m2, tu, mu
    vle8.v          v4, (a0)
    li              t0, 5
    vslideup.vx     v4, v4, t0
    vse8.v          v4, (s0)
    addi            s0, s0, 16

vslideup_e32m2:
    la              a0, vdata_start
    li              t0, 4
    vsetvli         x0, t0, e32, m2, tu, mu
    vle32.v         v4, (a0)
    vslideup.vi     v4, v4, 2
    vse32.v         v4, (s0)
    addi            s0, s0, 16

vslide1up_e32m2:
    la              a0, vdata_start
    li              t0, 4
    li              t1, 5
    vsetvli         x0, t0, e32, m2, tu, mu
    vle32.v         v4, (a0)
    vslide1up.vx    v4, v4, t1
    vse32.v         v4, (s0)
    addi            s0, s0, 16

    # Include test from ../unit_test/alu/vsll.S
vsll_e16m1:
    la              a0, vdata_start
    li              t0, 4
    vsetvli         x0, t0, e16, m1, tu, mu
    li              t0, 6
    vmv.v.i         v0, 7
    vle16.v         v2, (a0)
    vsll.vv         v0, v2, v0
    vse16.v         v0, (s0)
    addi            s0, s0, 8

    # Include test from ../unit_test/alu/vsra.S
vsra_e16m1:
    la              a0, vdata_start
    li              t0, 4
    vsetvli         x0, t0, e16, m1, tu, mu
    li              t0, 6
    vmv.v.i         v0, 7
    vle16.v         v2, (a0)
    vsra.vv         v0, v2, v0
    vse16.v         v0, (s0)
    addi            s0, s0, 8

    # Include test from ../unit_test/alu/vsrl.S
vsrl_e16m1:
    la              a0, vdata_start
    li              t0, 4
    vsetvli         x0, t0, e16, m1, tu, mu
    li              t0, 6
    vmv.v.i         v0, 7
    vle16.v         v2, (a0)
    vsrl.vv         v0, v2, v0
    vse16.v         v0, (s0)
    addi            s0, s0, 8

    # Include test from ../unit_test/lsu/vse8.S
vse8_e8m1:
    li              t0, 7
    vsetvli         x0, t0, e8, m1, tu, mu
    li              t1, 0xffffffff # -1
    vmv.v.i         v0, 5
    vadd.vx         v0, v0, t1
    vse8.v          v0, (s0)
    addi            s0, s0, 8

    # Include test from ../unit_test/lsu/vse16.S
vse16_e16m1:
    li              t0, 3
    vsetvli         x0, t0, e16, m1, tu, mu
    li              t1, 0xffffffff # -1
    vmv.v.i         v0, 5
    vadd.vx         v0, v0, t1
    vse16.v         v0, (s0)
    addi            s0, s0, 8

    # Include test from ../unit_test/lsu/vse32.S
vse32_e32m1:
    li              t0, 2
    vsetvli         x0, t0, e32, m1, tu, mu
    li              t1, 0xffffffff # -1
    vmv.v.i         v0, 5
    vadd.vx         v0, v0, t1
    vse32.v         v0, (s0)
    addi            s0, s0, 8

    # Include test from ../unit_test/lsu/vse64.S
vse64_e64m1:
    li              t0, 1
    vsetvli         x0, t0, e64, m1, tu, mu
    li              t1, 0xffffff9d # -99
    vmv.v.i         v0, 5
    vadd.vx         v0, v0, t1
    vse64.v         v0, (s0)
    addi            s0, s0, 8

    # Include test from ../unit_test/lsu/vsse8.S
vsse8_e8m1:
    li              t0, 7
    vsetvli         x0, t0, e8, m1, tu, mu
    li              t1, 0xffffffff # -1
    li              t2, 4
    vmv.v.i         v0, 5
    vadd.vx         v0, v0, t1
    vsse8.v         v0, (s0), t2
    addi            s0, s0, 28

    # Include test from ../unit_test/lsu/vsse16.S
vsse16_e16m1:
    li              t0, 3
    vsetvli         x0, t0, e16, m1, tu, mu
    li              t1, 0xffffffff # -1
    li              t2, 4
    vmv.v.i         v0, 5
    vadd.vx         v0, v0, t1
    vsse16.v         v0, (s0), t2
    addi            s0, s0, 20

    # Include test from ../unit_test/lsu/vsse32.S
vsse32_e32m1:
    li              t0, 2
    vsetvli         x0, t0, e32, m1, tu, mu
    li              t1, 0xffffffff # -1
    li              t2, 4
    vmv.v.i         v0, 5
    vadd.vx         v0, v0, t1
    vsse32.v        v0, (s0), t2
    addi            s0, s0, 20

    # Include test from ../unit_test/lsu/vsse64.S
vsse64_e64m1:
    li              t0, 1
    vsetvli         x0, t0, e64, m1, tu, mu
    li              t1, 0xffffff9d # -99
    li              t2, 4
    vmv.v.i         v0, 5
    vadd.vx         v0, v0, t1
    vsse64.v        v0, (s0), t2
    addi            s0, s0, 8

vsse64_e64m2:
    li              t0, 2
    vsetvli         x0, t0, e64, m2, tu, mu
    li              t1, 0xffffff9d # -99
    li              t2, 4
    vmv.v.i         v0, 5
    vadd.vx         v0, v0, t1
    vsse64.v        v0, (s0), t2
    addi            s0, s0, 40

vsse64_e64m4:
    li              t0, 3
    vsetvli         x0, t0, e64, m4, tu, mu
    li              t1, 0xffffff9d # -99
    li              t2, 4
    vmv.v.i         v0, 5
    vadd.vx         v0, v0, t1
    vsse64.v        v0, (s0), t2
    addi            s0, s0, 72

vsse64_e64m8:
    li              t0, 5
    vsetvli         x0, t0, e64, m8, tu, mu
    li              t1, 0xffffff9d # -99
    li              t2, 4
    vmv.v.i         v0, 5
    vadd.vx         v0, v0, t1
    vsse64.v        v0, (s0), t2
    addi            s0, s0, 160

    # Include test from ../unit_test/lsu/vle.S
vle8_e8m1:
    la              a0, vdata_start
    li              t0, 3
    vsetvli         x0, t0, e8, m1, tu, mu
    vmv.v.i         v8, 0
    vle8.v          v8, (a0)
    vse8.v          v8, (s0)
    addi            s0, s0, 4

vle16_e16m1:
    la              a0, vdata_start
    li              t0, 3
    vsetvli         x0, t0, e16, m1, tu, mu
    vmv.v.i         v8, 0
    vle16.v         v8, (a0)
    vse16.v         v8, (s0)
    addi            s0, s0, 8

vle32_e32m1:
    la              a0, vdata_start
    li              t0, 2
    vsetvli         x0, t0, e32, m1, tu, mu
    vmv.v.i         v8, 0
    vle32.v         v8, (a0)
    vse32.v         v8, (s0)
    addi            s0, s0, 8

vle64_e64m1:
    la              a0, vdata_start
    li              t0, 1
    vsetvli         x0, t0, e64, m1, tu, mu
    vmv.v.i         v8, 0
    vle64.v         v8, (a0)
    vse64.v         v8, (s0)
    addi            s0, s0, 4

    # Include test from ../unit_test/lsu/vlse.S
vle8_e8m2:
    la              a0, vdata_start
    li              t0, 5
    li              t1, 4
    vsetvli         x0, t0, e8, m1, tu, mu
    vmv.v.i         v8, 0
    vlse8.v         v8, (a0), t1
    vse8.v          v8, (s0)
    addi            s0, s0, 8

vle832_e32m2:
    la              a0, vdata_start
    li              t0, 3
    li              t1, 2
    vsetvli         x0, t0, e32, m2, tu, mu
    vmv.v.i         v8, 0
    vlse32.v        v8, (a0), t1
    vse32.v         v8, (s0)
    addi            s0, s0, 12



main_exit:
    lw      s0, 0(sp)
    addi    sp, sp, 4
    ret