vle8_e8m2:
    la              a0, vdata_start
    li              t0, 5
    li              t1, 4
    vsetvli         x0, t0, e8, m1, tu, mu
    vmv.v.i         v8, 0
    vlse8.v         v8, (a0), t1
    vse8.v          v8, (s0)
    addi            s0, s0, 8

vle832_e32m2:
    la              a0, vdata_start
    li              t0, 3
    li              t1, 2
    vsetvli         x0, t0, e32, m2, tu, mu
    vmv.v.i         v8, 0
    vlse32.v        v8, (a0), t1
    vse32.v         v8, (s0)
    addi            s0, s0, 12

golden:
    c0804000
    00000087

    30201000
    b0a09080
    00000087