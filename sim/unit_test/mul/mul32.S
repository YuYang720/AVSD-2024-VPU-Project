vmul_e32m2:
    la              a0, vdata_start
    li              t0, 4
    vsetvli         x0, t0, e32, m2, tu, mu
    vmv.v.i         v8 , 0
    li              t0,  2
    vle32.v         v8, (a0)
    vmul.vx         v0, v8, t0
    vse32.v         v0, (s0)
    addi            s0, s0, 16

golden:
    60402000
    e0c0a080
    61412100
    e1c1a180