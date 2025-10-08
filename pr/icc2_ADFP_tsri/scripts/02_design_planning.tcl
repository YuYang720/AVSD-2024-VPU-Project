set_host_options -max_cores 16



initialize_floorplan -honor_pad_limit -core_offset {233.864} -core_utilization 1.0
create_io_ring -name ioring -corner_height 78.864

source -echo ../scripts/create_corner_pad.tcl


source -echo ../scripts/create_power_pad.tcl

set_signal_io_constraints -io_guide_object ioring.left -constraint {{order_only}
opad_DRAM_CSn
opad_DRAM_WEn0
opad_DRAM_WEn1
opad_DRAM_WEn2
opad_DRAM_WEn3
opad_DRAM_RASn
opad_DRAM_CASn
opad_DRAM_A0
opad_DRAM_A1
opad_DRAM_A2
opad_DRAM_A3
opad_DRAM_A4
opad_DRAM_A5
opad_DRAM_A6
opad_DRAM_A7
opad_DRAM_A8
opad_DRAM_A9
opad_DRAM_A10
io_power1
core_power1
opad_ROM_read
opad_ROM_enable
opad_ROM_A0
opad_ROM_A1
opad_ROM_A2
opad_ROM_A3
opad_ROM_A4
opad_ROM_A5
opad_ROM_A6
opad_ROM_A7
opad_ROM_A8
opad_ROM_A9
opad_ROM_A10
opad_ROM_A11
}
set_signal_io_constraints -io_guide_object ioring.top -constraint {{order_only}
ipad_cpu_clk
ipad_wdt_clk
ipad_cpu_rst
ipad_wdt_rst
io_power2
core_power2
ipad_DRAM_valid
ipad_DRAM_Q0
ipad_DRAM_Q1
ipad_DRAM_Q2
ipad_DRAM_Q3
ipad_DRAM_Q4
ipad_DRAM_Q5
ipad_DRAM_Q6
ipad_DRAM_Q7
ipad_DRAM_Q8
ipad_DRAM_Q9
ipad_DRAM_Q10
ipad_DRAM_Q11
ipad_DRAM_Q12
ipad_DRAM_Q13
ipad_DRAM_Q14
ipad_DRAM_Q15
ipad_DRAM_Q16
ipad_DRAM_Q17
ipad_DRAM_Q18
ipad_DRAM_Q19
ipad_DRAM_Q20
ipad_DRAM_Q21
ipad_DRAM_Q22
ipad_DRAM_Q23
ipad_DRAM_Q24
ipad_DRAM_Q25
ipad_DRAM_Q26
ipad_DRAM_Q27
ipad_DRAM_Q28
ipad_DRAM_Q29
ipad_DRAM_Q30
ipad_DRAM_Q31
}
set_signal_io_constraints -io_guide_object ioring.right -constraint {{order_only}
ipad_ROM_out0
ipad_ROM_out1
ipad_ROM_out2
ipad_ROM_out3
ipad_ROM_out4
ipad_ROM_out5
ipad_ROM_out6
ipad_ROM_out7
ipad_ROM_out8
ipad_ROM_out9
ipad_ROM_out10
ipad_ROM_out11
ipad_ROM_out12
ipad_ROM_out13
ipad_ROM_out14
ipad_ROM_out15
core_power3
io_power3
ipad_ROM_out16
ipad_ROM_out17
ipad_ROM_out18
ipad_ROM_out19
ipad_ROM_out20
ipad_ROM_out21
ipad_ROM_out22
ipad_ROM_out23
ipad_ROM_out24
ipad_ROM_out25
ipad_ROM_out26
ipad_ROM_out27
ipad_ROM_out28
ipad_ROM_out29
ipad_ROM_out30
ipad_ROM_out31
}
set_signal_io_constraints -io_guide_object ioring.bottom -constraint {{order_only}
opad_DRAM_D0
opad_DRAM_D1
opad_DRAM_D2
opad_DRAM_D3
opad_DRAM_D4
opad_DRAM_D5
opad_DRAM_D6
opad_DRAM_D7
opad_DRAM_D8
opad_DRAM_D9
opad_DRAM_D10
opad_DRAM_D11
opad_DRAM_D12
opad_DRAM_D13
opad_DRAM_D14
opad_DRAM_D15
io_power4
core_power4
opad_DRAM_D16
opad_DRAM_D17
opad_DRAM_D18
opad_DRAM_D19
opad_DRAM_D20
opad_DRAM_D21
opad_DRAM_D22
opad_DRAM_D23
opad_DRAM_D24
opad_DRAM_D25
opad_DRAM_D26
opad_DRAM_D27
opad_DRAM_D28
opad_DRAM_D29
opad_DRAM_D30
opad_DRAM_D31
}


initialize_floorplan -honor_pad_limit -core_offset {233.864} -core_utilization 1.0
create_io_ring -name ioring -corner_height 78.864

source -echo ../scripts/create_corner_pad.tcl

