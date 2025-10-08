# you can modify it
clear -all
check_cov -init -type all

jasper_scoreboard_3 -init
# include source code
#analyze -sv  [glob ../include/AXI_define.svh]
analyze -sv  [glob ../include/def.svh]

#analyze -sv  [glob ../sim/data_array/*.sv]
#analyze -sv  [glob ../sim/DRAM/DRAM.sv]
#analyze -v2k [glob ../sim/ROM/ROM.v]
#analyze -sv  [glob ../sim/SRAM/SRAM_rtl.sv]
#analyze -sv  [glob ../sim/tag_array/tag_array_rtl.sv]

analyze -sv  [glob ../property/Formal_top.sv]
analyze -sv  [glob ../src/top.sv]
analyze -sv  [glob ../src/VPU/*.sv]
#analyze -sv  [glob ../src/AXI/*.sv]
#analyze -sv  [glob ../src/Cache/*.sv]
analyze -sv  [glob ../src/CPU/*.sv]
#analyze -sv  [glob ../src/DMA/*.sv]
analyze -sv  [glob ../src/FPU/*.sv]
#analyze -sv  [glob ../src/WDT/*.sv]
#analyze -sv  [glob ../src/Wrapper/*.sv]
# include assertion property
analyze -sv  [glob ../property/isa.sva]
check_cov -init -exclude_hierarchies {*/_automatic_coveritem*} -regexp

# top module
elaborate -top CPU -bbox_m VPU

# set clock and reset signal
clock clk_i
reset rst_i

# icache always hit
#stopat i_if_stage.fetch_wait
#assume {i_if_stage.fetch_wait == 1'b0}
# no exception
stopat DMA_interrupt_i
assume {DMA_interrupt_i == 1'b0}
stopat WDT_interrupt_i
assume {WDT_interrupt_i == 1'b0}

# always fetch legal instructions at the fetch stage from I-Cache
stopat icache_core_out_i

assume {
      (icache_core_out_i[6:0] == 7'b0110011 && 
            (
                  (icache_core_out_i[31:25] == 7'b0000000) ||
                  (icache_core_out_i[31:25] == 7'b0100000 && (icache_core_out_i[14:12] == 3'b000 || icache_core_out_i[14:12] == 3'b101)) ||
                  (icache_core_out_i[31:25] == 7'b0000001 && (icache_core_out_i[14:12] == 3'b000 || icache_core_out_i[14:12] == 3'b001 || icache_core_out_i[14:12] == 3'b010 || icache_core_out_i[14:12] == 3'b011))
            )
      ) ||
      (icache_core_out_i[6:0] == 7'b0000011 && 
            (
                  icache_core_out_i[14:12] == 3'b000 ||
                  icache_core_out_i[14:12] == 3'b001 ||
                  icache_core_out_i[14:12] == 3'b010 ||
                  icache_core_out_i[14:12] == 3'b100 ||
                  icache_core_out_i[14:12] == 3'b101
            )
      ) || 
      (icache_core_out_i[6:0] == 7'b0010011 && 
            (
                  (icache_core_out_i[14:12] == 3'b000 || 
                   icache_core_out_i[14:12] == 3'b010 || 
                   icache_core_out_i[14:12] == 3'b011 || 
                   icache_core_out_i[14:12] == 3'b100 || 
                   icache_core_out_i[14:12] == 3'b110 || 
                   icache_core_out_i[14:12] == 3'b111) || 
                  (icache_core_out_i[14:12] == 3'b001 && icache_core_out_i[31:25] == 7'b0000000) || 
                  (icache_core_out_i[14:12] == 3'b101 && (icache_core_out_i[31:25] == 7'b0000000 || icache_core_out_i[31:25] == 7'b0100000))
            )
      ) ||
      (icache_core_out_i[6:0] == 7'b1100111 && icache_core_out_i[14:12] == 3'b000) || 
      (icache_core_out_i[6:0] == 7'b0100011 && 
            (
                  icache_core_out_i[14:12] == 3'b000 || 
                  icache_core_out_i[14:12] == 3'b001 || 
                  icache_core_out_i[14:12] == 3'b010
            )
      ) ||
      (icache_core_out_i[6:0] == 7'b1100011 && 
            (
                  icache_core_out_i[14:12] == 3'b000 || 
                  icache_core_out_i[14:12] == 3'b001 || 
                  icache_core_out_i[14:12] == 3'b100 || 
                  icache_core_out_i[14:12] == 3'b101 || 
                  icache_core_out_i[14:12] == 3'b110 || 
                  icache_core_out_i[14:12] == 3'b111
            )
      ) || 
      (icache_core_out_i[6:0] == 7'b0010111) || 
      (icache_core_out_i[6:0] == 7'b0110111) || 
      (icache_core_out_i[6:0] == 7'b1101111) || 
      (icache_core_out_i[6:0] == 7'b1110011 && 
            (
                  icache_core_out_i[14:12] == 3'b001 || 
                  icache_core_out_i[14:12] == 3'b010 || 
                  icache_core_out_i[14:12] == 3'b011 || 
                  icache_core_out_i[14:12] == 3'b101 || 
                  icache_core_out_i[14:12] == 3'b110 || 
                  icache_core_out_i[14:12] == 3'b111
            )
      ) || (icache_core_out_i[6:0] == 7'b0000000 && icache_core_out_i[31:7] != 25'd0)
}

# set max runtime
set_prove_time_limit 259200s

# make jg execute the properties
prove -all