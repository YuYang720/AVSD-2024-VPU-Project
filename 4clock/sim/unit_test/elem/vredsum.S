vredsum:
    la              a0, vdata_start
    li              t0, 3
    li              t1, 30
    vsetvli         x0, t0, e16, m2, tu, mu
    vle16.v         v8, (a0)
    vmv.v.x         v0, t1
    vredsum.vs      v0, v8, v0
    vse16.v         v0, (s0)
    addi            s0, s0, 4

golden:
    001e907e
    0000001e
