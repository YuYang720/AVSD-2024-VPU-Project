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

golden:
    30201000
    20100040
    60504030
    a0908070

    30201000
    70605040
    30201000
    70605040

    00000005
    30201000
    70605040
    b0a09080