module AXI_CDC_slave (
    input  logic                      axi_clk,
    input  logic                      axi_rst,
    input  logic                      slave_clk,
    input  logic                      slave_rst,

    // INTERFACE FOR AXI
    // AR channel
    input  logic [`AXI_IDS_BITS -1:0] ARID_AXI,
    input  logic [`AXI_DATA_BITS-1:0] ARADDR_AXI,
    input  logic [`AXI_LEN_BITS -1:0] ARLEN_AXI,
    input  logic [`AXI_SIZE_BITS-1:0] ARSIZE_AXI,
    input  logic [1:0]                ARBURST_AXI,
    input  logic                      ARVALID_AXI,
    output logic                      ARREADY_AXI,
    // R channel
    output logic [`AXI_IDS_BITS -1:0] RID_AXI,
    output logic [`AXI_DATA_BITS-1:0] RDATA_AXI,
    output logic [1:0]                RRESP_AXI,
    output logic                      RLAST_AXI,
    output logic                      RVALID_AXI,
    input  logic                      RREADY_AXI,
    // AW channel
    input  logic [`AXI_IDS_BITS -1:0] AWID_AXI,
    input  logic [`AXI_ADDR_BITS-1:0] AWADDR_AXI,
    input  logic [`AXI_LEN_BITS -1:0] AWLEN_AXI,
    input  logic [`AXI_SIZE_BITS-1:0] AWSIZE_AXI,
    input  logic [1:0]                AWBURST_AXI,
    input  logic                      AWVALID_AXI,
    output logic                      AWREADY_AXI,
    // W channel
    input  logic [`AXI_DATA_BITS-1:0] WDATA_AXI,
    input  logic [`AXI_STRB_BITS-1:0] WSTRB_AXI,
    input  logic                      WLAST_AXI,
    input  logic                      WVALID_AXI,
    output logic                      WREADY_AXI,
    // B channel
    output logic [`AXI_IDS_BITS -1:0] BID_AXI,
    output logic [1:0]                BRESP_AXI,
    output logic                      BVALID_AXI,
    input  logic                      BREADY_AXI,

    // INTERFACE FOR SLAVE
    // AR channel
    output logic [`AXI_IDS_BITS -1:0] ARID_S,
    output logic [`AXI_DATA_BITS-1:0] ARADDR_S,
    output logic [`AXI_LEN_BITS -1:0] ARLEN_S,
    output logic [`AXI_SIZE_BITS-1:0] ARSIZE_S,
    output logic [1:0]                ARBURST_S,
    output logic                      ARVALID_S,
    input  logic                      ARREADY_S,
    // R channel
    input  logic [`AXI_IDS_BITS -1:0] RID_S,
    input  logic [`AXI_DATA_BITS-1:0] RDATA_S,
    input  logic [1:0]                RRESP_S,
    input  logic                      RLAST_S,
    input  logic                      RVALID_S,
    output logic                      RREADY_S,
    // AW channel
    output logic [`AXI_IDS_BITS -1:0] AWID_S,
    output logic [`AXI_ADDR_BITS-1:0] AWADDR_S,
    output logic [`AXI_LEN_BITS -1:0] AWLEN_S,
    output logic [`AXI_SIZE_BITS-1:0] AWSIZE_S,
    output logic [1:0]                AWBURST_S,
    output logic                      AWVALID_S,
    input  logic                      AWREADY_S,
    // W channel
    output logic [`AXI_DATA_BITS-1:0] WDATA_S,
    output logic [`AXI_STRB_BITS-1:0] WSTRB_S,
    output logic                      WLAST_S,
    output logic                      WVALID_S,
    input  logic                      WREADY_S,
    // B channel
    input  logic [`AXI_IDS_BITS -1:0] BID_S,
    input  logic [1:0]                BRESP_S,
    input  logic                      BVALID_S,
    output logic                      BREADY_S
);

    // --------------------------------------------
    //              Signal Declaration             
    // --------------------------------------------
    // axi -> fifo -> slave
    logic [44:0] AR_axi_data, AR_slave_data;
    logic        AR_full, AR_empty;
    logic        AR_axi_handshake;
    logic        AR_sf_handshake;

    // slave -> fifo -> axi
    logic [38:0] R_slave_data, R_axi_data;
    logic        R_full, R_empty;
    logic        R_sf_handshake;
    logic        R_axi_handshake;

    // axi -> fifo -> slave
    logic [44:0] AW_axi_data, AW_slave_data;
    logic        AW_full, AW_empty;
    logic        AW_axi_handshake;
    logic        AW_sf_handshake;

    // axi -> fifo -> slave
    logic [36:0] W_axi_data, W_slave_data;
    logic        W_full, W_empty;
    logic        W_axi_handshake;
    logic        W_sf_handshake;

    // slave -> fifo -> axi
    logic [5:0]  B_slave_data, B_axi_data;
    logic        B_full, B_empty;
    logic        B_sf_handshake;
    logic        B_axi_handshake;

    // --------------------------------------------
    //                  AR channel                 
    // --------------------------------------------
    assign ARREADY_AXI = ~AR_full;
    assign ARVALID_S   = ~AR_empty;
    assign ARID_S      = {4'd0, AR_slave_data[44:41]};
    assign ARADDR_S    = AR_slave_data[40: 9];
    assign ARLEN_S     = AR_slave_data[ 8: 5];
    assign ARSIZE_S    = AR_slave_data[ 4: 2];
    assign ARBURST_S   = AR_slave_data[ 1: 0];

    assign AR_axi_handshake = ARVALID_AXI && ARREADY_AXI;
    assign AR_sf_handshake  = ARVALID_S   && ARREADY_S;
    assign AR_axi_data      = {ARID_AXI[3:0], ARADDR_AXI, ARLEN_AXI, ARSIZE_AXI, ARBURST_AXI};

    AR_FIFO i_AR_FIFO (
        .w_clk   ( axi_clk          ),
        .w_rst   ( axi_rst          ),
        .w_push  ( AR_axi_handshake ),
        .w_data  ( AR_axi_data      ),
        .w_full  ( AR_full          ),

        .r_clk   ( slave_clk        ),
        .r_rst   ( slave_rst        ),
        .r_pop   ( AR_sf_handshake  ),
        .r_data  ( AR_slave_data    ),
        .r_empty ( AR_empty         )
    );

    // --------------------------------------------
    //                   R channel                 
    // --------------------------------------------
    assign RREADY_S   = ~R_full;
    assign RVALID_AXI = ~R_empty;
    assign RID_AXI    = {4'd0, R_axi_data[38:35]};
    assign RDATA_AXI  = R_axi_data[34: 3];
    assign RRESP_AXI  = R_axi_data[2 : 1];
    assign RLAST_AXI  = R_axi_data[0];

    assign R_axi_handshake = RVALID_AXI && RREADY_AXI;
    assign R_sf_handshake  = RVALID_S   && RREADY_S;
    assign R_slave_data    = {RID_S[3:0], RDATA_S, RRESP_S, RLAST_S};

    R_FIFO i_R_FIFO (
        .w_clk   ( slave_clk        ),
        .w_rst   ( slave_rst        ),
        .w_push  ( R_sf_handshake   ),
        .w_data  ( R_slave_data     ),
        .w_full  ( R_full           ),

        .r_clk   ( axi_clk          ),
        .r_rst   ( axi_rst          ),
        .r_pop   ( R_axi_handshake  ),
        .r_data  ( R_axi_data       ),
        .r_empty ( R_empty          )
    );

    // --------------------------------------------
    //                  AW channel                 
    // --------------------------------------------
    assign AWREADY_AXI = ~AW_full;
    assign AWVALID_S   = ~AW_empty;
    assign AWID_S      = {4'd0, AW_slave_data[44:41]};
    assign AWADDR_S    = AW_slave_data[40: 9];
    assign AWLEN_S     = AW_slave_data[ 8: 5];
    assign AWSIZE_S    = AW_slave_data[ 4: 2];
    assign AWBURST_S   = AW_slave_data[ 1: 0];

    assign AW_axi_handshake = AWVALID_AXI && AWREADY_AXI;
    assign AW_sf_handshake  = AWVALID_S   && AWREADY_S;
    assign AW_axi_data      = {AWID_AXI[3:0], AWADDR_AXI, AWLEN_AXI, AWSIZE_AXI, AWBURST_AXI};

    AW_FIFO i_AW_FIFO (
        .w_clk   ( axi_clk          ),
        .w_rst   ( axi_rst          ),
        .w_push  ( AW_axi_handshake ),
        .w_data  ( AW_axi_data      ),
        .w_full  ( AW_full          ),

        .r_clk   ( slave_clk        ),
        .r_rst   ( slave_rst        ),
        .r_pop   ( AW_sf_handshake  ),
        .r_data  ( AW_slave_data    ),
        .r_empty ( AW_empty         )
    );

    // --------------------------------------------
    //                   W channel                 
    // --------------------------------------------
    assign WREADY_AXI = ~W_full;
    assign WVALID_S   = ~W_empty;
    assign WDATA_S    = W_slave_data[36:5];
    assign WSTRB_S    = W_slave_data[ 4:1];
    assign WLAST_S    = W_slave_data[0];

    assign W_axi_handshake = WVALID_AXI && WREADY_AXI;
    assign W_sf_handshake  = WVALID_S   && WREADY_S;
    assign W_axi_data      = {WDATA_AXI, WSTRB_AXI, WLAST_AXI};

    W_FIFO i_W_FIFO (
        .w_clk   ( axi_clk          ),
        .w_rst   ( axi_rst          ),
        .w_push  ( W_axi_handshake  ),
        .w_data  ( W_axi_data       ),
        .w_full  ( W_full           ),

        .r_clk   ( slave_clk        ),
        .r_rst   ( slave_rst        ),
        .r_pop   ( W_sf_handshake   ),
        .r_data  ( W_slave_data     ),
        .r_empty ( W_empty          )
    );

    // --------------------------------------------
    //                   B channel                 
    // --------------------------------------------
    assign BREADY_S   = ~B_full;
    assign BVALID_AXI = ~B_empty;
    assign BID_AXI    = {4'd0, B_axi_data[5:2]};
    assign BRESP_AXI  = B_axi_data[1:0];

    assign B_axi_handshake = BVALID_AXI && BREADY_AXI;
    assign B_sf_handshake  = BVALID_S   && BREADY_S;
    assign B_slave_data    = {BID_S[3:0], BRESP_S};

    B_FIFO i_B_FIFO (
        .w_clk   ( slave_clk        ),
        .w_rst   ( slave_rst        ),
        .w_push  ( B_sf_handshake   ),
        .w_data  ( B_slave_data     ),
        .w_full  ( B_full           ),

        .r_clk   ( axi_clk          ),
        .r_rst   ( axi_rst          ),
        .r_pop   ( B_axi_handshake  ),
        .r_data  ( B_axi_data       ),
        .r_empty ( B_empty          )
    );

endmodule