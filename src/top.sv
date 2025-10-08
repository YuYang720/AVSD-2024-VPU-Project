// ----------------------------------
// Module chekclist :
//     1.  top.sv          --> ok
//     2.  CPU.sv          --> ok
//     3.  CPU_wrapper.sv  --> ok
//     4.  ROM_wrapper.sv  --> ok
//     5.  SRAM_wrapper.sv --> ok
//     6.  DRAM_wrapper.sv --> ok
//     7.  DMA.sv          --> ok
//     8.  DMA_wrapper.sv  --> ok
//     9.  WDT.sv          --> ok
//     10. WDT_wrapper.sv  --> ok
//     11. AXI.sv          --> ok
//     12. AXI_decoder.sv  --> ok
// ----------------------------------
`include "../include/def.svh"
`include "../include/AXI_define.svh"
// `include "../include/VPU_define.svh"

module top (
    input  logic        cpu_clk,
    input  logic        wdt_clk,
    input  logic        cpu_rst,
    input  logic        wdt_rst,

    // ROM memory port
    input  logic [31:0] ROM_out,
    output logic        ROM_read,
    output logic        ROM_enable,
    output logic [11:0] ROM_address,

    // DRAM memory port
    input  logic        DRAM_valid,
    input  logic [31:0] DRAM_Q,
    output logic        DRAM_CSn,
    output logic [ 3:0] DRAM_WEn,
    output logic        DRAM_RASn,
    output logic        DRAM_CASn,
    output logic [10:0] DRAM_A,
    output logic [31:0] DRAM_D
);

    // --------------------------------------------
    //             AXI Master Interface            
    // --------------------------------------------
    // AR channel
    logic [`AXI_ID_BITS  -1:0] ARID_M   [`MASTER_NUM];
    logic [`AXI_DATA_BITS-1:0] ARADDR_M [`MASTER_NUM];
    logic [`AXI_LEN_BITS -1:0] ARLEN_M  [`MASTER_NUM];
    logic [`AXI_SIZE_BITS-1:0] ARSIZE_M [`MASTER_NUM];
    logic [1:0]                ARBURST_M[`MASTER_NUM];
    logic                      ARVALID_M[`MASTER_NUM];
    logic                      ARREADY_M[`MASTER_NUM];
    // R channel
    logic [`AXI_ID_BITS  -1:0] RID_M    [`MASTER_NUM];
    logic [`AXI_DATA_BITS-1:0] RDATA_M  [`MASTER_NUM];
    logic [1:0]                RRESP_M  [`MASTER_NUM];
    logic                      RLAST_M  [`MASTER_NUM];
    logic                      RVALID_M [`MASTER_NUM];
    logic                      RREADY_M [`MASTER_NUM];
    // AW channel
    logic [`AXI_ID_BITS  -1:0] AWID_M   [`MASTER_NUM];
    logic [`AXI_ADDR_BITS-1:0] AWADDR_M [`MASTER_NUM];
    logic [`AXI_LEN_BITS -1:0] AWLEN_M  [`MASTER_NUM];
    logic [`AXI_SIZE_BITS-1:0] AWSIZE_M [`MASTER_NUM];
    logic [1:0]                AWBURST_M[`MASTER_NUM];
    logic                      AWVALID_M[`MASTER_NUM];
    logic                      AWREADY_M[`MASTER_NUM];
    // W channel
    logic [`AXI_DATA_BITS-1:0] WDATA_M  [`MASTER_NUM];
    logic [`AXI_STRB_BITS-1:0] WSTRB_M  [`MASTER_NUM];
    logic                      WLAST_M  [`MASTER_NUM];
    logic                      WVALID_M [`MASTER_NUM];
    logic                      WREADY_M [`MASTER_NUM];
    // B channel
    logic [`AXI_ID_BITS  -1:0] BID_M    [`MASTER_NUM];
    logic [1:0]                BRESP_M  [`MASTER_NUM];
    logic                      BVALID_M [`MASTER_NUM];
    logic                      BREADY_M [`MASTER_NUM];

    // --------------------------------------------
    //             AXI Slave Interfaces            
    // --------------------------------------------
    // AR channel
    logic [`AXI_IDS_BITS -1:0] ARID_S   [`SLAVE_NUM];
    logic [`AXI_DATA_BITS-1:0] ARADDR_S [`SLAVE_NUM];
    logic [`AXI_LEN_BITS -1:0] ARLEN_S  [`SLAVE_NUM];
    logic [`AXI_SIZE_BITS-1:0] ARSIZE_S [`SLAVE_NUM];
    logic [1:0]                ARBURST_S[`SLAVE_NUM];
    logic                      ARVALID_S[`SLAVE_NUM];
    logic                      ARREADY_S[`SLAVE_NUM];
    // R channel
    logic [`AXI_IDS_BITS -1:0] RID_S    [`SLAVE_NUM];
    logic [`AXI_DATA_BITS-1:0] RDATA_S  [`SLAVE_NUM];
    logic [1:0]                RRESP_S  [`SLAVE_NUM];
    logic                      RLAST_S  [`SLAVE_NUM];
    logic                      RVALID_S [`SLAVE_NUM];
    logic                      RREADY_S [`SLAVE_NUM];
    // AW channel
    logic [`AXI_IDS_BITS -1:0] AWID_S   [`SLAVE_NUM];
    logic [`AXI_ADDR_BITS-1:0] AWADDR_S [`SLAVE_NUM];
    logic [`AXI_LEN_BITS -1:0] AWLEN_S  [`SLAVE_NUM];
    logic [`AXI_SIZE_BITS-1:0] AWSIZE_S [`SLAVE_NUM];
    logic [1:0]                AWBURST_S[`SLAVE_NUM];
    logic                      AWVALID_S[`SLAVE_NUM];
    logic                      AWREADY_S[`SLAVE_NUM];
    // W channel
    logic [`AXI_DATA_BITS-1:0] WDATA_S  [`SLAVE_NUM];
    logic [`AXI_STRB_BITS-1:0] WSTRB_S  [`SLAVE_NUM];
    logic                      WLAST_S  [`SLAVE_NUM];
    logic                      WVALID_S [`SLAVE_NUM];
    logic                      WREADY_S [`SLAVE_NUM];
    // B channel
    logic [`AXI_IDS_BITS -1:0] BID_S    [`SLAVE_NUM];
    logic [1:0]                BRESP_S  [`SLAVE_NUM];
    logic                      BVALID_S [`SLAVE_NUM];
    logic                      BREADY_S [`SLAVE_NUM];

    // --------------------------------------------
    //               External Signals              
    // --------------------------------------------
    logic                      DMA_interrupt;
    logic                      WDT_interrupt;

    // --------------------------------------------
    //                    System                   
    // --------------------------------------------
    CPU_wrapper CPU_wrapper (
        .clk_i            ( cpu_clk          ),
        .rst_i            ( cpu_rst          ),

        .DMA_interrupt_i  ( DMA_interrupt    ),
        .WDT_interrupt_i  ( WDT_interrupt    ),

        .ARID_M0          ( ARID_M   [0]     ),
        .ARADDR_M0        ( ARADDR_M [0]     ),
        .ARLEN_M0         ( ARLEN_M  [0]     ),
        .ARSIZE_M0        ( ARSIZE_M [0]     ),
        .ARBURST_M0       ( ARBURST_M[0]     ),
        .ARVALID_M0       ( ARVALID_M[0]     ),
        .ARREADY_M0       ( ARREADY_M[0]     ),
        .RID_M0           ( RID_M    [0]     ),
        .RDATA_M0         ( RDATA_M  [0]     ),
        .RRESP_M0         ( RRESP_M  [0]     ),
        .RLAST_M0         ( RLAST_M  [0]     ),
        .RVALID_M0        ( RVALID_M [0]     ),
        .RREADY_M0        ( RREADY_M [0]     ),
        .AWID_M0          ( AWID_M   [0]     ),
        .AWADDR_M0        ( AWADDR_M [0]     ),
        .AWLEN_M0         ( AWLEN_M  [0]     ),
        .AWSIZE_M0        ( AWSIZE_M [0]     ),
        .AWBURST_M0       ( AWBURST_M[0]     ),
        .AWVALID_M0       ( AWVALID_M[0]     ),
        .AWREADY_M0       ( AWREADY_M[0]     ),
        .WDATA_M0         ( WDATA_M  [0]     ),
        .WSTRB_M0         ( WSTRB_M  [0]     ),
        .WLAST_M0         ( WLAST_M  [0]     ),
        .WVALID_M0        ( WVALID_M [0]     ),
        .WREADY_M0        ( WREADY_M [0]     ),
        .BID_M0           ( BID_M    [0]     ),
        .BRESP_M0         ( BRESP_M  [0]     ),
        .BVALID_M0        ( BVALID_M [0]     ),
        .BREADY_M0        ( BREADY_M [0]     ),

        .ARID_M1          ( ARID_M   [1]     ),
        .ARADDR_M1        ( ARADDR_M [1]     ),
        .ARLEN_M1         ( ARLEN_M  [1]     ),
        .ARSIZE_M1        ( ARSIZE_M [1]     ),
        .ARBURST_M1       ( ARBURST_M[1]     ),
        .ARVALID_M1       ( ARVALID_M[1]     ),
        .ARREADY_M1       ( ARREADY_M[1]     ),
        .RID_M1           ( RID_M    [1]     ),
        .RDATA_M1         ( RDATA_M  [1]     ),
        .RRESP_M1         ( RRESP_M  [1]     ),
        .RLAST_M1         ( RLAST_M  [1]     ),
        .RVALID_M1        ( RVALID_M [1]     ),
        .RREADY_M1        ( RREADY_M [1]     ),
        .AWID_M1          ( AWID_M   [1]     ),
        .AWADDR_M1        ( AWADDR_M [1]     ),
        .AWLEN_M1         ( AWLEN_M  [1]     ),
        .AWSIZE_M1        ( AWSIZE_M [1]     ),
        .AWBURST_M1       ( AWBURST_M[1]     ),
        .AWVALID_M1       ( AWVALID_M[1]     ),
        .AWREADY_M1       ( AWREADY_M[1]     ),
        .WDATA_M1         ( WDATA_M  [1]     ),
        .WSTRB_M1         ( WSTRB_M  [1]     ),
        .WLAST_M1         ( WLAST_M  [1]     ),
        .WVALID_M1        ( WVALID_M [1]     ),
        .WREADY_M1        ( WREADY_M [1]     ),
        .BID_M1           ( BID_M    [1]     ),
        .BRESP_M1         ( BRESP_M  [1]     ),
        .BVALID_M1        ( BVALID_M [1]     ),
        .BREADY_M1        ( BREADY_M [1]     )
    );

    DMA_wrapper DMA_wrapper (
        .clk              ( cpu_clk          ),
        .rst              ( cpu_rst          ),
        .BASE_ADDR        ( `DMA_start_addr  ),
        .DMA_interrupt_o  ( DMA_interrupt    ),

        .ARID_M           ( ARID_M   [2]     ),
        .ARADDR_M         ( ARADDR_M [2]     ),
        .ARLEN_M          ( ARLEN_M  [2]     ),
        .ARSIZE_M         ( ARSIZE_M [2]     ),
        .ARBURST_M        ( ARBURST_M[2]     ),
        .ARVALID_M        ( ARVALID_M[2]     ),
        .ARREADY_M        ( ARREADY_M[2]     ),
        .RID_M            ( RID_M    [2]     ),
        .RDATA_M          ( RDATA_M  [2]     ),
        .RRESP_M          ( RRESP_M  [2]     ),
        .RLAST_M          ( RLAST_M  [2]     ),
        .RVALID_M         ( RVALID_M [2]     ),
        .RREADY_M         ( RREADY_M [2]     ),
        .AWID_M           ( AWID_M   [2]     ),
        .AWADDR_M         ( AWADDR_M [2]     ),
        .AWLEN_M          ( AWLEN_M  [2]     ),
        .AWSIZE_M         ( AWSIZE_M [2]     ),
        .AWBURST_M        ( AWBURST_M[2]     ),
        .AWVALID_M        ( AWVALID_M[2]     ),
        .AWREADY_M        ( AWREADY_M[2]     ),
        .WDATA_M          ( WDATA_M  [2]     ),
        .WSTRB_M          ( WSTRB_M  [2]     ),
        .WLAST_M          ( WLAST_M  [2]     ),
        .WVALID_M         ( WVALID_M [2]     ),
        .WREADY_M         ( WREADY_M [2]     ),
        .BID_M            ( BID_M    [2]     ),
        .BRESP_M          ( BRESP_M  [2]     ),
        .BVALID_M         ( BVALID_M [2]     ),
        .BREADY_M         ( BREADY_M [2]     ),

        .ARID_S           ( ARID_S   [3]     ),
        .ARADDR_S         ( ARADDR_S [3]     ),
        .ARLEN_S          ( ARLEN_S  [3]     ),
        .ARSIZE_S         ( ARSIZE_S [3]     ),
        .ARBURST_S        ( ARBURST_S[3]     ),
        .ARVALID_S        ( ARVALID_S[3]     ),
        .ARREADY_S        ( ARREADY_S[3]     ),
        .RID_S            ( RID_S    [3]     ),
        .RDATA_S          ( RDATA_S  [3]     ),
        .RRESP_S          ( RRESP_S  [3]     ),
        .RLAST_S          ( RLAST_S  [3]     ),
        .RVALID_S         ( RVALID_S [3]     ),
        .RREADY_S         ( RREADY_S [3]     ),
        .AWID_S           ( AWID_S   [3]     ),
        .AWADDR_S         ( AWADDR_S [3]     ),
        .AWLEN_S          ( AWLEN_S  [3]     ),
        .AWSIZE_S         ( AWSIZE_S [3]     ),
        .AWBURST_S        ( AWBURST_S[3]     ),
        .AWVALID_S        ( AWVALID_S[3]     ),
        .AWREADY_S        ( AWREADY_S[3]     ),
        .WDATA_S          ( WDATA_S  [3]     ),
        .WSTRB_S          ( WSTRB_S  [3]     ),
        .WLAST_S          ( WLAST_S  [3]     ),
        .WVALID_S         ( WVALID_S [3]     ),
        .WREADY_S         ( WREADY_S [3]     ),
        .BID_S            ( BID_S    [3]     ),
        .BRESP_S          ( BRESP_S  [3]     ),
        .BVALID_S         ( BVALID_S [3]     ),
        .BREADY_S         ( BREADY_S [3]     )
    );

    AXI AXI_BUS (
        .ACLK            ( cpu_clk          ),
        .ARESET          ( cpu_rst          ),

        .ARID_M          ( ARID_M           ),
        .ARADDR_M        ( ARADDR_M         ),
        .ARLEN_M         ( ARLEN_M          ),
        .ARSIZE_M        ( ARSIZE_M         ),
        .ARBURST_M       ( ARBURST_M        ),
        .ARVALID_M       ( ARVALID_M        ),
        .ARREADY_M       ( ARREADY_M        ),
        .RID_M           ( RID_M            ),
        .RDATA_M         ( RDATA_M          ),
        .RRESP_M         ( RRESP_M          ),
        .RLAST_M         ( RLAST_M          ),
        .RVALID_M        ( RVALID_M         ),
        .RREADY_M        ( RREADY_M         ),
        .AWID_M          ( AWID_M           ),
        .AWADDR_M        ( AWADDR_M         ),
        .AWLEN_M         ( AWLEN_M          ),
        .AWSIZE_M        ( AWSIZE_M         ),
        .AWBURST_M       ( AWBURST_M        ),
        .AWVALID_M       ( AWVALID_M        ),
        .AWREADY_M       ( AWREADY_M        ),
        .WDATA_M         ( WDATA_M          ),
        .WSTRB_M         ( WSTRB_M          ),
        .WLAST_M         ( WLAST_M          ),
        .WVALID_M        ( WVALID_M         ),
        .WREADY_M        ( WREADY_M         ),
        .BID_M           ( BID_M            ),
        .BRESP_M         ( BRESP_M          ),
        .BVALID_M        ( BVALID_M         ),
        .BREADY_M        ( BREADY_M         ),

        .ARID_S          ( ARID_S           ),
        .ARADDR_S        ( ARADDR_S         ),
        .ARLEN_S         ( ARLEN_S          ),
        .ARSIZE_S        ( ARSIZE_S         ),
        .ARBURST_S       ( ARBURST_S        ),
        .ARVALID_S       ( ARVALID_S        ),
        .ARREADY_S       ( ARREADY_S        ),
        .RID_S           ( RID_S            ),
        .RDATA_S         ( RDATA_S          ),
        .RRESP_S         ( RRESP_S          ),
        .RLAST_S         ( RLAST_S          ),
        .RVALID_S        ( RVALID_S         ),
        .RREADY_S        ( RREADY_S         ),
        .AWID_S          ( AWID_S           ),
        .AWADDR_S        ( AWADDR_S         ),
        .AWLEN_S         ( AWLEN_S          ),
        .AWSIZE_S        ( AWSIZE_S         ),
        .AWBURST_S       ( AWBURST_S        ),
        .AWVALID_S       ( AWVALID_S        ),
        .AWREADY_S       ( AWREADY_S        ),
        .WDATA_S         ( WDATA_S          ),
        .WSTRB_S         ( WSTRB_S          ),
        .WLAST_S         ( WLAST_S          ),
        .WVALID_S        ( WVALID_S         ),
        .WREADY_S        ( WREADY_S         ),
        .BID_S           ( BID_S            ),
        .BRESP_S         ( BRESP_S          ),
        .BVALID_S        ( BVALID_S         ),
        .BREADY_S        ( BREADY_S         )
    );

    ROM_wrapper ROM_wrapper (
        .clk             ( cpu_clk          ),
        .rst             ( cpu_rst          ),
        .BASE_ADDR       ( `ROM_start_addr  ),

        .ROM_out,
        .ROM_read,
        .ROM_enable,
        .ROM_address,

        .ARID_S          ( ARID_S   [0]     ),
        .ARADDR_S        ( ARADDR_S [0]     ),
        .ARLEN_S         ( ARLEN_S  [0]     ),
        .ARSIZE_S        ( ARSIZE_S [0]     ),
        .ARBURST_S       ( ARBURST_S[0]     ),
        .ARVALID_S       ( ARVALID_S[0]     ),
        .ARREADY_S       ( ARREADY_S[0]     ),
        .RID_S           ( RID_S    [0]     ),
        .RDATA_S         ( RDATA_S  [0]     ),
        .RRESP_S         ( RRESP_S  [0]     ),
        .RLAST_S         ( RLAST_S  [0]     ),
        .RVALID_S        ( RVALID_S [0]     ),
        .RREADY_S        ( RREADY_S [0]     ),
        .AWID_S          ( AWID_S   [0]     ),
        .AWADDR_S        ( AWADDR_S [0]     ),
        .AWLEN_S         ( AWLEN_S  [0]     ),
        .AWSIZE_S        ( AWSIZE_S [0]     ),
        .AWBURST_S       ( AWBURST_S[0]     ),
        .AWVALID_S       ( AWVALID_S[0]     ),
        .AWREADY_S       ( AWREADY_S[0]     ),
        .WDATA_S         ( WDATA_S  [0]     ),
        .WSTRB_S         ( WSTRB_S  [0]     ),
        .WLAST_S         ( WLAST_S  [0]     ),
        .WVALID_S        ( WVALID_S [0]     ),
        .WREADY_S        ( WREADY_S [0]     ),
        .BID_S           ( BID_S    [0]     ),
        .BRESP_S         ( BRESP_S  [0]     ),
        .BVALID_S        ( BVALID_S [0]     ),
        .BREADY_S        ( BREADY_S [0]     )
    );

    IM_wrapper IM1 (
        .clk             ( cpu_clk          ),
        .rst             ( cpu_rst          ),
        .BASE_ADDR       ( `IM_start_addr   ),

        .ARID_S          ( ARID_S   [1]     ),
        .ARADDR_S        ( ARADDR_S [1]     ),
        .ARLEN_S         ( ARLEN_S  [1]     ),
        .ARSIZE_S        ( ARSIZE_S [1]     ),
        .ARBURST_S       ( ARBURST_S[1]     ),
        .ARVALID_S       ( ARVALID_S[1]     ),
        .ARREADY_S       ( ARREADY_S[1]     ),
        .RID_S           ( RID_S    [1]     ),
        .RDATA_S         ( RDATA_S  [1]     ),
        .RRESP_S         ( RRESP_S  [1]     ),
        .RLAST_S         ( RLAST_S  [1]     ),
        .RVALID_S        ( RVALID_S [1]     ),
        .RREADY_S        ( RREADY_S [1]     ),
        .AWID_S          ( AWID_S   [1]     ),
        .AWADDR_S        ( AWADDR_S [1]     ),
        .AWLEN_S         ( AWLEN_S  [1]     ),
        .AWSIZE_S        ( AWSIZE_S [1]     ),
        .AWBURST_S       ( AWBURST_S[1]     ),
        .AWVALID_S       ( AWVALID_S[1]     ),
        .AWREADY_S       ( AWREADY_S[1]     ),
        .WDATA_S         ( WDATA_S  [1]     ),
        .WSTRB_S         ( WSTRB_S  [1]     ),
        .WLAST_S         ( WLAST_S  [1]     ),
        .WVALID_S        ( WVALID_S [1]     ),
        .WREADY_S        ( WREADY_S [1]     ),
        .BID_S           ( BID_S    [1]     ),
        .BRESP_S         ( BRESP_S  [1]     ),
        .BVALID_S        ( BVALID_S [1]     ),
        .BREADY_S        ( BREADY_S [1]     )
    );

    DM_wrapper DM1 (
        .clk             ( cpu_clk          ),
        .rst             ( cpu_rst          ),
        .BASE_ADDR       ( `DM_start_addr   ),

        .ARID_S          ( ARID_S   [2]     ),
        .ARADDR_S        ( ARADDR_S [2]     ),
        .ARLEN_S         ( ARLEN_S  [2]     ),
        .ARSIZE_S        ( ARSIZE_S [2]     ),
        .ARBURST_S       ( ARBURST_S[2]     ),
        .ARVALID_S       ( ARVALID_S[2]     ),
        .ARREADY_S       ( ARREADY_S[2]     ),
        .RID_S           ( RID_S    [2]     ),
        .RDATA_S         ( RDATA_S  [2]     ),
        .RRESP_S         ( RRESP_S  [2]     ),
        .RLAST_S         ( RLAST_S  [2]     ),
        .RVALID_S        ( RVALID_S [2]     ),
        .RREADY_S        ( RREADY_S [2]     ),
        .AWID_S          ( AWID_S   [2]     ),
        .AWADDR_S        ( AWADDR_S [2]     ),
        .AWLEN_S         ( AWLEN_S  [2]     ),
        .AWSIZE_S        ( AWSIZE_S [2]     ),
        .AWBURST_S       ( AWBURST_S[2]     ),
        .AWVALID_S       ( AWVALID_S[2]     ),
        .AWREADY_S       ( AWREADY_S[2]     ),
        .WDATA_S         ( WDATA_S  [2]     ),
        .WSTRB_S         ( WSTRB_S  [2]     ),
        .WLAST_S         ( WLAST_S  [2]     ),
        .WVALID_S        ( WVALID_S [2]     ),
        .WREADY_S        ( WREADY_S [2]     ),
        .BID_S           ( BID_S    [2]     ),
        .BRESP_S         ( BRESP_S  [2]     ),
        .BVALID_S        ( BVALID_S [2]     ),
        .BREADY_S        ( BREADY_S [2]     )
    );

    WDT_wrapper WDT_wrapper (
        .clk             ( cpu_clk          ),
        .rst             ( cpu_rst          ),
        .wdt_clk         ( wdt_clk          ),
        .wdt_rst         ( wdt_rst          ),
        .BASE_ADDR       ( `WDT_start_addr  ),
        .WDT_interrupt_o ( WDT_interrupt    ),

        .ARID_S          ( ARID_S   [4]     ),
        .ARADDR_S        ( ARADDR_S [4]     ),
        .ARLEN_S         ( ARLEN_S  [4]     ),
        .ARSIZE_S        ( ARSIZE_S [4]     ),
        .ARBURST_S       ( ARBURST_S[4]     ),
        .ARVALID_S       ( ARVALID_S[4]     ),
        .ARREADY_S       ( ARREADY_S[4]     ),
        .RID_S           ( RID_S    [4]     ),
        .RDATA_S         ( RDATA_S  [4]     ),
        .RRESP_S         ( RRESP_S  [4]     ),
        .RLAST_S         ( RLAST_S  [4]     ),
        .RVALID_S        ( RVALID_S [4]     ),
        .RREADY_S        ( RREADY_S [4]     ),
        .AWID_S          ( AWID_S   [4]     ),
        .AWADDR_S        ( AWADDR_S [4]     ),
        .AWLEN_S         ( AWLEN_S  [4]     ),
        .AWSIZE_S        ( AWSIZE_S [4]     ),
        .AWBURST_S       ( AWBURST_S[4]     ),
        .AWVALID_S       ( AWVALID_S[4]     ),
        .AWREADY_S       ( AWREADY_S[4]     ),
        .WDATA_S         ( WDATA_S  [4]     ),
        .WSTRB_S         ( WSTRB_S  [4]     ),
        .WLAST_S         ( WLAST_S  [4]     ),
        .WVALID_S        ( WVALID_S [4]     ),
        .WREADY_S        ( WREADY_S [4]     ),
        .BID_S           ( BID_S    [4]     ),
        .BRESP_S         ( BRESP_S  [4]     ),
        .BVALID_S        ( BVALID_S [4]     ),
        .BREADY_S        ( BREADY_S [4]     )
    );

    DRAM_wrapper DRAM_wrapper (
        .clk             ( cpu_clk          ),
        .rst             ( cpu_rst          ),
        .BASE_ADDR       ( `DRAM_start_addr ),

        .DRAM_Q,
        .DRAM_valid,
        .DRAM_CSn,
        .DRAM_WEn,
        .DRAM_RASn,
        .DRAM_CASn,
        .DRAM_A,
        .DRAM_D,

        .ARID_S          ( ARID_S   [5]     ),
        .ARADDR_S        ( ARADDR_S [5]     ),
        .ARLEN_S         ( ARLEN_S  [5]     ),
        .ARSIZE_S        ( ARSIZE_S [5]     ),
        .ARBURST_S       ( ARBURST_S[5]     ),
        .ARVALID_S       ( ARVALID_S[5]     ),
        .ARREADY_S       ( ARREADY_S[5]     ),
        .RID_S           ( RID_S    [5]     ),
        .RDATA_S         ( RDATA_S  [5]     ),
        .RRESP_S         ( RRESP_S  [5]     ),
        .RLAST_S         ( RLAST_S  [5]     ),
        .RVALID_S        ( RVALID_S [5]     ),
        .RREADY_S        ( RREADY_S [5]     ),
        .AWID_S          ( AWID_S   [5]     ),
        .AWADDR_S        ( AWADDR_S [5]     ),
        .AWLEN_S         ( AWLEN_S  [5]     ),
        .AWSIZE_S        ( AWSIZE_S [5]     ),
        .AWBURST_S       ( AWBURST_S[5]     ),
        .AWVALID_S       ( AWVALID_S[5]     ),
        .AWREADY_S       ( AWREADY_S[5]     ),
        .WDATA_S         ( WDATA_S  [5]     ),
        .WSTRB_S         ( WSTRB_S  [5]     ),
        .WLAST_S         ( WLAST_S  [5]     ),
        .WVALID_S        ( WVALID_S [5]     ),
        .WREADY_S        ( WREADY_S [5]     ),
        .BID_S           ( BID_S    [5]     ),
        .BRESP_S         ( BRESP_S  [5]     ),
        .BVALID_S        ( BVALID_S [5]     ),
        .BREADY_S        ( BREADY_S [5]     )
    );

endmodule