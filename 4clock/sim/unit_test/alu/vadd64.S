vadd_e64m8:
    li              t0, 8
    li              t1, 10
    vsetvli         x0, t0, e64, m8, tu, mu
    vmv.v.i         v0, 1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vse64.v         v0, (s0)
    addi            s0, s0, 64

vadd_e64m4:
    li              t0, 4
    li              t1, 15
    vsetvli         x0, t0, e64, m4, tu, mu
    vmv.v.i         v0, 3
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vse64.v         v0, (s0)
    addi            s0, s0, 32

vadd_e64m2:
    li              t0, 2
    li              t1, 20
    vsetvli         x0, t0, e64, m2, tu, mu
    vmv.v.i         v0, 5
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vse64.v         v0, (s0)
    addi            s0, s0, 16

vadd_e64m1:
    li              t0, 1
    li              t1, 0xfffffffa
    vsetvli         x0, t0, e64, m1, tu, mu
    vmv.v.i         v0, 5
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vse64.v         v0, (s0)
    addi            s0, s0, 8


golden:
    00000033
    00000000
    00000033
    00000000
    00000033
    00000000
    00000033
    00000000
    00000033
    00000000
    00000033
    00000000
    00000033
    00000000
    00000033
    00000000

    0000004e
    00000000
    0000004e
    00000000
    0000004e
    00000000
    0000004e
    00000000

    00000069
    00000000
    00000069
    00000000

    ffffffe7
    ffffffff
