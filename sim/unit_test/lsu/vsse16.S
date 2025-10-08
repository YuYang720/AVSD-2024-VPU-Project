vsse16_e16m1:
    li              t0, 3
    vsetvli         x0, t0, e16, m1, tu, mu
    li              t1, 0xffffffff # -1
    li              t2, 4
    vmv.v.i         v0, 5
    vadd.vx         v0, v0, t1
    vsse16.v         v0, (s0), t2
    addi            s0, s0, 20

golden:
    00000004
    00000000
    00000004
    00000000
    00000004
