vse64_e64m1:
    li              t0, 1
    vsetvli         x0, t0, e64, m1, tu, mu
    li              t1, 0xffffff9d # -99
    vmv.v.i         v0, 5
    vadd.vx         v0, v0, t1
    vse64.v         v0, (s0)
    addi            s0, s0, 8

golden:
    ffffffa2
    ffffffff