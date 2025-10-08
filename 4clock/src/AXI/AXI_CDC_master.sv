module AXI_CDC_master (
    input  logic                     master_clk,
    input  logic                     master_rst,
    input  logic                     axi_clk,
    input  logic                     axi_rst,

    // INTERFACE FOR MASTERS
    // AR channel
    input  logic [`AXI_ID_BITS  -1:0] ARID_M,
    input  logic [`AXI_DATA_BITS-1:0] ARADDR_M,
    input  logic [`AXI_LEN_BITS -1:0] ARLEN_M,
    input  logic [`AXI_SIZE_BITS-1:0] ARSIZE_M,
    input  logic [1:0]                ARBURST_M,
    input  logic                      ARVALID_M,
    output logic                      ARREADY_M,
    // R channel
    output logic [`AXI_ID_BITS  -1:0] RID_M,
    output logic [`AXI_DATA_BITS-1:0] RDATA_M,
    output logic [1:0]                RRESP_M,
    output logic                      RLAST_M,
    output logic                      RVALID_M,
    input  logic                      RREADY_M,
    // AW channel
    input  logic [`AXI_ID_BITS  -1:0] AWID_M,
    input  logic [`AXI_ADDR_BITS-1:0] AWADDR_M,
    input  logic [`AXI_LEN_BITS -1:0] AWLEN_M,
    input  logic [`AXI_SIZE_BITS-1:0] AWSIZE_M,
    input  logic [1:0]                AWBURST_M,
    input  logic                      AWVALID_M,
    output logic                      AWREADY_M,
    // W channel
    input  logic [`AXI_DATA_BITS-1:0] WDATA_M,
    input  logic [`AXI_STRB_BITS-1:0] WSTRB_M,
    input  logic                      WLAST_M,
    input  logic                      WVALID_M,
    output logic                      WREADY_M,
    // B channel
    output logic [`AXI_ID_BITS  -1:0] BID_M,
    output logic [1:0]                BRESP_M,
    output logic                      BVALID_M,
    input  logic                      BREADY_M,

    // INTERFACE FOR AXI
    // AR channel
    output logic [`AXI_ID_BITS  -1:0] ARID_AXI,
    output logic [`AXI_DATA_BITS-1:0] ARADDR_AXI,
    output logic [`AXI_LEN_BITS -1:0] ARLEN_AXI,
    output logic [`AXI_SIZE_BITS-1:0] ARSIZE_AXI,
    output logic [1:0]                ARBURST_AXI,
    output logic                      ARVALID_AXI,
    input  logic                      ARREADY_AXI,
    // R channel
    input  logic [`AXI_ID_BITS  -1:0] RID_AXI,
    input  logic [`AXI_DATA_BITS-1:0] RDATA_AXI,
    input  logic [1:0]                RRESP_AXI,
    input  logic                      RLAST_AXI,
    input  logic                      RVALID_AXI,
    output logic                      RREADY_AXI,
    // AW channel
    output logic [`AXI_ID_BITS  -1:0] AWID_AXI,
    output logic [`AXI_ADDR_BITS-1:0] AWADDR_AXI,
    output logic [`AXI_LEN_BITS -1:0] AWLEN_AXI,
    output logic [`AXI_SIZE_BITS-1:0] AWSIZE_AXI,
    output logic [1:0]                AWBURST_AXI,
    output logic                      AWVALID_AXI,
    input  logic                      AWREADY_AXI,
    // W channel
    output logic [`AXI_DATA_BITS-1:0] WDATA_AXI,
    output logic [`AXI_STRB_BITS-1:0] WSTRB_AXI,
    output logic                      WLAST_AXI,
    output logic                      WVALID_AXI,
    input  logic                      WREADY_AXI,
    // B channel
    input  logic [`AXI_ID_BITS -1:0]  BID_AXI,
    input  logic [1:0]                BRESP_AXI,
    input  logic                      BVALID_AXI,
    output logic                      BREADY_AXI
);

    // --------------------------------------------
    //              Signal Declaration             
    // --------------------------------------------
    // AR channel : master -> fifo -> axi
    logic [44:0] AR_master_data, AR_axi_data;
    logic        AR_full, AR_empty;
    logic        AR_mf_handshake;   // master and fifo handshake
    logic        AR_axi_handshake;  // axi handshake

    // R channel : axi -> fifo -> master
    logic [38:0] R_axi_data, R_master_data;
    logic        R_full, R_empty;
    logic        R_axi_handshake;
    logic        R_mf_handshake;

    // AW channel : master -> fifo -> axi
    logic [44:0] AW_master_data, AW_axi_data;
    logic        AW_full, AW_empty;
    logic        AW_mf_handshake;   // master and fifo handshake
    logic        AW_axi_handshake;  // axi handshake

    // W channel : master -> fifo -> axi
    logic [36:0] W_master_data, W_axi_data;
    logic        W_full, W_empty;
    logic        W_mf_handshake;   // master and fifo handshake
    logic        W_axi_handshake;  // axi handshake

    // B channel : axi -> fifo -> axi
    logic [5:0]  B_axi_data, B_master_data;
    logic        B_full, B_empty;
    logic        B_axi_handshake;
    logic        B_mf_handshake;

    // --------------------------------------------
    //                  AR channel                 
    // --------------------------------------------
    assign ARREADY_M   = ~AR_full;
    assign ARVALID_AXI = ~AR_empty;
    assign ARID_AXI    = AR_axi_data[44:41];
    assign ARADDR_AXI  = AR_axi_data[40: 9];
    assign ARLEN_AXI   = AR_axi_data[ 8: 5];
    assign ARSIZE_AXI  = AR_axi_data[ 4: 2];
    assign ARBURST_AXI = AR_axi_data[ 1: 0];

    assign AR_mf_handshake  = ARVALID_M   && ARREADY_M;
    assign AR_axi_handshake = ARVALID_AXI && ARREADY_AXI;
    assign AR_master_data   = {ARID_M, ARADDR_M, ARLEN_M, ARSIZE_M, ARBURST_M};

    AR_FIFO i_AR_FIFO (
        .w_clk   ( master_clk       ),
        .w_rst   ( master_rst       ),
        .w_push  ( AR_mf_handshake  ),
        .w_data  ( AR_master_data   ),
        .w_full  ( AR_full          ),

        .r_clk   ( axi_clk          ),
        .r_rst   ( axi_rst          ),
        .r_pop   ( AR_axi_handshake ),
        .r_data  ( AR_axi_data      ),
        .r_empty ( AR_empty         )
    );

    // --------------------------------------------
    //                   R channel                 
    // --------------------------------------------
    assign RREADY_AXI = ~R_full;
    assign RVALID_M   = ~R_empty;
    assign RID_M      = R_master_data[38:35];
    assign RDATA_M    = R_master_data[34: 3];
    assign RRESP_M    = R_master_data[2 : 1];
    assign RLAST_M    = R_master_data[0];

    assign R_axi_handshake = RVALID_AXI && RREADY_AXI;
    assign R_mf_handshake  = RVALID_M   && RREADY_M;
    assign R_axi_data      = {RID_AXI, RDATA_AXI, RRESP_AXI, RLAST_AXI};

    R_FIFO i_R_FIFO (
        .w_clk   ( axi_clk          ),
        .w_rst   ( axi_rst          ),
        .w_push  ( R_axi_handshake  ),
        .w_data  ( R_axi_data       ),
        .w_full  ( R_full           ),

        .r_clk   ( master_clk       ),
        .r_rst   ( master_rst       ),
        .r_pop   ( R_mf_handshake   ),
        .r_data  ( R_master_data    ),
        .r_empty ( R_empty          )
    );

    // --------------------------------------------
    //                  AW channel                 
    // --------------------------------------------
    assign AWREADY_M   = ~AW_full;
    assign AWVALID_AXI = ~AW_empty;
    assign AWID_AXI    = AW_axi_data[44:41];
    assign AWADDR_AXI  = AW_axi_data[40: 9];
    assign AWLEN_AXI   = AW_axi_data[ 8: 5];
    assign AWSIZE_AXI  = AW_axi_data[ 4: 2];
    assign AWBURST_AXI = AW_axi_data[ 1: 0];

    assign AW_mf_handshake  = AWVALID_M   && AWREADY_M;
    assign AW_axi_handshake = AWVALID_AXI && AWREADY_AXI;
    assign AW_master_data   = {AWID_M, AWADDR_M, AWLEN_M, AWSIZE_M, AWBURST_M};

    AW_FIFO i_AW_FIFO (
        .w_clk   ( master_clk       ),
        .w_rst   ( master_rst       ),
        .w_push  ( AW_mf_handshake  ),
        .w_data  ( AW_master_data   ),
        .w_full  ( AW_full          ),

        .r_clk   ( axi_clk          ),
        .r_rst   ( axi_rst          ),
        .r_pop   ( AW_axi_handshake ),
        .r_data  ( AW_axi_data      ),
        .r_empty ( AW_empty         )
    );

    // --------------------------------------------
    //                  W channel                 
    // --------------------------------------------
    assign WREADY_M   = ~W_full;
    assign WVALID_AXI = ~W_empty;
    assign WDATA_AXI  = W_axi_data[36:5];
    assign WSTRB_AXI  = W_axi_data[ 4:1];
    assign WLAST_AXI  = W_axi_data[0];

    assign W_mf_handshake  = WVALID_M   && WREADY_M;
    assign W_axi_handshake = WVALID_AXI && WREADY_AXI;
    assign W_master_data   = {WDATA_M, WSTRB_M, WLAST_M};

    W_FIFO i_W_FIFO (
        .w_clk   ( master_clk       ),
        .w_rst   ( master_rst       ),
        .w_push  ( W_mf_handshake   ),
        .w_data  ( W_master_data    ),
        .w_full  ( W_full           ),

        .r_clk   ( axi_clk          ),
        .r_rst   ( axi_rst          ),
        .r_pop   ( W_axi_handshake  ),
        .r_data  ( W_axi_data       ),
        .r_empty ( W_empty          )
    );

    // --------------------------------------------
    //                   B channel                 
    // --------------------------------------------
    assign BREADY_AXI = ~B_full;
    assign BVALID_M   = ~B_empty;
    assign BID_M      = B_master_data[5:2];
    assign BRESP_M    = B_master_data[1:0];

    assign B_axi_handshake = BVALID_AXI && BREADY_AXI;
    assign B_mf_handshake  = BVALID_M   && BREADY_M;
    assign B_axi_data      = {BID_AXI, BRESP_AXI};

    B_FIFO i_B_FIFO (
        .w_clk   ( axi_clk          ),
        .w_rst   ( axi_rst          ),
        .w_push  ( B_axi_handshake  ),
        .w_data  ( B_axi_data       ),
        .w_full  ( B_full           ),

        .r_clk   ( master_clk       ),
        .r_rst   ( master_rst       ),
        .r_pop   ( B_mf_handshake   ),
        .r_data  ( B_master_data    ),
        .r_empty ( B_empty          )
    );

endmodule