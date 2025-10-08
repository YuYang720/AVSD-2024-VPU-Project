vse16_e16m1:
    li              t0, 3
    vsetvli         x0, t0, e16, m1, tu, mu
    li              t1, 0xffffffff # -1
    vmv.v.i         v0, 5
    vadd.vx         v0, v0, t1
    vse16.v         v0, (s0)
    addi            s0, s0, 8

golden:
    00040004
    00000004

