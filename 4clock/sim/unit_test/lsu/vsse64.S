vsse64_e64m1:
    li              t0, 1
    vsetvli         x0, t0, e64, m1, tu, mu
    li              t1, 0xffffff9d # -99
    li              t2, 4
    vmv.v.i         v0, 5
    vadd.vx         v0, v0, t1
    vsse64.v        v0, (s0), t2
    addi            s0, s0, 8

vsse64_e64m2:
    li              t0, 2
    vsetvli         x0, t0, e64, m2, tu, mu
    li              t1, 0xffffff9d # -99
    li              t2, 4
    vmv.v.i         v0, 5
    vadd.vx         v0, v0, t1
    vsse64.v        v0, (s0), t2
    addi            s0, s0, 40

vsse64_e64m4:
    li              t0, 3
    vsetvli         x0, t0, e64, m4, tu, mu
    li              t1, 0xffffff9d # -99
    li              t2, 4
    vmv.v.i         v0, 5
    vadd.vx         v0, v0, t1
    vsse64.v        v0, (s0), t2
    addi            s0, s0, 72

vsse64_e64m8:
    li              t0, 5
    vsetvli         x0, t0, e64, m8, tu, mu
    li              t1, 0xffffff9d # -99
    li              t2, 4
    vmv.v.i         v0, 5
    vadd.vx         v0, v0, t1
    vsse64.v        v0, (s0), t2
    addi            s0, s0, 160

golden:
    ffffffa2
    ffffffff

    ffffffa2
    ffffffff
    00000000
    00000000
    00000000
    00000000
    00000000
    00000000
    ffffffa2
    ffffffff

    ffffffa2
    ffffffff
    00000000
    00000000
    00000000
    00000000
    00000000
    00000000
    ffffffa2
    ffffffff
    00000000
    00000000
    00000000
    00000000
    00000000
    00000000
    ffffffa2
    ffffffff

    ffffffa2
    ffffffff
    00000000
    00000000
    00000000
    00000000
    00000000
    00000000
    ffffffa2
    ffffffff
    00000000
    00000000
    00000000
    00000000
    00000000
    00000000
    ffffffa2
    ffffffff
    00000000
    00000000
    00000000
    00000000
    00000000
    00000000
    ffffffa2
    ffffffff
    00000000
    00000000
    00000000
    00000000
    00000000
    00000000
    ffffffa2
    ffffffff
    00000000
    00000000
    00000000
    00000000
    00000000
    00000000