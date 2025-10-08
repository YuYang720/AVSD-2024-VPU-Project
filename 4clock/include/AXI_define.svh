`ifndef _AXI
`define _AXI

`define AXI_ID_BITS     4
`define AXI_IDS_BITS    8
`define AXI_ADDR_BITS   32
`define AXI_LEN_BITS    4
`define AXI_SIZE_BITS   3
`define AXI_DATA_BITS   32
`define AXI_STRB_BITS   4
`define AXI_LEN_ONE     4'h0
`define AXI_SIZE_BYTE   3'b000
`define AXI_SIZE_HWORD  3'b001
`define AXI_SIZE_WORD   3'b010
`define AXI_BURST_INC   2'h1
`define AXI_STRB_WORD   4'b1111
`define AXI_STRB_HWORD  4'b0011
`define AXI_STRB_BYTE   4'b0001
`define AXI_RESP_OKAY   2'h0
`define AXI_RESP_SLVERR 2'h2
`define AXI_RESP_DECERR 2'h3

// --------------------------------------------
//            Memory Address Mapping           
// --------------------------------------------
`define MASTER_NUM      3
`define SLAVE_NUM       6
`define MASTER_BITS     $clog2(`MASTER_NUM)
`define SLAVE_BITS      $clog2(`SLAVE_NUM)

typedef enum logic [`MASTER_BITS-1:0] {
    CPU_FETCH, CPU_MEM, DMA_M
} MASTER_ID;

typedef enum logic[`SLAVE_BITS:0] {
    ROM, IM, DM, DMA_S, WDT, DRAM, DEAULT_SLAVE
} SLAVE_ID;


// ROM  : 0x0000_0000 ~ 0x0000_1FFF
// IM   : 0x0001_0000 ~ 0x0001_FFFF
// DM   : 0x0002_0000 ~ 0x0003_FFFF
// DMA  : 0x1002_0000 ~ 0x1002_0400
// WDT  : 0x1001_0000 ~ 0x1001_03FF
// DRAM : 0x2000_0000 ~ 0x201F_FFFF

`define ROM_start_addr  32'h0000_0000
`define IM_start_addr   32'h0001_0000
`define DM_start_addr   32'h0002_0000
`define DMA_start_addr  32'h1002_0000
`define WDT_start_addr  32'h1001_0000
`define DRAM_start_addr 32'h2000_0000

`define ROM_end_addr    32'h0000_1FFF
`define IM_end_addr     32'h0001_FFFF
`define DM_end_addr     32'h0003_FFFF
`define DMA_end_addr    32'h1002_0400
`define WDT_end_addr    32'h1001_03FF
`define DRAM_end_addr   32'h201F_FFFF

`endif