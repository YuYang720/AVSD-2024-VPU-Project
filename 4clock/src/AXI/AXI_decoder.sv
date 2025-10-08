module AXI_decoder (
    input  logic                      valid_i,
    input  logic [`AXI_ADDR_BITS-1:0] addr_i,
    output SLAVE_ID                   slave_id_o
);

    always_comb begin
        slave_id_o = DEAULT_SLAVE;

        if     (addr_i >= `ROM_start_addr  && addr_i <= `ROM_end_addr ) slave_id_o = ROM;
        else if(addr_i >= `IM_start_addr   && addr_i <= `IM_end_addr  ) slave_id_o = IM;
        else if(addr_i >= `DM_start_addr   && addr_i <= `DM_end_addr  ) slave_id_o = DM;
        else if(addr_i >= `DMA_start_addr  && addr_i <= `DMA_end_addr ) slave_id_o = DMA_S;
        else if(addr_i >= `WDT_start_addr  && addr_i <= `WDT_end_addr ) slave_id_o = WDT;
        else if(addr_i >= `DRAM_start_addr && addr_i <= `DRAM_end_addr) slave_id_o = DRAM;

        if(~valid_i) slave_id_o = DEAULT_SLAVE;
    end

endmodule