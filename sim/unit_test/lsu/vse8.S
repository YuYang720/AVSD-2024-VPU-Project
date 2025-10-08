vse8_e8m1:
    li              t0, 7
    vsetvli         x0, t0, e8, m1, tu, mu
    li              t1, 0xffffffff # -1
    vmv.v.i         v0, 5
    vadd.vx         v0, v0, t1
    vse8.v          v0, (s0)
    addi            s0, s0, 8

golden:
    04040404
    00040404
