# you can modify it
clear -all
check_cov -init -type all

jasper_scoreboard_3 -init
# include source code
analyze -sv  [glob ../include/AXI_define.svh]
analyze -sv  [glob ../include/def.svh]

analyze -sv  [glob ../sim/data_array/*.sv]
analyze -sv  [glob ../sim/DRAM/DRAM.sv]
analyze -v2k [glob ../sim/ROM/ROM.v]
analyze -sv  [glob ../sim/SRAM/SRAM_rtl.sv]
analyze -sv  [glob ../sim/tag_array/tag_array_rtl.sv]

analyze -sv  [glob ../property/Formal_AXI_top.sv]
analyze -sv  [glob ../src/top.sv]
analyze -sv  [glob ../src/AXI/*.sv]
analyze -sv  [glob ../src/Cache/*.sv]
analyze -sv  [glob ../src/CPU/*.sv]
analyze -sv  [glob ../src/DMA/*.sv]
analyze -sv  [glob ../src/FPU/*.sv]
analyze -sv  [glob ../src/WDT/*.sv]
analyze -sv  [glob ../src/Wrapper/*.sv]
# include assertion property
analyze -sv  [glob ../property/axi.sva]
check_cov -init -exclude_hierarchies {*/_automatic_coveritem*} -regexp

# top module

elaborate -top Formal_AXI_top -bbox_m VPU -bbox_m L1C_data

# set clock and reset signal
clock top_clk
reset top_rst

# icache always hit
#stopat u_TOP.CPU_wrapper.CPU1.i_if_stage.fetch_wait
#assume {u_TOP.CPU_wrapper.CPU1.i_if_stage.fetch_wait == 1'b0}
# no exception
#stopat u_TOP.CPU_wrapper.CPU1.DMA_interrupt_i
#assume {u_TOP.CPU_wrapper.CPU1.DMA_interrupt_i == 1'b0}
#stopat u_TOP.CPU_wrapper.CPU1.WDT_interrupt_i
#assume {u_TOP.CPU_wrapper.CPU1.WDT_interrupt_i == 1'b0}

