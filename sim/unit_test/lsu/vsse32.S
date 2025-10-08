vsse32_e32m1:
    li              t0, 2
    vsetvli         x0, t0, e32, m1, tu, mu
    li              t1, 0xffffffff # -1
    li              t2, 4
    vmv.v.i         v0, 5
    vadd.vx         v0, v0, t1
    vsse32.v        v0, (s0), t2
    addi            s0, s0, 20

golden:
    00000004
    00000000
    00000000
    00000000
    00000004