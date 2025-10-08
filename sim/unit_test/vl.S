vl: 
    li              t0, 6
    vsetvli         t0, t0, e32,m4,tu,mu
    csrr            t0, vl
    vmv.v.x         v0, t0
    vse32.v         v0, (s0)
    addi            s0, s0, 52