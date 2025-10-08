vsse8_e8m1:
    li              t0, 7
    vsetvli         x0, t0, e8, m1, tu, mu
    li              t1, 0xffffffff # -1
    li              t2, 4
    vmv.v.i         v0, 5
    vadd.vx         v0, v0, t1
    vsse8.v         v0, (s0), t2
    addi            s0, s0, 28

golden:
    00000004
    00000004
    00000004
    00000004
    00000004
    00000004
    00000004