set_signal_io_constraints -io_guide_object ioring.left -constraint {{order_only}
opad_DRAM_CSn
opad_DRAM_WEn0
opad_DRAM_WEn1
opad_DRAM_WEn2
opad_DRAM_WEn3
opad_DRAM_RASn
opad_DRAM_CASn
opad_DRAM_A0
opad_DRAM_A1
opad_DRAM_A2
opad_DRAM_A3
opad_DRAM_A4
opad_DRAM_A5
opad_DRAM_A6
opad_DRAM_A7
opad_DRAM_A8
opad_DRAM_A9
opad_DRAM_A10
io_power1
core_power1
opad_ROM_read
opad_ROM_enable
opad_ROM_A0
opad_ROM_A1
opad_ROM_A2
opad_ROM_A3
opad_ROM_A4
opad_ROM_A5
opad_ROM_A6
opad_ROM_A7
opad_ROM_A8
opad_ROM_A9
opad_ROM_A10
opad_ROM_A11
}
set_signal_io_constraints -io_guide_object ioring.top -constraint {{order_only}
ipad_cpu_clk
ipad_wdt_clk
ipad_cpu_rst
ipad_wdt_rst
io_power2
core_power2
ipad_DRAM_valid
ipad_DRAM_Q0
ipad_DRAM_Q1
ipad_DRAM_Q2
ipad_DRAM_Q3
ipad_DRAM_Q4
ipad_DRAM_Q5
ipad_DRAM_Q6
ipad_DRAM_Q7
ipad_DRAM_Q8
ipad_DRAM_Q9
ipad_DRAM_Q10
ipad_DRAM_Q11
ipad_DRAM_Q12
ipad_DRAM_Q13
ipad_DRAM_Q14
ipad_DRAM_Q15
ipad_DRAM_Q16
ipad_DRAM_Q17
ipad_DRAM_Q18
ipad_DRAM_Q19
ipad_DRAM_Q20
ipad_DRAM_Q21
ipad_DRAM_Q22
ipad_DRAM_Q23
ipad_DRAM_Q24
ipad_DRAM_Q25
ipad_DRAM_Q26
ipad_DRAM_Q27
ipad_DRAM_Q28
ipad_DRAM_Q29
ipad_DRAM_Q30
ipad_DRAM_Q31
}
set_signal_io_constraints -io_guide_object ioring.right -constraint {{order_only}
ipad_ROM_out0
ipad_ROM_out1
ipad_ROM_out2
ipad_ROM_out3
ipad_ROM_out4
ipad_ROM_out5
ipad_ROM_out6
ipad_ROM_out7
ipad_ROM_out8
ipad_ROM_out9
ipad_ROM_out10
ipad_ROM_out11
ipad_ROM_out12
ipad_ROM_out13
ipad_ROM_out14
ipad_ROM_out15
core_power3
io_power3
ipad_ROM_out16
ipad_ROM_out17
ipad_ROM_out18
ipad_ROM_out19
ipad_ROM_out20
ipad_ROM_out21
ipad_ROM_out22
ipad_ROM_out23
ipad_ROM_out24
ipad_ROM_out25
ipad_ROM_out26
ipad_ROM_out27
ipad_ROM_out28
ipad_ROM_out29
ipad_ROM_out30
ipad_ROM_out31
}
set_signal_io_constraints -io_guide_object ioring.bottom -constraint {{order_only}
opad_DRAM_D0
opad_DRAM_D1
opad_DRAM_D2
opad_DRAM_D3
opad_DRAM_D4
opad_DRAM_D5
opad_DRAM_D6
opad_DRAM_D7
opad_DRAM_D8
opad_DRAM_D9
opad_DRAM_D10
opad_DRAM_D11
opad_DRAM_D12
opad_DRAM_D13
opad_DRAM_D14
opad_DRAM_D15
io_power4
core_power4
opad_DRAM_D16
opad_DRAM_D17
opad_DRAM_D18
opad_DRAM_D19
opad_DRAM_D20
opad_DRAM_D21
opad_DRAM_D22
opad_DRAM_D23
opad_DRAM_D24
opad_DRAM_D25
opad_DRAM_D26
opad_DRAM_D27
opad_DRAM_D28
opad_DRAM_D29
opad_DRAM_D30
opad_DRAM_D31
}

#DRC: spacing between bump must >= 90um
#bump size 84x84 um2
#delta: 84 + 90 = 174 um
create_bump_array -lib_cell PAD80APB_LF_BU -delta {120 120} -origin {79.104 79.104}

place_io

create_io_filler_cells -reference_cells {PFILLER10080 PFILLER01008 PFILLER00048 PFILLER00001} -overlap_cells PFILLER00001


set io_insts [get_cells -hier -filter "is_io==true"]
set_fixed_objects $io_insts

save_block
save_block -as CHIP:die_init.design
save_lib

#macro pad orientation:
# O: R0,  R180, MY,    MX
# x: R90, R270, MYR90, MXR90


set all_macros [get_cells -hierarchical -filter "is_hard_macro && !is_physical_only"]
create_keepout_margin -type hard -outer {3 3 3 3} $all_macros
create_keepout_margin -type hard_macro -outer {10 10 10 10} $all_macros
create_keepout_margin -type routing_blockage -outer {1 1 1 1} -layers {M4 M5} $all_macros

set_app_options -name place.coarse.fix_hard_macros -value false

source ../scripts/macro_app_options.tcl

create_placement -floorplan
set_fixed_objects $all_macros

source ../scripts/create_boundary_cells.tcl
source ../scripts/create_tap_cells.tcl

set_app_options -name place.coarse.continue_on_missing_scandef -value true
create_placement -incremental

save_block
save_block -as CHIP:before_pns.design
save_lib

source -echo ../scripts/pns.tcl
create_placement -incremental


save_block
save_block -as CHIP:design_planning.design
save_lib

write_floorplan -net_types {power ground} \
   -include_physical_status {fixed locked} \
   -force -output CHIP_icc2.fp