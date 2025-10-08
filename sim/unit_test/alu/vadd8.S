vadd_e8m8:
    li              t0, 34
    vsetvli         x0, t0, e8, m8, tu, mu
    li              t1, 0xffffffff # -1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vse8.v          v0, (s0)
    addi            s0, s0, 36

vadd_e8m4:
    li              t0, 29
    vsetvli         x0, t0, e8, m4, tu, mu
    li              t0, 5
    li              t1, 0xfffffffe # -2
    vadd.vx         v0, v0, t0
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vse8.v          v0, (s0)
    addi            s0, s0, 32

vadd_e8m2:
    li              t0, 16
    vsetvli         x0, t0, e8, m2, tu, mu
    li              t0, 10
    li              t1, 4
    vadd.vx         v0, v0, t0
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vse8.v          v0, (s0)
    addi            s0, s0, 16

vadd_e8m1:
    li              t0, 5
    vsetvli         x0, t0, e8, m1, tu, mu
    li              t0, 0xffffffec
    li              t1, 5
    vadd.vx         v0, v0, t0
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vse8.v          v0, (s0)
    addi            s0, s0, 8

golden:
    fbfbfbfb
    fbfbfbfb
    fbfbfbfb
    fbfbfbfb
    fbfbfbfb
    fbfbfbfb
    fbfbfbfb
    fbfbfbfb
    0000fbfb

    f6f6f6f6
    f6f6f6f6
    f6f6f6f6
    f6f6f6f6
    f6f6f6f6
    f6f6f6f6
    f6f6f6f6
    000000f6

    14141414
    14141414
    14141414
    14141414
    
    4b4b4b4b
    0000004b