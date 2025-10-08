create_cell {cornerLL cornerLR cornerUL cornerUR} N16ADFP_StdIO/PCORNER
create_io_corner_cell -cell cornerLL  {ioring.bottom ioring.left}
create_io_corner_cell -cell cornerUL  {ioring.left ioring.top}
create_io_corner_cell -cell cornerUR  {ioring.top ioring.right}
create_io_corner_cell -cell cornerLR  {ioring.right ioring.bottom}
#corner pad orientation:
# O: R0,  R180, MY,    MX
# x: R90, R270, MYR90, MXR90
set_attribute -objects [get_cells cornerLR] -name orientation -value MY
set_attribute -objects [get_cells cornerUL] -name orientation -value MX

