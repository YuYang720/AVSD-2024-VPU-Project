vsub_e64m8:
    li              t0, 8
    li              t1, 100
    vsetvli         x0, t0, e64, m8, tu, mu
    vmv.v.i         v0, 10
    vmv.v.i         v8, 6
    vsub.vv         v0, v0, v8
    vsub.vx         v0, v0, t1
    vse64.v         v0, (s0)
    addi            s0, s0, 64

vsub_e64m4:
    li              t0, 4
    li              t1, 200
    vsetvli         x0, t0, e64, m4, tu, mu
    vmv.v.i         v0, 2
    vmv.v.i         v8, 10
    vsub.vv         v0, v0, v8
    vsub.vx         v0, v0, t1
    vse64.v         v0, (s0)
    addi            s0, s0, 32

vsub_e64m2:
    li              t0, 2
    li              t1, 300
    vsetvli         x0, t0, e64, m2, tu, mu
    vmv.v.i         v0, 5
    vmv.v.i         v4, 2
    vsub.vv         v0, v0, v4
    vsub.vx         v0, v0, t1
    vse64.v         v0, (s0)
    addi            s0, s0, 16

vsub_e64m1:
    li              t0, 1
    li              t1, 0xffffffff# -1
    vsetvli         x0, t0, e64, m1, tu, mu
    vmv.v.i         v0, 0
    vmv.v.i         v1, 0
    vsub.vx         v0, v0, t1
    vsub.vx         v1, v1, t1
    vsub.vv         v1, v1, v0
    vsub.vx         v1, v1, t1
    vse64.v         v1, (s0)
    addi            s0, s0, 8

golden:
    ffffffa0
    ffffffff
    ffffffa0
    ffffffff
    ffffffa0
    ffffffff
    ffffffa0
    ffffffff
    ffffffa0
    ffffffff
    ffffffa0
    ffffffff
    ffffffa0
    ffffffff
    ffffffa0
    ffffffff

    ffffff30
    ffffffff
    ffffff30
    ffffffff
    ffffff30
    ffffffff
    ffffff30
    ffffffff

    fffffed7
    ffffffff
    fffffed7
    ffffffff

    00000001
    00000000
