//================================================
// Auther:      Chen-En Wu
// Filename:    AXI.sv
// Description: AXI crossbar
// Version:     1.0
//================================================

module AXI (
    input  logic                      cpu_clk,
    input  logic                      axi_clk,
    input  logic                      rom_clk,
    input  logic                      dram_clk,
    input  logic                      cpu_rst,
    input  logic                      axi_rst,
    input  logic                      rom_rst,
    input  logic                      dram_rst,

    // SLAVE INTERFACE FOR MASTERS
    // AR channel
    input  logic [`AXI_ID_BITS  -1:0] ARID_M   [`MASTER_NUM],
    input  logic [`AXI_DATA_BITS-1:0] ARADDR_M [`MASTER_NUM],
    input  logic [`AXI_LEN_BITS -1:0] ARLEN_M  [`MASTER_NUM],
    input  logic [`AXI_SIZE_BITS-1:0] ARSIZE_M [`MASTER_NUM],
    input  logic [1:0]                ARBURST_M[`MASTER_NUM],
    input  logic                      ARVALID_M[`MASTER_NUM],
    output logic                      ARREADY_M[`MASTER_NUM],
    // R channel
    output logic [`AXI_ID_BITS  -1:0] RID_M    [`MASTER_NUM],
    output logic [`AXI_DATA_BITS-1:0] RDATA_M  [`MASTER_NUM],
    output logic [1:0]                RRESP_M  [`MASTER_NUM],
    output logic                      RLAST_M  [`MASTER_NUM],
    output logic                      RVALID_M [`MASTER_NUM],
    input  logic                      RREADY_M [`MASTER_NUM],
    // AW channel
    input  logic [`AXI_ID_BITS  -1:0] AWID_M   [`MASTER_NUM],
    input  logic [`AXI_ADDR_BITS-1:0] AWADDR_M [`MASTER_NUM],
    input  logic [`AXI_LEN_BITS -1:0] AWLEN_M  [`MASTER_NUM],
    input  logic [`AXI_SIZE_BITS-1:0] AWSIZE_M [`MASTER_NUM],
    input  logic [1:0]                AWBURST_M[`MASTER_NUM],
    input  logic                      AWVALID_M[`MASTER_NUM],
    output logic                      AWREADY_M[`MASTER_NUM],
    // W channel
    input  logic [`AXI_DATA_BITS-1:0] WDATA_M  [`MASTER_NUM],
    input  logic [`AXI_STRB_BITS-1:0] WSTRB_M  [`MASTER_NUM],
    input  logic                      WLAST_M  [`MASTER_NUM],
    input  logic                      WVALID_M [`MASTER_NUM],
    output logic                      WREADY_M [`MASTER_NUM],
    // B channel
    output logic [`AXI_ID_BITS  -1:0] BID_M    [`MASTER_NUM],
    output logic [1:0]                BRESP_M  [`MASTER_NUM],
    output logic                      BVALID_M [`MASTER_NUM],
    input  logic                      BREADY_M [`MASTER_NUM],

    // MASTER INTERFACE FOR SLAVES
    // AR channel
    output logic [`AXI_IDS_BITS -1:0] ARID_S   [`SLAVE_NUM],
    output logic [`AXI_DATA_BITS-1:0] ARADDR_S [`SLAVE_NUM],
    output logic [`AXI_LEN_BITS -1:0] ARLEN_S  [`SLAVE_NUM],
    output logic [`AXI_SIZE_BITS-1:0] ARSIZE_S [`SLAVE_NUM],
    output logic [1:0]                ARBURST_S[`SLAVE_NUM],
    output logic                      ARVALID_S[`SLAVE_NUM],
    input  logic                      ARREADY_S[`SLAVE_NUM],
    // R channel
    input  logic [`AXI_IDS_BITS -1:0] RID_S    [`SLAVE_NUM],
    input  logic [`AXI_DATA_BITS-1:0] RDATA_S  [`SLAVE_NUM],
    input  logic [1:0]                RRESP_S  [`SLAVE_NUM],
    input  logic                      RLAST_S  [`SLAVE_NUM],
    input  logic                      RVALID_S [`SLAVE_NUM],
    output logic                      RREADY_S [`SLAVE_NUM],
    // AW channel
    output logic [`AXI_IDS_BITS -1:0] AWID_S   [`SLAVE_NUM],
    output logic [`AXI_ADDR_BITS-1:0] AWADDR_S [`SLAVE_NUM],
    output logic [`AXI_LEN_BITS -1:0] AWLEN_S  [`SLAVE_NUM],
    output logic [`AXI_SIZE_BITS-1:0] AWSIZE_S [`SLAVE_NUM],
    output logic [1:0]                AWBURST_S[`SLAVE_NUM],
    output logic                      AWVALID_S[`SLAVE_NUM],
    input  logic                      AWREADY_S[`SLAVE_NUM],
    // W channel
    output logic [`AXI_DATA_BITS-1:0] WDATA_S  [`SLAVE_NUM],
    output logic [`AXI_STRB_BITS-1:0] WSTRB_S  [`SLAVE_NUM],
    output logic                      WLAST_S  [`SLAVE_NUM],
    output logic                      WVALID_S [`SLAVE_NUM],
    input  logic                      WREADY_S [`SLAVE_NUM],
    // B channel
    input  logic [`AXI_IDS_BITS -1:0] BID_S    [`SLAVE_NUM],
    input  logic [1:0]                BRESP_S  [`SLAVE_NUM],
    input  logic                      BVALID_S [`SLAVE_NUM],
    output logic                      BREADY_S [`SLAVE_NUM]
);

    // --------------------------------------------
    //              Signal Declaration             
    // --------------------------------------------
    // master <-> AXI
    // AR channel
    logic [`AXI_ID_BITS  -1:0] ARID_M_AXI   [`MASTER_NUM];
    logic [`AXI_DATA_BITS-1:0] ARADDR_M_AXI [`MASTER_NUM];
    logic [`AXI_LEN_BITS -1:0] ARLEN_M_AXI  [`MASTER_NUM];
    logic [`AXI_SIZE_BITS-1:0] ARSIZE_M_AXI [`MASTER_NUM];
    logic [1:0]                ARBURST_M_AXI[`MASTER_NUM];
    logic                      ARVALID_M_AXI[`MASTER_NUM];
    logic                      ARREADY_M_AXI[`MASTER_NUM];
    // R channel
    logic [`AXI_ID_BITS  -1:0] RID_M_AXI    [`MASTER_NUM];
    logic [`AXI_DATA_BITS-1:0] RDATA_M_AXI  [`MASTER_NUM];
    logic [1:0]                RRESP_M_AXI  [`MASTER_NUM];
    logic                      RLAST_M_AXI  [`MASTER_NUM];
    logic                      RVALID_M_AXI [`MASTER_NUM];
    logic                      RREADY_M_AXI [`MASTER_NUM];
    // AW channel
    logic [`AXI_ID_BITS  -1:0] AWID_M_AXI   [`MASTER_NUM];
    logic [`AXI_ADDR_BITS-1:0] AWADDR_M_AXI [`MASTER_NUM];
    logic [`AXI_LEN_BITS -1:0] AWLEN_M_AXI  [`MASTER_NUM];
    logic [`AXI_SIZE_BITS-1:0] AWSIZE_M_AXI [`MASTER_NUM];
    logic [1:0]                AWBURST_M_AXI[`MASTER_NUM];
    logic                      AWVALID_M_AXI[`MASTER_NUM];
    logic                      AWREADY_M_AXI[`MASTER_NUM];
    // W channel
    logic [`AXI_DATA_BITS-1:0] WDATA_M_AXI  [`MASTER_NUM];
    logic [`AXI_STRB_BITS-1:0] WSTRB_M_AXI  [`MASTER_NUM];
    logic                      WLAST_M_AXI  [`MASTER_NUM];
    logic                      WVALID_M_AXI [`MASTER_NUM];
    logic                      WREADY_M_AXI [`MASTER_NUM];
    // B channel
    logic [`AXI_ID_BITS  -1:0] BID_M_AXI    [`MASTER_NUM];
    logic [1:0]                BRESP_M_AXI  [`MASTER_NUM];
    logic                      BVALID_M_AXI [`MASTER_NUM];
    logic                      BREADY_M_AXI [`MASTER_NUM];

    // axi <-> slave
    // AR channel
    logic [`AXI_IDS_BITS -1:0] ARID_AXI_S   [`SLAVE_NUM];
    logic [`AXI_DATA_BITS-1:0] ARADDR_AXI_S [`SLAVE_NUM];
    logic [`AXI_LEN_BITS -1:0] ARLEN_AXI_S  [`SLAVE_NUM];
    logic [`AXI_SIZE_BITS-1:0] ARSIZE_AXI_S [`SLAVE_NUM];
    logic [1:0]                ARBURST_AXI_S[`SLAVE_NUM];
    logic                      ARVALID_AXI_S[`SLAVE_NUM];
    logic                      ARREADY_AXI_S[`SLAVE_NUM];
    // R channel
    logic [`AXI_IDS_BITS -1:0] RID_AXI_S    [`SLAVE_NUM];
    logic [`AXI_DATA_BITS-1:0] RDATA_AXI_S  [`SLAVE_NUM];
    logic [1:0]                RRESP_AXI_S  [`SLAVE_NUM];
    logic                      RLAST_AXI_S  [`SLAVE_NUM];
    logic                      RVALID_AXI_S [`SLAVE_NUM];
    logic                      RREADY_AXI_S [`SLAVE_NUM];
    // AW channel
    logic [`AXI_IDS_BITS -1:0] AWID_AXI_S   [`SLAVE_NUM];
    logic [`AXI_ADDR_BITS-1:0] AWADDR_AXI_S [`SLAVE_NUM];
    logic [`AXI_LEN_BITS -1:0] AWLEN_AXI_S  [`SLAVE_NUM];
    logic [`AXI_SIZE_BITS-1:0] AWSIZE_AXI_S [`SLAVE_NUM];
    logic [1:0]                AWBURST_AXI_S[`SLAVE_NUM];
    logic                      AWVALID_AXI_S[`SLAVE_NUM];
    logic                      AWREADY_AXI_S[`SLAVE_NUM];
    // W channel
    logic [`AXI_DATA_BITS-1:0] WDATA_AXI_S  [`SLAVE_NUM];
    logic [`AXI_STRB_BITS-1:0] WSTRB_AXI_S  [`SLAVE_NUM];
    logic                      WLAST_AXI_S  [`SLAVE_NUM];
    logic                      WVALID_AXI_S [`SLAVE_NUM];
    logic                      WREADY_AXI_S [`SLAVE_NUM];
    // B channel
    logic [`AXI_IDS_BITS -1:0] BID_AXI_S    [`SLAVE_NUM];
    logic [1:0]                BRESP_AXI_S  [`SLAVE_NUM];
    logic                      BVALID_AXI_S [`SLAVE_NUM];
    logic                      BREADY_AXI_S [`SLAVE_NUM];

    // --------------------------------------------
    //           master <-> fifo <-> axi           
    // --------------------------------------------
    AXI_CDC_master i_axi_cdc_master0 (
        .master_clk      ( cpu_clk          ),
        .master_rst      ( cpu_rst          ),
        .axi_clk         ( axi_clk          ),
        .axi_rst         ( axi_rst          ),

        .ARID_M          ( ARID_M   [0]     ),
        .ARADDR_M        ( ARADDR_M [0]     ),
        .ARLEN_M         ( ARLEN_M  [0]     ),
        .ARSIZE_M        ( ARSIZE_M [0]     ),
        .ARBURST_M       ( ARBURST_M[0]     ),
        .ARVALID_M       ( ARVALID_M[0]     ),
        .ARREADY_M       ( ARREADY_M[0]     ),
        .RID_M           ( RID_M    [0]     ),
        .RDATA_M         ( RDATA_M  [0]     ),
        .RRESP_M         ( RRESP_M  [0]     ),
        .RLAST_M         ( RLAST_M  [0]     ),
        .RVALID_M        ( RVALID_M [0]     ),
        .RREADY_M        ( RREADY_M [0]     ),
        .AWID_M          ( AWID_M   [0]     ),
        .AWADDR_M        ( AWADDR_M [0]     ),
        .AWLEN_M         ( AWLEN_M  [0]     ),
        .AWSIZE_M        ( AWSIZE_M [0]     ),
        .AWBURST_M       ( AWBURST_M[0]     ),
        .AWVALID_M       ( AWVALID_M[0]     ),
        .AWREADY_M       ( AWREADY_M[0]     ),
        .WDATA_M         ( WDATA_M  [0]     ),
        .WSTRB_M         ( WSTRB_M  [0]     ),
        .WLAST_M         ( WLAST_M  [0]     ),
        .WVALID_M        ( WVALID_M [0]     ),
        .WREADY_M        ( WREADY_M [0]     ),
        .BID_M           ( BID_M    [0]     ),
        .BRESP_M         ( BRESP_M  [0]     ),
        .BVALID_M        ( BVALID_M [0]     ),
        .BREADY_M        ( BREADY_M [0]     ),

        .ARID_AXI        ( ARID_M_AXI   [0] ),
        .ARADDR_AXI      ( ARADDR_M_AXI [0] ),
        .ARLEN_AXI       ( ARLEN_M_AXI  [0] ),
        .ARSIZE_AXI      ( ARSIZE_M_AXI [0] ),
        .ARBURST_AXI     ( ARBURST_M_AXI[0] ),
        .ARVALID_AXI     ( ARVALID_M_AXI[0] ),
        .ARREADY_AXI     ( ARREADY_M_AXI[0] ),
        .RID_AXI         ( RID_M_AXI    [0] ),
        .RDATA_AXI       ( RDATA_M_AXI  [0] ),
        .RRESP_AXI       ( RRESP_M_AXI  [0] ),
        .RLAST_AXI       ( RLAST_M_AXI  [0] ),
        .RVALID_AXI      ( RVALID_M_AXI [0] ),
        .RREADY_AXI      ( RREADY_M_AXI [0] ),
        .AWID_AXI        ( AWID_M_AXI   [0] ),
        .AWADDR_AXI      ( AWADDR_M_AXI [0] ),
        .AWLEN_AXI       ( AWLEN_M_AXI  [0] ),
        .AWSIZE_AXI      ( AWSIZE_M_AXI [0] ),
        .AWBURST_AXI     ( AWBURST_M_AXI[0] ),
        .AWVALID_AXI     ( AWVALID_M_AXI[0] ),
        .AWREADY_AXI     ( AWREADY_M_AXI[0] ),
        .WDATA_AXI       ( WDATA_M_AXI  [0] ),
        .WSTRB_AXI       ( WSTRB_M_AXI  [0] ),
        .WLAST_AXI       ( WLAST_M_AXI  [0] ),
        .WVALID_AXI      ( WVALID_M_AXI [0] ),
        .WREADY_AXI      ( WREADY_M_AXI [0] ),
        .BID_AXI         ( BID_M_AXI    [0] ),
        .BRESP_AXI       ( BRESP_M_AXI  [0] ),
        .BVALID_AXI      ( BVALID_M_AXI [0] ),
        .BREADY_AXI      ( BREADY_M_AXI [0] )
    );

    AXI_CDC_master i_axi_cdc_master1 (
        .master_clk      ( cpu_clk          ),
        .master_rst      ( cpu_rst          ),
        .axi_clk         ( axi_clk          ),
        .axi_rst         ( axi_rst          ),

        .ARID_M          ( ARID_M   [1]     ),
        .ARADDR_M        ( ARADDR_M [1]     ),
        .ARLEN_M         ( ARLEN_M  [1]     ),
        .ARSIZE_M        ( ARSIZE_M [1]     ),
        .ARBURST_M       ( ARBURST_M[1]     ),
        .ARVALID_M       ( ARVALID_M[1]     ),
        .ARREADY_M       ( ARREADY_M[1]     ),
        .RID_M           ( RID_M    [1]     ),
        .RDATA_M         ( RDATA_M  [1]     ),
        .RRESP_M         ( RRESP_M  [1]     ),
        .RLAST_M         ( RLAST_M  [1]     ),
        .RVALID_M        ( RVALID_M [1]     ),
        .RREADY_M        ( RREADY_M [1]     ),
        .AWID_M          ( AWID_M   [1]     ),
        .AWADDR_M        ( AWADDR_M [1]     ),
        .AWLEN_M         ( AWLEN_M  [1]     ),
        .AWSIZE_M        ( AWSIZE_M [1]     ),
        .AWBURST_M       ( AWBURST_M[1]     ),
        .AWVALID_M       ( AWVALID_M[1]     ),
        .AWREADY_M       ( AWREADY_M[1]     ),
        .WDATA_M         ( WDATA_M  [1]     ),
        .WSTRB_M         ( WSTRB_M  [1]     ),
        .WLAST_M         ( WLAST_M  [1]     ),
        .WVALID_M        ( WVALID_M [1]     ),
        .WREADY_M        ( WREADY_M [1]     ),
        .BID_M           ( BID_M    [1]     ),
        .BRESP_M         ( BRESP_M  [1]     ),
        .BVALID_M        ( BVALID_M [1]     ),
        .BREADY_M        ( BREADY_M [1]     ),

        .ARID_AXI        ( ARID_M_AXI   [1] ),
        .ARADDR_AXI      ( ARADDR_M_AXI [1] ),
        .ARLEN_AXI       ( ARLEN_M_AXI  [1] ),
        .ARSIZE_AXI      ( ARSIZE_M_AXI [1] ),
        .ARBURST_AXI     ( ARBURST_M_AXI[1] ),
        .ARVALID_AXI     ( ARVALID_M_AXI[1] ),
        .ARREADY_AXI     ( ARREADY_M_AXI[1] ),
        .RID_AXI         ( RID_M_AXI    [1] ),
        .RDATA_AXI       ( RDATA_M_AXI  [1] ),
        .RRESP_AXI       ( RRESP_M_AXI  [1] ),
        .RLAST_AXI       ( RLAST_M_AXI  [1] ),
        .RVALID_AXI      ( RVALID_M_AXI [1] ),
        .RREADY_AXI      ( RREADY_M_AXI [1] ),
        .AWID_AXI        ( AWID_M_AXI   [1] ),
        .AWADDR_AXI      ( AWADDR_M_AXI [1] ),
        .AWLEN_AXI       ( AWLEN_M_AXI  [1] ),
        .AWSIZE_AXI      ( AWSIZE_M_AXI [1] ),
        .AWBURST_AXI     ( AWBURST_M_AXI[1] ),
        .AWVALID_AXI     ( AWVALID_M_AXI[1] ),
        .AWREADY_AXI     ( AWREADY_M_AXI[1] ),
        .WDATA_AXI       ( WDATA_M_AXI  [1] ),
        .WSTRB_AXI       ( WSTRB_M_AXI  [1] ),
        .WLAST_AXI       ( WLAST_M_AXI  [1] ),
        .WVALID_AXI      ( WVALID_M_AXI [1] ),
        .WREADY_AXI      ( WREADY_M_AXI [1] ),
        .BID_AXI         ( BID_M_AXI    [1] ),
        .BRESP_AXI       ( BRESP_M_AXI  [1] ),
        .BVALID_AXI      ( BVALID_M_AXI [1] ),
        .BREADY_AXI      ( BREADY_M_AXI [1] )
    );

    AXI_CDC_master i_axi_cdc_master2 (
        .master_clk      ( cpu_clk          ),
        .master_rst      ( cpu_rst          ),
        .axi_clk         ( axi_clk          ),
        .axi_rst         ( axi_rst          ),

        .ARID_M          ( ARID_M   [2]     ),
        .ARADDR_M        ( ARADDR_M [2]     ),
        .ARLEN_M         ( ARLEN_M  [2]     ),
        .ARSIZE_M        ( ARSIZE_M [2]     ),
        .ARBURST_M       ( ARBURST_M[2]     ),
        .ARVALID_M       ( ARVALID_M[2]     ),
        .ARREADY_M       ( ARREADY_M[2]     ),
        .RID_M           ( RID_M    [2]     ),
        .RDATA_M         ( RDATA_M  [2]     ),
        .RRESP_M         ( RRESP_M  [2]     ),
        .RLAST_M         ( RLAST_M  [2]     ),
        .RVALID_M        ( RVALID_M [2]     ),
        .RREADY_M        ( RREADY_M [2]     ),
        .AWID_M          ( AWID_M   [2]     ),
        .AWADDR_M        ( AWADDR_M [2]     ),
        .AWLEN_M         ( AWLEN_M  [2]     ),
        .AWSIZE_M        ( AWSIZE_M [2]     ),
        .AWBURST_M       ( AWBURST_M[2]     ),
        .AWVALID_M       ( AWVALID_M[2]     ),
        .AWREADY_M       ( AWREADY_M[2]     ),
        .WDATA_M         ( WDATA_M  [2]     ),
        .WSTRB_M         ( WSTRB_M  [2]     ),
        .WLAST_M         ( WLAST_M  [2]     ),
        .WVALID_M        ( WVALID_M [2]     ),
        .WREADY_M        ( WREADY_M [2]     ),
        .BID_M           ( BID_M    [2]     ),
        .BRESP_M         ( BRESP_M  [2]     ),
        .BVALID_M        ( BVALID_M [2]     ),
        .BREADY_M        ( BREADY_M [2]     ),

        .ARID_AXI        ( ARID_M_AXI   [2] ),
        .ARADDR_AXI      ( ARADDR_M_AXI [2] ),
        .ARLEN_AXI       ( ARLEN_M_AXI  [2] ),
        .ARSIZE_AXI      ( ARSIZE_M_AXI [2] ),
        .ARBURST_AXI     ( ARBURST_M_AXI[2] ),
        .ARVALID_AXI     ( ARVALID_M_AXI[2] ),
        .ARREADY_AXI     ( ARREADY_M_AXI[2] ),
        .RID_AXI         ( RID_M_AXI    [2] ),
        .RDATA_AXI       ( RDATA_M_AXI  [2] ),
        .RRESP_AXI       ( RRESP_M_AXI  [2] ),
        .RLAST_AXI       ( RLAST_M_AXI  [2] ),
        .RVALID_AXI      ( RVALID_M_AXI [2] ),
        .RREADY_AXI      ( RREADY_M_AXI [2] ),
        .AWID_AXI        ( AWID_M_AXI   [2] ),
        .AWADDR_AXI      ( AWADDR_M_AXI [2] ),
        .AWLEN_AXI       ( AWLEN_M_AXI  [2] ),
        .AWSIZE_AXI      ( AWSIZE_M_AXI [2] ),
        .AWBURST_AXI     ( AWBURST_M_AXI[2] ),
        .AWVALID_AXI     ( AWVALID_M_AXI[2] ),
        .AWREADY_AXI     ( AWREADY_M_AXI[2] ),
        .WDATA_AXI       ( WDATA_M_AXI  [2] ),
        .WSTRB_AXI       ( WSTRB_M_AXI  [2] ),
        .WLAST_AXI       ( WLAST_M_AXI  [2] ),
        .WVALID_AXI      ( WVALID_M_AXI [2] ),
        .WREADY_AXI      ( WREADY_M_AXI [2] ),
        .BID_AXI         ( BID_M_AXI    [2] ),
        .BRESP_AXI       ( BRESP_M_AXI  [2] ),
        .BVALID_AXI      ( BVALID_M_AXI [2] ),
        .BREADY_AXI      ( BREADY_M_AXI [2] )
    );

    // --------------------------------------------
    //                 AXI bridge                  
    // --------------------------------------------
    AXI_bridge i_AXI_bridge (
        .ACLK            ( axi_clk          ),
        .ARESET          ( axi_rst          ),

        .ARID_M          ( ARID_M_AXI       ),
        .ARADDR_M        ( ARADDR_M_AXI     ),
        .ARLEN_M         ( ARLEN_M_AXI      ),
        .ARSIZE_M        ( ARSIZE_M_AXI     ),
        .ARBURST_M       ( ARBURST_M_AXI    ),
        .ARVALID_M       ( ARVALID_M_AXI    ),
        .ARREADY_M       ( ARREADY_M_AXI    ),
        .RID_M           ( RID_M_AXI        ),
        .RDATA_M         ( RDATA_M_AXI      ),
        .RRESP_M         ( RRESP_M_AXI      ),
        .RLAST_M         ( RLAST_M_AXI      ),
        .RVALID_M        ( RVALID_M_AXI     ),
        .RREADY_M        ( RREADY_M_AXI     ),
        .AWID_M          ( AWID_M_AXI       ),
        .AWADDR_M        ( AWADDR_M_AXI     ),
        .AWLEN_M         ( AWLEN_M_AXI      ),
        .AWSIZE_M        ( AWSIZE_M_AXI     ),
        .AWBURST_M       ( AWBURST_M_AXI    ),
        .AWVALID_M       ( AWVALID_M_AXI    ),
        .AWREADY_M       ( AWREADY_M_AXI    ),
        .WDATA_M         ( WDATA_M_AXI      ),
        .WSTRB_M         ( WSTRB_M_AXI      ),
        .WLAST_M         ( WLAST_M_AXI      ),
        .WVALID_M        ( WVALID_M_AXI     ),
        .WREADY_M        ( WREADY_M_AXI     ),
        .BID_M           ( BID_M_AXI        ),
        .BRESP_M         ( BRESP_M_AXI      ),
        .BVALID_M        ( BVALID_M_AXI     ),
        .BREADY_M        ( BREADY_M_AXI     ),

        .ARID_S          ( ARID_AXI_S       ),
        .ARADDR_S        ( ARADDR_AXI_S     ),
        .ARLEN_S         ( ARLEN_AXI_S      ),
        .ARSIZE_S        ( ARSIZE_AXI_S     ),
        .ARBURST_S       ( ARBURST_AXI_S    ),
        .ARVALID_S       ( ARVALID_AXI_S    ),
        .ARREADY_S       ( ARREADY_AXI_S    ),
        .RID_S           ( RID_AXI_S        ),
        .RDATA_S         ( RDATA_AXI_S      ),
        .RRESP_S         ( RRESP_AXI_S      ),
        .RLAST_S         ( RLAST_AXI_S      ),
        .RVALID_S        ( RVALID_AXI_S     ),
        .RREADY_S        ( RREADY_AXI_S     ),
        .AWID_S          ( AWID_AXI_S       ),
        .AWADDR_S        ( AWADDR_AXI_S     ),
        .AWLEN_S         ( AWLEN_AXI_S      ),
        .AWSIZE_S        ( AWSIZE_AXI_S     ),
        .AWBURST_S       ( AWBURST_AXI_S    ),
        .AWVALID_S       ( AWVALID_AXI_S    ),
        .AWREADY_S       ( AWREADY_AXI_S    ),
        .WDATA_S         ( WDATA_AXI_S      ),
        .WSTRB_S         ( WSTRB_AXI_S      ),
        .WLAST_S         ( WLAST_AXI_S      ),
        .WVALID_S        ( WVALID_AXI_S     ),
        .WREADY_S        ( WREADY_AXI_S     ),
        .BID_S           ( BID_AXI_S        ),
        .BRESP_S         ( BRESP_AXI_S      ),
        .BVALID_S        ( BVALID_AXI_S     ),
        .BREADY_S        ( BREADY_AXI_S     )
    );

    // --------------------------------------------
    //            axi <-> fifo <-> slave           
    // --------------------------------------------
    AXI_CDC_slave i_axi_cdc_slave0 (
        .axi_clk         ( axi_clk          ),
        .axi_rst         ( axi_rst          ),
        .slave_clk       ( rom_clk          ),
        .slave_rst       ( rom_rst          ),

        .ARID_AXI        ( ARID_AXI_S   [0] ),
        .ARADDR_AXI      ( ARADDR_AXI_S [0] ),
        .ARLEN_AXI       ( ARLEN_AXI_S  [0] ),
        .ARSIZE_AXI      ( ARSIZE_AXI_S [0] ),
        .ARBURST_AXI     ( ARBURST_AXI_S[0] ),
        .ARVALID_AXI     ( ARVALID_AXI_S[0] ),
        .ARREADY_AXI     ( ARREADY_AXI_S[0] ),
        .RID_AXI         ( RID_AXI_S    [0] ),
        .RDATA_AXI       ( RDATA_AXI_S  [0] ),
        .RRESP_AXI       ( RRESP_AXI_S  [0] ),
        .RLAST_AXI       ( RLAST_AXI_S  [0] ),
        .RVALID_AXI      ( RVALID_AXI_S [0] ),
        .RREADY_AXI      ( RREADY_AXI_S [0] ),
        .AWID_AXI        ( AWID_AXI_S   [0] ),
        .AWADDR_AXI      ( AWADDR_AXI_S [0] ),
        .AWLEN_AXI       ( AWLEN_AXI_S  [0] ),
        .AWSIZE_AXI      ( AWSIZE_AXI_S [0] ),
        .AWBURST_AXI     ( AWBURST_AXI_S[0] ),
        .AWVALID_AXI     ( AWVALID_AXI_S[0] ),
        .AWREADY_AXI     ( AWREADY_AXI_S[0] ),
        .WDATA_AXI       ( WDATA_AXI_S  [0] ),
        .WSTRB_AXI       ( WSTRB_AXI_S  [0] ),
        .WLAST_AXI       ( WLAST_AXI_S  [0] ),
        .WVALID_AXI      ( WVALID_AXI_S [0] ),
        .WREADY_AXI      ( WREADY_AXI_S [0] ),
        .BID_AXI         ( BID_AXI_S    [0] ),
        .BRESP_AXI       ( BRESP_AXI_S  [0] ),
        .BVALID_AXI      ( BVALID_AXI_S [0] ),
        .BREADY_AXI      ( BREADY_AXI_S [0] ),

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

    AXI_CDC_slave i_axi_cdc_slave1 (
        .axi_clk         ( axi_clk          ),
        .axi_rst         ( axi_rst          ),
        .slave_clk       ( cpu_clk          ),
        .slave_rst       ( cpu_rst          ),

        .ARID_AXI        ( ARID_AXI_S   [1] ),
        .ARADDR_AXI      ( ARADDR_AXI_S [1] ),
        .ARLEN_AXI       ( ARLEN_AXI_S  [1] ),
        .ARSIZE_AXI      ( ARSIZE_AXI_S [1] ),
        .ARBURST_AXI     ( ARBURST_AXI_S[1] ),
        .ARVALID_AXI     ( ARVALID_AXI_S[1] ),
        .ARREADY_AXI     ( ARREADY_AXI_S[1] ),
        .RID_AXI         ( RID_AXI_S    [1] ),
        .RDATA_AXI       ( RDATA_AXI_S  [1] ),
        .RRESP_AXI       ( RRESP_AXI_S  [1] ),
        .RLAST_AXI       ( RLAST_AXI_S  [1] ),
        .RVALID_AXI      ( RVALID_AXI_S [1] ),
        .RREADY_AXI      ( RREADY_AXI_S [1] ),
        .AWID_AXI        ( AWID_AXI_S   [1] ),
        .AWADDR_AXI      ( AWADDR_AXI_S [1] ),
        .AWLEN_AXI       ( AWLEN_AXI_S  [1] ),
        .AWSIZE_AXI      ( AWSIZE_AXI_S [1] ),
        .AWBURST_AXI     ( AWBURST_AXI_S[1] ),
        .AWVALID_AXI     ( AWVALID_AXI_S[1] ),
        .AWREADY_AXI     ( AWREADY_AXI_S[1] ),
        .WDATA_AXI       ( WDATA_AXI_S  [1] ),
        .WSTRB_AXI       ( WSTRB_AXI_S  [1] ),
        .WLAST_AXI       ( WLAST_AXI_S  [1] ),
        .WVALID_AXI      ( WVALID_AXI_S [1] ),
        .WREADY_AXI      ( WREADY_AXI_S [1] ),
        .BID_AXI         ( BID_AXI_S    [1] ),
        .BRESP_AXI       ( BRESP_AXI_S  [1] ),
        .BVALID_AXI      ( BVALID_AXI_S [1] ),
        .BREADY_AXI      ( BREADY_AXI_S [1] ),

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

    AXI_CDC_slave i_axi_cdc_slave2 (
        .axi_clk         ( axi_clk          ),
        .axi_rst         ( axi_rst          ),
        .slave_clk       ( cpu_clk          ),
        .slave_rst       ( cpu_rst          ),

        .ARID_AXI        ( ARID_AXI_S   [2] ),
        .ARADDR_AXI      ( ARADDR_AXI_S [2] ),
        .ARLEN_AXI       ( ARLEN_AXI_S  [2] ),
        .ARSIZE_AXI      ( ARSIZE_AXI_S [2] ),
        .ARBURST_AXI     ( ARBURST_AXI_S[2] ),
        .ARVALID_AXI     ( ARVALID_AXI_S[2] ),
        .ARREADY_AXI     ( ARREADY_AXI_S[2] ),
        .RID_AXI         ( RID_AXI_S    [2] ),
        .RDATA_AXI       ( RDATA_AXI_S  [2] ),
        .RRESP_AXI       ( RRESP_AXI_S  [2] ),
        .RLAST_AXI       ( RLAST_AXI_S  [2] ),
        .RVALID_AXI      ( RVALID_AXI_S [2] ),
        .RREADY_AXI      ( RREADY_AXI_S [2] ),
        .AWID_AXI        ( AWID_AXI_S   [2] ),
        .AWADDR_AXI      ( AWADDR_AXI_S [2] ),
        .AWLEN_AXI       ( AWLEN_AXI_S  [2] ),
        .AWSIZE_AXI      ( AWSIZE_AXI_S [2] ),
        .AWBURST_AXI     ( AWBURST_AXI_S[2] ),
        .AWVALID_AXI     ( AWVALID_AXI_S[2] ),
        .AWREADY_AXI     ( AWREADY_AXI_S[2] ),
        .WDATA_AXI       ( WDATA_AXI_S  [2] ),
        .WSTRB_AXI       ( WSTRB_AXI_S  [2] ),
        .WLAST_AXI       ( WLAST_AXI_S  [2] ),
        .WVALID_AXI      ( WVALID_AXI_S [2] ),
        .WREADY_AXI      ( WREADY_AXI_S [2] ),
        .BID_AXI         ( BID_AXI_S    [2] ),
        .BRESP_AXI       ( BRESP_AXI_S  [2] ),
        .BVALID_AXI      ( BVALID_AXI_S [2] ),
        .BREADY_AXI      ( BREADY_AXI_S [2] ),

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

    AXI_CDC_slave i_axi_cdc_slave3 (
        .axi_clk         ( axi_clk          ),
        .axi_rst         ( axi_rst          ),
        .slave_clk       ( cpu_clk          ),
        .slave_rst       ( cpu_rst          ),

        .ARID_AXI        ( ARID_AXI_S   [3] ),
        .ARADDR_AXI      ( ARADDR_AXI_S [3] ),
        .ARLEN_AXI       ( ARLEN_AXI_S  [3] ),
        .ARSIZE_AXI      ( ARSIZE_AXI_S [3] ),
        .ARBURST_AXI     ( ARBURST_AXI_S[3] ),
        .ARVALID_AXI     ( ARVALID_AXI_S[3] ),
        .ARREADY_AXI     ( ARREADY_AXI_S[3] ),
        .RID_AXI         ( RID_AXI_S    [3] ),
        .RDATA_AXI       ( RDATA_AXI_S  [3] ),
        .RRESP_AXI       ( RRESP_AXI_S  [3] ),
        .RLAST_AXI       ( RLAST_AXI_S  [3] ),
        .RVALID_AXI      ( RVALID_AXI_S [3] ),
        .RREADY_AXI      ( RREADY_AXI_S [3] ),
        .AWID_AXI        ( AWID_AXI_S   [3] ),
        .AWADDR_AXI      ( AWADDR_AXI_S [3] ),
        .AWLEN_AXI       ( AWLEN_AXI_S  [3] ),
        .AWSIZE_AXI      ( AWSIZE_AXI_S [3] ),
        .AWBURST_AXI     ( AWBURST_AXI_S[3] ),
        .AWVALID_AXI     ( AWVALID_AXI_S[3] ),
        .AWREADY_AXI     ( AWREADY_AXI_S[3] ),
        .WDATA_AXI       ( WDATA_AXI_S  [3] ),
        .WSTRB_AXI       ( WSTRB_AXI_S  [3] ),
        .WLAST_AXI       ( WLAST_AXI_S  [3] ),
        .WVALID_AXI      ( WVALID_AXI_S [3] ),
        .WREADY_AXI      ( WREADY_AXI_S [3] ),
        .BID_AXI         ( BID_AXI_S    [3] ),
        .BRESP_AXI       ( BRESP_AXI_S  [3] ),
        .BVALID_AXI      ( BVALID_AXI_S [3] ),
        .BREADY_AXI      ( BREADY_AXI_S [3] ),

        .ARID_S          ( ARID_S   [3]     ),
        .ARADDR_S        ( ARADDR_S [3]     ),
        .ARLEN_S         ( ARLEN_S  [3]     ),
        .ARSIZE_S        ( ARSIZE_S [3]     ),
        .ARBURST_S       ( ARBURST_S[3]     ),
        .ARVALID_S       ( ARVALID_S[3]     ),
        .ARREADY_S       ( ARREADY_S[3]     ),
        .RID_S           ( RID_S    [3]     ),
        .RDATA_S         ( RDATA_S  [3]     ),
        .RRESP_S         ( RRESP_S  [3]     ),
        .RLAST_S         ( RLAST_S  [3]     ),
        .RVALID_S        ( RVALID_S [3]     ),
        .RREADY_S        ( RREADY_S [3]     ),
        .AWID_S          ( AWID_S   [3]     ),
        .AWADDR_S        ( AWADDR_S [3]     ),
        .AWLEN_S         ( AWLEN_S  [3]     ),
        .AWSIZE_S        ( AWSIZE_S [3]     ),
        .AWBURST_S       ( AWBURST_S[3]     ),
        .AWVALID_S       ( AWVALID_S[3]     ),
        .AWREADY_S       ( AWREADY_S[3]     ),
        .WDATA_S         ( WDATA_S  [3]     ),
        .WSTRB_S         ( WSTRB_S  [3]     ),
        .WLAST_S         ( WLAST_S  [3]     ),
        .WVALID_S        ( WVALID_S [3]     ),
        .WREADY_S        ( WREADY_S [3]     ),
        .BID_S           ( BID_S    [3]     ),
        .BRESP_S         ( BRESP_S  [3]     ),
        .BVALID_S        ( BVALID_S [3]     ),
        .BREADY_S        ( BREADY_S [3]     )
    );

    AXI_CDC_slave i_axi_cdc_slave4 (
        .axi_clk         ( axi_clk          ),
        .axi_rst         ( axi_rst          ),
        .slave_clk       ( rom_clk          ),
        .slave_rst       ( rom_rst          ),

        .ARID_AXI        ( ARID_AXI_S   [4] ),
        .ARADDR_AXI      ( ARADDR_AXI_S [4] ),
        .ARLEN_AXI       ( ARLEN_AXI_S  [4] ),
        .ARSIZE_AXI      ( ARSIZE_AXI_S [4] ),
        .ARBURST_AXI     ( ARBURST_AXI_S[4] ),
        .ARVALID_AXI     ( ARVALID_AXI_S[4] ),
        .ARREADY_AXI     ( ARREADY_AXI_S[4] ),
        .RID_AXI         ( RID_AXI_S    [4] ),
        .RDATA_AXI       ( RDATA_AXI_S  [4] ),
        .RRESP_AXI       ( RRESP_AXI_S  [4] ),
        .RLAST_AXI       ( RLAST_AXI_S  [4] ),
        .RVALID_AXI      ( RVALID_AXI_S [4] ),
        .RREADY_AXI      ( RREADY_AXI_S [4] ),
        .AWID_AXI        ( AWID_AXI_S   [4] ),
        .AWADDR_AXI      ( AWADDR_AXI_S [4] ),
        .AWLEN_AXI       ( AWLEN_AXI_S  [4] ),
        .AWSIZE_AXI      ( AWSIZE_AXI_S [4] ),
        .AWBURST_AXI     ( AWBURST_AXI_S[4] ),
        .AWVALID_AXI     ( AWVALID_AXI_S[4] ),
        .AWREADY_AXI     ( AWREADY_AXI_S[4] ),
        .WDATA_AXI       ( WDATA_AXI_S  [4] ),
        .WSTRB_AXI       ( WSTRB_AXI_S  [4] ),
        .WLAST_AXI       ( WLAST_AXI_S  [4] ),
        .WVALID_AXI      ( WVALID_AXI_S [4] ),
        .WREADY_AXI      ( WREADY_AXI_S [4] ),
        .BID_AXI         ( BID_AXI_S    [4] ),
        .BRESP_AXI       ( BRESP_AXI_S  [4] ),
        .BVALID_AXI      ( BVALID_AXI_S [4] ),
        .BREADY_AXI      ( BREADY_AXI_S [4] ),

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

    AXI_CDC_slave i_axi_cdc_slave5 (
        .axi_clk         ( axi_clk          ),
        .axi_rst         ( axi_rst          ),
        .slave_clk       ( dram_clk         ),
        .slave_rst       ( dram_rst         ),

        .ARID_AXI        ( ARID_AXI_S   [5] ),
        .ARADDR_AXI      ( ARADDR_AXI_S [5] ),
        .ARLEN_AXI       ( ARLEN_AXI_S  [5] ),
        .ARSIZE_AXI      ( ARSIZE_AXI_S [5] ),
        .ARBURST_AXI     ( ARBURST_AXI_S[5] ),
        .ARVALID_AXI     ( ARVALID_AXI_S[5] ),
        .ARREADY_AXI     ( ARREADY_AXI_S[5] ),
        .RID_AXI         ( RID_AXI_S    [5] ),
        .RDATA_AXI       ( RDATA_AXI_S  [5] ),
        .RRESP_AXI       ( RRESP_AXI_S  [5] ),
        .RLAST_AXI       ( RLAST_AXI_S  [5] ),
        .RVALID_AXI      ( RVALID_AXI_S [5] ),
        .RREADY_AXI      ( RREADY_AXI_S [5] ),
        .AWID_AXI        ( AWID_AXI_S   [5] ),
        .AWADDR_AXI      ( AWADDR_AXI_S [5] ),
        .AWLEN_AXI       ( AWLEN_AXI_S  [5] ),
        .AWSIZE_AXI      ( AWSIZE_AXI_S [5] ),
        .AWBURST_AXI     ( AWBURST_AXI_S[5] ),
        .AWVALID_AXI     ( AWVALID_AXI_S[5] ),
        .AWREADY_AXI     ( AWREADY_AXI_S[5] ),
        .WDATA_AXI       ( WDATA_AXI_S  [5] ),
        .WSTRB_AXI       ( WSTRB_AXI_S  [5] ),
        .WLAST_AXI       ( WLAST_AXI_S  [5] ),
        .WVALID_AXI      ( WVALID_AXI_S [5] ),
        .WREADY_AXI      ( WREADY_AXI_S [5] ),
        .BID_AXI         ( BID_AXI_S    [5] ),
        .BRESP_AXI       ( BRESP_AXI_S  [5] ),
        .BVALID_AXI      ( BVALID_AXI_S [5] ),
        .BREADY_AXI      ( BREADY_AXI_S [5] ),

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