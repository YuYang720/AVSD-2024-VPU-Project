module CPU_wrapper (
    input  logic                      clk_i,
    input  logic                      rst_i,

    // external interrupt
    input  logic                      DMA_interrupt_i,
    input  logic                      WDT_interrupt_i,

    // AXI MASTER0 INTERFACE
    // AR channel
    output logic [`AXI_ID_BITS  -1:0] ARID_M0,
    output logic [`AXI_DATA_BITS-1:0] ARADDR_M0,
    output logic [`AXI_LEN_BITS -1:0] ARLEN_M0,
    output logic [`AXI_SIZE_BITS-1:0] ARSIZE_M0,
    output logic [1:0]                ARBURST_M0,
    output logic                      ARVALID_M0,
    input  logic                      ARREADY_M0,
    // R channel
    input  logic [`AXI_ID_BITS  -1:0] RID_M0,
    input  logic [`AXI_DATA_BITS-1:0] RDATA_M0,
    input  logic [1:0]                RRESP_M0,
    input  logic                      RLAST_M0,
    input  logic                      RVALID_M0,
    output logic                      RREADY_M0,
    // AW channel
    output logic [`AXI_ID_BITS  -1:0] AWID_M0,
    output logic [`AXI_ADDR_BITS-1:0] AWADDR_M0,
    output logic [`AXI_LEN_BITS -1:0] AWLEN_M0,
    output logic [`AXI_SIZE_BITS-1:0] AWSIZE_M0,
    output logic [1:0]                AWBURST_M0,
    output logic                      AWVALID_M0,
    input  logic                      AWREADY_M0,
    // W channel
    output logic [`AXI_DATA_BITS-1:0] WDATA_M0,
    output logic [`AXI_STRB_BITS-1:0] WSTRB_M0,
    output logic                      WLAST_M0,
    output logic                      WVALID_M0,
    input  logic                      WREADY_M0,
    // B channel
    input  logic [`AXI_ID_BITS  -1:0] BID_M0,
    input  logic [1:0]                BRESP_M0,
    input  logic                      BVALID_M0,
    output logic                      BREADY_M0,

    // MASTER1 INTERFACE
    // AR channel
    output logic [`AXI_ID_BITS  -1:0] ARID_M1,
    output logic [`AXI_DATA_BITS-1:0] ARADDR_M1,
    output logic [`AXI_LEN_BITS -1:0] ARLEN_M1,
    output logic [`AXI_SIZE_BITS-1:0] ARSIZE_M1,
    output logic [1:0]                ARBURST_M1,
    output logic                      ARVALID_M1,
    input  logic                      ARREADY_M1,
    // R channel
    input  logic [`AXI_ID_BITS  -1:0] RID_M1,
    input  logic [`AXI_DATA_BITS-1:0] RDATA_M1,
    input  logic [1:0]                RRESP_M1,
    input  logic                      RLAST_M1,
    input  logic                      RVALID_M1,
    output logic                      RREADY_M1,
    // AW channel
    output logic [`AXI_ID_BITS  -1:0] AWID_M1,
    output logic [`AXI_ADDR_BITS-1:0] AWADDR_M1,
    output logic [`AXI_LEN_BITS -1:0] AWLEN_M1,
    output logic [`AXI_SIZE_BITS-1:0] AWSIZE_M1,
    output logic [1:0]                AWBURST_M1,
    output logic                      AWVALID_M1,
    input  logic                      AWREADY_M1,
    // W channel
    output logic [`AXI_DATA_BITS-1:0] WDATA_M1,
    output logic [`AXI_STRB_BITS-1:0] WSTRB_M1,
    output logic                      WLAST_M1,
    output logic                      WVALID_M1,
    input  logic                      WREADY_M1,
    // B channel
    input  logic [`AXI_ID_BITS  -1:0] BID_M1,
    input  logic [1:0]                BRESP_M1,
    input  logic                      BVALID_M1,
    output logic                      BREADY_M1
);

    // --------------------------------------------
    //              Signal Declaration             
    // --------------------------------------------
    // master FSM
    typedef enum logic [2:0] {
        IDLE, AR_TRANS, RDATA_TRANS, AW_TRANS, WDATA_TRANS, BRESP
    } AXI_STATE_t;

    // request buffer
    typedef struct packed {
        logic        valid;
        logic [31:0] addr;
        logic [31:0] data;
        logic [ 3:0] strb;
    } REQUEST_t;

    // state machine
    AXI_STATE_t  fetch_state_q, fetch_state_n;
    AXI_STATE_t  ls_state_q, ls_state_n;

    // request buffer
    REQUEST_t    fetch_request_q, fetch_request_n;
    REQUEST_t    ls_request_q, ls_request_n;

    // master0 <-> I$
    logic        icache_request;
    logic [31:0] icache_addr;
    logic        icache_wait;
    logic        icache_out_valid;
    logic [31:0] icache_out;

    // master1 <-> D$
    logic        dcache_request;
    logic [ 3:0] dcache_write;
    logic [31:0] dcache_addr;
    logic [31:0] dcache_in;
    logic        dcache_wait;
    logic        dcache_out_valid;
    logic [31:0] dcache_out;

    // CPU <-> I$
    logic        icache_core_request; // memory access request from CPU
    logic [31:0] icache_core_pc;      // pc from CPU
    logic        icache_core_wait;    // wait signal to CPU
    logic [31:0] icache_core_addr;    // address to CPU
    logic [31:0] icache_core_out;     // read data to CPU

    // CPU <-> D$
    logic        dcache_core_request; // memory access request from CPU
    logic [ 3:0] dcache_core_write;   // write byte, half, or word from CPU
    logic [31:0] dcache_core_addr;    // address from CPU
    logic [31:0] dcache_core_in;      // write data from CPU
    logic        dcache_core_wait;    // wait signal to CPU
    logic [31:0] dcache_core_out;     // read data to CPU

    // VPU signal
    logic        vector_inst_valid;
    logic [31:0] vector_inst;
    logic [31:0] vector_xrs1_val;
    logic [31:0] vector_xrs2_val;
    logic        vector_ack;
    logic        vector_writeback;
    logic        vector_pend_lsu;
    logic        vector_lsu_valid;
    logic        vector_result_valid;
    logic [31:0] vector_result;

    // VPU <-> D$
    logic        dcache_vpu_request;
    logic [ 3:0] dcache_vpu_write;
    logic [31:0] dcache_vpu_addr;
    logic [31:0] dcache_vpu_in;

    // response from D$
    logic        dcache_vpu_wait;
    logic [31:0] dcache_vpu_out;

    // --------------------------------------------
    //    Master0: Instruction Fetch (Read Only)   
    // --------------------------------------------
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            fetch_state_q   <= IDLE;
            fetch_request_q <= REQUEST_t'(0);
        end else begin
            fetch_state_q   <= fetch_state_n;
            fetch_request_q <= fetch_request_n;
        end
    end

    always_comb begin
        fetch_state_n   = fetch_state_q;
        fetch_request_n = fetch_request_q;

        // default AXI master output assignment
        ARVALID_M0 = 1'b0;
        ARID_M0    = `AXI_ID_BITS'd0;
        ARLEN_M0   = 4'h3;
        ARSIZE_M0  = `AXI_SIZE_WORD;
        ARBURST_M0 = `AXI_BURST_INC;
        ARADDR_M0  = `AXI_ADDR_BITS'd0;
        RREADY_M0  = 1'b0;
        AWVALID_M0 = 1'b0;
        AWID_M0    = 4'd0;
        AWLEN_M0   = `AXI_LEN_ONE;
        AWSIZE_M0  = `AXI_SIZE_WORD;
        AWBURST_M0 = `AXI_BURST_INC;
        AWADDR_M0  = `AXI_ADDR_BITS'd0;
        WVALID_M0  = 1'b0;
        WDATA_M0   = `AXI_DATA_BITS'd0;
        WSTRB_M0   = `AXI_STRB_WORD;
        WLAST_M0   = 1'b0;
        BREADY_M0  = 1'b0;

        // default icache response assignment
        icache_wait      = fetch_request_q.valid | icache_request;
        icache_out_valid = 1'b0;
        icache_out       = fetch_request_q.data;

        unique case (fetch_state_q)
            IDLE : begin
                // receive icache request when icache_request is asserted
                // otherwise, keep the previous request result
                if (icache_request) begin
                    fetch_state_n   = AR_TRANS;
                    fetch_request_n = {1'b1, icache_addr, 32'd0, 4'd0};

                    // actually we can send request to AXI bridge right now
                    // if AR handshake, go to next rdata state to receive data
                    ARVALID_M0 = 1'b1;
                    ARADDR_M0  = fetch_request_n.addr;

                    if(ARREADY_M0) fetch_state_n = RDATA_TRANS;
                end
            end

            AR_TRANS: begin
                ARVALID_M0 = 1'b1;
                ARADDR_M0  = fetch_request_q.addr;

                // if AR handshake, go to next to receive data
                if(ARREADY_M0) fetch_state_n = RDATA_TRANS;
            end

            RDATA_TRANS: begin
                RREADY_M0 = 1'b1;

                // if R handshake, the data is valid right now
                if (RVALID_M0) begin
                    icache_out_valid = 1'b1;
                    icache_out       = RDATA_M0;
                end

                // received last data, go back to idle
                if (RVALID_M0 & RLAST_M0) begin
                    fetch_state_n         = IDLE;
                    fetch_request_n.valid = 1'b0;
                    fetch_request_n.data  = RDATA_M0;
                end
            end

            default : fetch_state_n = IDLE;
        endcase
    end

    // --------------------------------------------
    //            Master1: Load / Store            
    // --------------------------------------------
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            ls_state_q   <= IDLE;
            ls_request_q <= REQUEST_t'(0);
        end else begin
            ls_state_q   <= ls_state_n;
            ls_request_q <= ls_request_n;
        end
    end

    always_comb begin
        ls_state_n   = ls_state_q;
        ls_request_n = ls_request_q;

        // default AXI master output assignment
        ARVALID_M1 = 1'b0;
        ARID_M1    = 4'd0;
        ARLEN_M1   = 4'h3;
        ARSIZE_M1  = `AXI_SIZE_WORD;
        ARBURST_M1 = `AXI_BURST_INC;
        ARADDR_M1  = `AXI_ADDR_BITS'd0;
        RREADY_M1  = 1'b0;
        AWVALID_M1 = 1'b0;
        AWID_M1    = 4'd0;
        AWLEN_M1   = `AXI_LEN_ONE;
        AWSIZE_M1  = `AXI_SIZE_WORD;
        AWBURST_M1 = `AXI_BURST_INC;
        AWADDR_M1  = `AXI_ADDR_BITS'd0;
        WVALID_M1  = 1'b0;
        WDATA_M1   = `AXI_DATA_BITS'd0;
        WSTRB_M1   = `AXI_STRB_WORD;
        WLAST_M1   = 1'b0;
        BREADY_M1  = 1'b0;

        // default dcache response assignment
        dcache_wait      = ls_request_q.valid | dcache_request;
        dcache_out_valid = 1'b0;
        dcache_out       = ls_request_q.data;

        unique case (ls_state_q)
            IDLE : begin
                // receive dcache request when load or store request is asserted
                // otherwise, keep the previous load/store request
                if (dcache_request && ~|dcache_write) begin
                    // assume load request
                    ls_state_n   = AR_TRANS;
                    ls_request_n = {1'b1, dcache_addr, dcache_in, dcache_write};

                    // actually we can send request to AXI bridge right now
                    // if AR handshake, go to next rdata state to receive data
                    ARVALID_M1 = 1'b1;
                    ARADDR_M1  = ls_request_n.addr;

                    if (ARREADY_M1) ls_state_n = RDATA_TRANS;

                end else if (dcache_request) begin
                    ls_state_n   = AW_TRANS;
                    ls_request_n = {1'b1, dcache_addr, dcache_in, dcache_write};

                    // actually we can send request to AXI bridge right now
                    // if AW handshake, go to next to send data
                    // to speed up, the W channel can send right away when AW channel handshake
                    AWVALID_M1 = 1'b1;
                    AWADDR_M1  = ls_request_n.addr;

                    if (AWREADY_M1) begin
                        ls_state_n = WDATA_TRANS;

                        WVALID_M1 = 1'b1;
                        WLAST_M1  = 1'b1;
                        WSTRB_M1  = ls_request_n.strb;
                        WDATA_M1  = ls_request_n.data;

                        if (WREADY_M1) ls_state_n = BRESP;
                    end
                end
            end

            AR_TRANS : begin
                ARVALID_M1 = 1'b1;
                ARADDR_M1  = ls_request_q.addr;

                // If AR handshake, go to next to receive data
                if (ARREADY_M1) ls_state_n = RDATA_TRANS;
            end

            RDATA_TRANS : begin
                RREADY_M1 = 1'b1;

                // If R handshake, the data is valid right now
                if (RVALID_M1) begin
                    dcache_out_valid = 1'b1;
                    dcache_out       = RDATA_M1;
                end

                // Received last data, go back to idle
                if (RVALID_M1 & RLAST_M1) begin
                    ls_state_n         = IDLE;
                    ls_request_n.valid = 1'b0;
                    ls_request_n.data  = RDATA_M1;
                end
            end

            AW_TRANS : begin
                AWVALID_M1 = 1'b1;
                AWADDR_M1  = ls_request_q.addr;

                // If AW handshake, go to next to send data
                // To speed up, the W channel can send right away when AW channel handshake
                if (AWREADY_M1) begin
                    ls_state_n = WDATA_TRANS;
                    
                    WVALID_M1 = 1'b1;
                    WLAST_M1  = 1'b1;
                    WSTRB_M1  = ls_request_q.strb;
                    WDATA_M1  = ls_request_q.data;

                    if (WREADY_M1) ls_state_n = BRESP;
                end
            end

            WDATA_TRANS : begin
                WVALID_M1 = 1'b1;
                WLAST_M1  = 1'b1;
                WSTRB_M1  = ls_request_q.strb;
                WDATA_M1  = ls_request_q.data;

                if (WREADY_M1) ls_state_n = BRESP;
            end

            BRESP : begin
                BREADY_M1 = 1'b1;

                if (BVALID_M1) begin
                    ls_state_n         = IDLE;
                    ls_request_n.valid = 1'b0;
                    dcache_wait        = 1'b0;
                end
            end

            default : ls_state_n = IDLE;
        endcase
    end

    // --------------------------------------------
    //            Master 0/1 <---> I$,D$           
    // --------------------------------------------
    CPU CPU1 (
        .clk_i,
        .rst_i,

        // external and timer interrupt
        .DMA_interrupt_i,
        .WDT_interrupt_i,

        // if stage request to I$
        .icache_core_request_o ( icache_core_request ),
        .icache_core_pc_o      ( icache_core_pc      ),
        .icache_core_wait_i    ( icache_core_wait    ),
        .icache_core_addr_i    ( icache_core_addr    ),
        .icache_core_out_i     ( icache_core_out     ),

        // exe stage request to D$
        .dcache_core_request_o ( dcache_core_request ),
        .dcache_core_write_o   ( dcache_core_write   ),
        .dcache_core_addr_o    ( dcache_core_addr    ),
        .dcache_core_in_o      ( dcache_core_in      ),
        .dcache_core_wait_i    ( dcache_core_wait    ),
        .dcache_core_out_i     ( dcache_core_out     ),

        // to VPU
        .vector_inst_valid_o   ( vector_inst_valid   ),
        .vector_inst_o         ( vector_inst         ),
        .vector_xrs1_val_o     ( vector_xrs1_val     ),
        .vector_xrs2_val_o     ( vector_xrs2_val     ),
        .vector_ack_i          ( vector_ack          ),
        .vector_writeback_i    ( vector_writeback    ),
        .vector_pend_lsu_i     ( vector_pend_lsu     ),

        // from VPU
        .vector_lsu_valid_i    ( vector_lsu_valid    ),
        .vector_result_valid_i ( vector_result_valid ),
        .vector_result_i       ( vector_result       )
    );

    VPU i_VPU (
        .clk_i,
        .rst_i,

        // from CPU
        .vector_inst_valid_i   ( vector_inst_valid   ),
        .vector_inst_i         ( vector_inst         ),
        .vector_xrs1_val_i     ( vector_xrs1_val     ),
        .vector_xrs2_val_i     ( vector_xrs2_val     ),
        .vector_ack_o          ( vector_ack          ),
        .vector_writeback_o    ( vector_writeback    ),
        .vector_pend_lsu_o     ( vector_pend_lsu     ),

        // to CPU
        .vector_lsu_valid_o    ( vector_lsu_valid    ),
        .vector_result_valid_o ( vector_result_valid ),
        .vector_result_o       ( vector_result       ),

        // request to D$
        .dcache_vpu_request_o  ( dcache_vpu_request  ),
        .dcache_vpu_write_o    ( dcache_vpu_write    ),
        .dcache_vpu_addr_o     ( dcache_vpu_addr     ),
        .dcache_vpu_in_o       ( dcache_vpu_in       ),

        // response from D$
        .dcache_vpu_wait_i     ( dcache_vpu_wait     ),
        .dcache_vpu_out_i      ( dcache_vpu_out      )
    );

    L1C_inst L1CI (
        .clk_i,
        .rst_i,

        // core <-> D$
        .core_req_i            ( icache_core_request ),
        .core_pc_i             ( icache_core_pc      ),
        .core_wait_o           ( icache_core_wait    ),
        .core_addr_o           ( icache_core_addr    ),
        .core_out_o            ( icache_core_out     ),

        // D$ <-> master0
        .D_req_o               ( icache_request      ),
        .D_addr_o              ( icache_addr         ),
        .D_wait_i              ( icache_wait         ),
        .D_out_valid_i         ( icache_out_valid    ),
        .D_out_i               ( icache_out          )
    );

    L1C_data L1CD (
        .clk_i,
        .rst_i,
  
        // core <-> D$
        .core_req_i            ( dcache_core_request ),
        .core_write_i          ( dcache_core_write   ),
        .core_addr_i           ( dcache_core_addr    ),
        .core_in_i             ( dcache_core_in      ),
        .core_wait_o           ( dcache_core_wait    ),
        .core_out_o            ( dcache_core_out     ),

        // VPU <-> D$
        .vpu_request_i         ( dcache_vpu_request  ),
        .vpu_write_i           ( dcache_vpu_write    ),
        .vpu_addr_i            ( dcache_vpu_addr     ),
        .vpu_in_i              ( dcache_vpu_in       ),
        .vpu_wait_o            ( dcache_vpu_wait     ),
        .vpu_out_o             ( dcache_vpu_out      ),

        // D$ <-> master1
        .D_req_o               ( dcache_request      ),
        .D_write_o             ( dcache_write        ),
        .D_addr_o              ( dcache_addr         ),
        .D_in_o                ( dcache_in           ),
        .D_wait_i              ( dcache_wait         ),
        .D_out_valid_i         ( dcache_out_valid    ),
        .D_out_i               ( dcache_out          )
    );

endmodule