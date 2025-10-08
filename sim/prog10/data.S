.section .data
.global M
.align 1
M:
    .word 0x0000000c
.global N
.align 1
N:
    .word 0x0000000c
.global F
.align 1
F:
    .word 0x00000003
.global input
.align 1
input:
    .word 0xfffffd01
    .word 0x01feff02
    .word 0xfffefd02
    .word 0x0000ffff

    .word 0xff010303
    .word 0x0203fd03
    .word 0x01fcfcfe
    .word 0x000002fe

    .word 0xfc00fc02
    .word 0xfdfdfdfc
    .word 0x02fefefd
    .word 0x00000103

    .word 0x02fe0303
    .word 0xfe00fefe
    .word 0x01fdfffc
    .word 0x0000fcfe

    .word 0xfdffff01
    .word 0x0300ff00
    .word 0xfcfd01fe
    .word 0x0000fffd

    .word 0xfe01ffff
    .word 0x0102fefe
    .word 0xfc030101
    .word 0x000001ff

    .word 0xfd00fd01
    .word 0x0301fe00
    .word 0xfeff0100
    .word 0x000001fd

    .word 0x01fdfd00
    .word 0xfe00fffd
    .word 0xfefe0202
    .word 0x0000ff01
    
    .word 0x01ff00ff
    .word 0x0203ff01
    .word 0xff01fe01
    .word 0x0000fc02

    .word 0xfefcfefc
    .word 0xfefcfdfe
    .word 0xfffe01ff
    .word 0x0000fffe

    .word 0x00fe00fe
    .word 0x0002ffff
    .word 0x0200fc03
    .word 0x0000fe03

    .word 0xfdfd0000
    .word 0xfdfe0101
    .word 0x03fcff01
    .word 0x0000fd01

    .word 0x0101fcfc
    .word 0x000100ff
    .word 0xfc0200fc
    .word 0x0000fc00

    .word 0x03fe0000
    .word 0x03fc0200
    .word 0xfe01fdff
    .word 0x0000ff03
.global filter
.align 1
filter:
    .word 0x02fc0101
    .word 0xff01fe00
    .word 0x00000000