# always fetch legal instructions at the fetch stage from I-Cache
#stopat u_TOP.CPU_wrapper.CPU1.icache_core_out_i
#
#assume {
#      // Instruction 0
#      (u_TOP.CPU_wrapper.CPU1.icache_core_out_i[6:0] == 7'b0110011 && 
#            (
#                  (u_TOP.CPU_wrapper.CPU1.icache_core_out_i[31:25] == 7'b0000000) ||
#                  (u_TOP.CPU_wrapper.CPU1.icache_core_out_i[31:25] == 7'b0100000 && (u_TOP.CPU_wrapper.CPU1.icache_core_out_i[14:12] == 3'b000 || u_TOP.CPU_wrapper.CPU1.icache_core_out_i[14:12] == 3'b101)) ||
#                  (u_TOP.CPU_wrapper.CPU1.icache_core_out_i[31:25] == 7'b0000001 && (u_TOP.CPU_wrapper.CPU1.icache_core_out_i[14:12] == 3'b000 || u_TOP.CPU_wrapper.CPU1.icache_core_out_i[14:12] == 3'b001 || u_TOP.CPU_wrapper.CPU1.icache_core_out_i[14:12] == 3'b010 || u_TOP.CPU_wrapper.CPU1.icache_core_out_i[14:12] == 3'b011))
#            )
#      ) ||
#      (u_TOP.CPU_wrapper.CPU1.icache_core_out_i[6:0] == 7'b0000011 && 
#            (
#                  u_TOP.CPU_wrapper.CPU1.icache_core_out_i[14:12] == 3'b000 ||
#                  u_TOP.CPU_wrapper.CPU1.icache_core_out_i[14:12] == 3'b001 ||
#                  u_TOP.CPU_wrapper.CPU1.icache_core_out_i[14:12] == 3'b010 ||
#                  u_TOP.CPU_wrapper.CPU1.icache_core_out_i[14:12] == 3'b100 ||
#                  u_TOP.CPU_wrapper.CPU1.icache_core_out_i[14:12] == 3'b101
#            )
#      ) || 
#      (u_TOP.CPU_wrapper.CPU1.icache_core_out_i[6:0] == 7'b0010011 && 
#            (
#                  (u_TOP.CPU_wrapper.CPU1.icache_core_out_i[14:12] == 3'b000 || 
#                   u_TOP.CPU_wrapper.CPU1.icache_core_out_i[14:12] == 3'b010 || 
#                   u_TOP.CPU_wrapper.CPU1.icache_core_out_i[14:12] == 3'b011 || 
#                   u_TOP.CPU_wrapper.CPU1.icache_core_out_i[14:12] == 3'b100 || 
#                   u_TOP.CPU_wrapper.CPU1.icache_core_out_i[14:12] == 3'b110 || 
#                   u_TOP.CPU_wrapper.CPU1.icache_core_out_i[14:12] == 3'b111) || 
#                  (u_TOP.CPU_wrapper.CPU1.icache_core_out_i[14:12] == 3'b001 && u_TOP.CPU_wrapper.CPU1.icache_core_out_i[31:25] == 7'b0000000) || 
#                  (u_TOP.CPU_wrapper.CPU1.icache_core_out_i[14:12] == 3'b101 && (u_TOP.CPU_wrapper.CPU1.icache_core_out_i[31:25] == 7'b0000000 || u_TOP.CPU_wrapper.CPU1.icache_core_out_i[31:25] == 7'b0100000))
#            )
#      ) ||
#      (u_TOP.CPU_wrapper.CPU1.icache_core_out_i[6:0] == 7'b1100111 && u_TOP.CPU_wrapper.CPU1.icache_core_out_i[14:12] == 3'b000) || 
#      (u_TOP.CPU_wrapper.CPU1.icache_core_out_i[6:0] == 7'b0100011 && 
#            (
#                  u_TOP.CPU_wrapper.CPU1.icache_core_out_i[14:12] == 3'b000 || 
#                  u_TOP.CPU_wrapper.CPU1.icache_core_out_i[14:12] == 3'b001 || 
#                  u_TOP.CPU_wrapper.CPU1.icache_core_out_i[14:12] == 3'b010
#            )
#      ) ||
#      (u_TOP.CPU_wrapper.CPU1.icache_core_out_i[6:0] == 7'b1100011 && 
#            (
#                  u_TOP.CPU_wrapper.CPU1.icache_core_out_i[14:12] == 3'b000 || 
#                  u_TOP.CPU_wrapper.CPU1.icache_core_out_i[14:12] == 3'b001 || 
#                  u_TOP.CPU_wrapper.CPU1.icache_core_out_i[14:12] == 3'b100 || 
#                  u_TOP.CPU_wrapper.CPU1.icache_core_out_i[14:12] == 3'b101 || 
#                  u_TOP.CPU_wrapper.CPU1.icache_core_out_i[14:12] == 3'b110 || 
#                  u_TOP.CPU_wrapper.CPU1.icache_core_out_i[14:12] == 3'b111
#            )
#      ) || 
#      (u_TOP.CPU_wrapper.CPU1.icache_core_out_i[6:0] == 7'b0010111) || 
#      (u_TOP.CPU_wrapper.CPU1.icache_core_out_i[6:0] == 7'b0110111) || 
#      (u_TOP.CPU_wrapper.CPU1.icache_core_out_i[6:0] == 7'b1101111) || 
#      (u_TOP.CPU_wrapper.CPU1.icache_core_out_i[6:0] == 7'b1110011 && 
#            (
#                  u_TOP.CPU_wrapper.CPU1.icache_core_out_i[14:12] == 3'b001 || 
#                  u_TOP.CPU_wrapper.CPU1.icache_core_out_i[14:12] == 3'b010 || 
#                  u_TOP.CPU_wrapper.CPU1.icache_core_out_i[14:12] == 3'b011 || 
#                  u_TOP.CPU_wrapper.CPU1.icache_core_out_i[14:12] == 3'b101 || 
#                  u_TOP.CPU_wrapper.CPU1.icache_core_out_i[14:12] == 3'b110 || 
#                  u_TOP.CPU_wrapper.CPU1.icache_core_out_i[14:12] == 3'b111
#            )
#      ) || (icache_core_out_i[6:0] == 7'b0000000 && icache_core_out_i[31:7] != 25'd0)
#}
#
# set max runtime
set_prove_time_limit 259200s

# make jg execute the properties
prove -all