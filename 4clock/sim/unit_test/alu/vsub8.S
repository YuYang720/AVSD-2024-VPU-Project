vsub_e8m1:
    li              t0, 6
    vsetvli         x0, t0, e8, m1, tu, mu
    li              t1, 0xffffffff # -1
    vmv.v.i         v0, 0
    vmv.v.i         v1, 0
    vsub.vx         v0, v0, t1
    vsub.vx         v1, v1, t1
    vsub.vv         v1, v1, v0
    vsub.vx         v1, v1, t1
    vse8.v          v1, (s0)
    addi            s0, s0, 8

golden:
    01010101
    00000101