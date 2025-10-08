vor_e8m2:
    la              a0, vdata_start
    li              t0, 12
    vsetvli         x0, t0, e8, m2, tu, mu
    li              t0, 6
    vmv.v.i         v0, 7
    vle8.v          v2, (a0)
    vor.vv          v0, v2, v0
    vor.vx          v0, v0, t0
    vor.vi          v0, v0, 15
    vse8.v          v0, (s0)
    addi            s0, s0, 12

golden:
    3f2f1f0f
    7f6f5f4f
    bfaf9f8f