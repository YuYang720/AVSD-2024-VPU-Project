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

golden:
    00201000

    30201000
    00005040

    30201000
    70605040

    30201000
