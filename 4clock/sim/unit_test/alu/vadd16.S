vadd_e16m8:
    li              t0, 20
    li              t1, 5
    vsetvli         x0, t0, e16, m8, tu, mu
    vmv.v.i         v0, 2
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vse16.v         v0, (s0)
    addi            s0, s0, 40

vadd_e16m4:
    li              t0, 10
    li              t1, 9
    vsetvli         x0, t0, e16, m4, tu, mu
    vmv.v.i         v0, 2
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vse16.v         v0, (s0)
    addi            s0, s0, 20

vadd_e16m2:
    li              t0, 5
    li              t1, 5
    vsetvli         x0, t0, e16, m2, tu, mu
    vmv.v.i         v0, 8
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vse16.v         v0, (s0)
    addi            s0, s0, 12

vadd_e16m1:
    li              t0, 2
    li              t1, 0xffffffff
    vsetvli         x0, t0, e16, m1, tu, mu
    vmv.v.i         v0, 2
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vadd.vx         v0, v0, t1
    vse16.v         v0, (s0)
    addi            s0, s0, 4

golden:
    001b001b
    001b001b
    001b001b
    001b001b
    001b001b
    001b001b
    001b001b
    001b001b
    001b001b
    001b001b

    002f002f
    002f002f
    002f002f
    002f002f
    002f002f

    00210021
    00210021
    00000021

    fffdfffd