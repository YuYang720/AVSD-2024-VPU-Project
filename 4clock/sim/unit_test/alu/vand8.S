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

golden:
    06060606
    00000606