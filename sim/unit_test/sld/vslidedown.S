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

golden:
    80706050
    c0b0a090
    00f0e0d0
    00000000

    b0a09080
    f0e0d0c0
    00000000
    00000000

    70605040
    b0a09080
    f0e0d0c0
    00000005