vrsub_e8m1:
    li              t0, 6
    vsetvli         x0, t0, e8, m1, tu, mu
    li              t1, 0xffffffff # -1
    vmv.v.i         v0, 0
    vrsub.vi        v0, v0, 2
    vrsub.vx        v0, v0, t1
    vse8.v          v0, (s0)
    addi            s0, s0, 8

golden:
    fdfdfdfd
    0000fdfd