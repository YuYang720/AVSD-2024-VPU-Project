vsub_e16m8:
    li              t0, 16
    li              t1, 20
    vsetvli         x0, t0, e16, m8, tu, mu
    vmv.v.i         v0, 10
    vmv.v.i         v8, 5
    vsub.vv         v0, v0, v8
    vsub.vx         v0, v0, t1
    vse16.v         v0, (s0)
    addi            s0, s0, 64

vsub_e16m4:
    li              t0, 8
    li              t1, 30
    vsetvli         x0, t0, e16, m4, tu, mu
    vmv.v.i         v0, 2
    vmv.v.i         v8, 7
    vsub.vv         v0, v0, v8
    vsub.vx         v0, v0, t1
    vse16.v         v0, (s0)
    addi            s0, s0, 32

vsub_e16m2:
    li              t0, 4
    li              t1, 15
    vsetvli         x0, t0, e16, m2, tu, mu
    vmv.v.i         v0, 3
    vmv.v.i         v8, 10
    vsub.vv         v0, v0, v8
    vsub.vx         v0, v0, t1
    vse16.v         v0, (s0)
    addi            s0, s0, 16

vsub_e16m1:
    li              t0, 2
    li              t1, 0xffffffff # -1
    vsetvli         x0, t0, e16, m1, tu, mu
    vmv.v.i         v0, 0
    vmv.v.i         v1, 0
    vsub.vx         v0, v0, t1
    vsub.vx         v1, v1, t1
    vsub.vv         v1, v1, v0
    vsub.vx         v1, v1, t1
    vse16.v         v1, (s0)
    addi            s0, s0, 8

golden:
    fff1fff1
    fff1fff1
    fff1fff1
    fff1fff1
    fff1fff1
    fff1fff1
    fff1fff1
    fff1fff1

    ffddffdd
    ffddffdd
    ffddffdd
    ffddffdd

    ffeaffea
    ffeaffea

    00010001
