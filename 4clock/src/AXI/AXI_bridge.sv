//================================================
// Auther:      Chen-En Wu
// Filename:    AXI.sv
// Description: AXI crossbar
// Version:     1.0
//================================================
module AXI_bridge (
    input logic                       ACLK,
    input logic                       ARESET,

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
    typedef enum logic {
        READ, WRITE
    } TYPE_t;

    typedef struct packed {
        logic     busy;             // If the slave is busy
        TYPE_t    transaction_type; // Read or Write
        MASTER_ID current_master;   // Who use the slave
    } SLAVE_STATUS_t;
    
    SLAVE_ID       decoded_ar[`MASTER_NUM];
    SLAVE_ID       decoded_aw[`MASTER_NUM];
    MASTER_ID      master_priority_q, master_priority_n;
    
    SLAVE_STATUS_t slave_status_q    [`SLAVE_NUM  ]; // Record the slave status
    SLAVE_STATUS_t slave_status_n    [`SLAVE_NUM  ]; // Update next slave status
    logic          transaction_finish[`SLAVE_NUM  ]; // If transaction finish
    logic          request_valid     [`SLAVE_NUM+1]; // If any master want to use slave
    TYPE_t         request_type      [`SLAVE_NUM+1]; // Request is read or write
    MASTER_ID      request_master    [`SLAVE_NUM+1]; // Which master want to use slave

    // --------------------------------------------
    //                Address Decode               
    // --------------------------------------------
    generate
        for (genvar i = 0; i < `MASTER_NUM; i++) begin : ADDR_decoder
            AXI_decoder ar_addr_decoder (
                .valid_i    (ARVALID_M [i]),
                .addr_i     (ARADDR_M  [i]),
                .slave_id_o (decoded_ar[i])
            );

            AXI_decoder aw_addr_decoder (
                .valid_i    (AWVALID_M [i]),
                .addr_i     (AWADDR_M  [i]),
                .slave_id_o (decoded_aw[i])
            );
        end
    endgenerate

    // --------------------------------------------
    //               Arbitration Logic             
    // --------------------------------------------
    always_comb begin
        // reset all request (include default slave)
        for (int i = 0; i < `SLAVE_NUM + 1; i++) begin
            request_valid [i] = 1'b0;
            request_type  [i] = READ;
            request_master[i] = CPU_FETCH;
        end

        // set up request
        for (int i = 0; i < `MASTER_NUM; i++) begin
            // if receive a write request
            if (AWVALID_M[i]) begin
                request_valid [ decoded_aw[i][`SLAVE_BITS-1:0] ] = 1'b1;
                request_type  [ decoded_aw[i][`SLAVE_BITS-1:0] ] = WRITE;
                request_master[ decoded_aw[i][`SLAVE_BITS-1:0] ] = MASTER_ID'(i);
            end

            // if receive a read request
            if (ARVALID_M[i]) begin
                request_valid [ decoded_ar[i][`SLAVE_BITS-1:0] ] = 1'b1;
                request_type  [ decoded_ar[i][`SLAVE_BITS-1:0] ] = READ;
                request_master[ decoded_ar[i][`SLAVE_BITS-1:0] ] = MASTER_ID'(i);
            end
        end

        // check the highest priority can get the request
        if (AWVALID_M[master_priority_q]) begin
            request_valid [ decoded_aw[master_priority_q][`SLAVE_BITS-1:0] ] = 1'b1;
            request_type  [ decoded_aw[master_priority_q][`SLAVE_BITS-1:0] ] = WRITE;
            request_master[ decoded_aw[master_priority_q][`SLAVE_BITS-1:0] ] = master_priority_q;
        end

        if (ARVALID_M[master_priority_q]) begin
            request_valid [ decoded_ar[master_priority_q][`SLAVE_BITS-1:0] ] = 1'b1;
            request_type  [ decoded_ar[master_priority_q][`SLAVE_BITS-1:0] ] = READ;
            request_master[ decoded_ar[master_priority_q][`SLAVE_BITS-1:0] ] = master_priority_q;
        end

        // update priority
        unique case (master_priority_q)
            CPU_FETCH : master_priority_n = CPU_MEM;
            CPU_MEM   : master_priority_n = DMA_M;
            DMA_M     : master_priority_n = CPU_FETCH;
            default   : master_priority_n = CPU_FETCH;
        endcase
    end

    // update slave status
    // note : dont need to care about default slave
    always_comb begin
        slave_status_n = slave_status_q;

        for (int i = 0; i < `SLAVE_NUM; i++) begin
            // finish transaction when slave R handshake or B handshake
            transaction_finish[i] = (RVALID_S[i] & RREADY_S[i] & RLAST_S[i]) |
                                    (BVALID_S[i] & BREADY_S[i]);

            // reset busy to idle if finish transcation
            if (slave_status_q[i].busy & transaction_finish[i]) begin
                slave_status_n[i].busy = 1'b0;

                // remain busy if next request is still the same master and same type
                if (request_valid [i] &
                    request_master[i] == slave_status_q[i].current_master &
                    request_type  [i] == slave_status_q[i].transaction_type) begin
                    slave_status_n[i].busy = 1'b1;
                end
            end

            // set to busy, if any master want send request to "idle" slave
            if (!slave_status_q[i].busy & request_valid[i]) begin
                slave_status_n[i].busy             = 1'b1;
                slave_status_n[i].transaction_type = request_type[i];
                slave_status_n[i].current_master   = request_master[i];
            end
        end
    end

    always_ff @(posedge ACLK) begin
        if (ARESET) begin
            master_priority_q <= CPU_FETCH;

            for (int i = 0; i < `SLAVE_NUM; i++) begin
                slave_status_q[i] <= SLAVE_STATUS_t'(0);
            end

        end else begin
            master_priority_q <= master_priority_n;

            for (int i = 0; i < `SLAVE_NUM; i++) begin
                slave_status_q[i] <= slave_status_n[i];
            end
        end
    end

    // --------------------------------------------
    //                   Cross Bar                 
    // --------------------------------------------
    always_comb begin
        // default master output
        for (int i = 0; i < `MASTER_NUM; i++) begin
            ARREADY_M[i] = 1'b0;
            RID_M    [i] = `AXI_ID_BITS'd0;
            RDATA_M  [i] = `AXI_DATA_BITS'd0;
            RRESP_M  [i] = `AXI_RESP_OKAY;
            RLAST_M  [i] = 1'b0;
            RVALID_M [i] = 1'b0;
            AWREADY_M[i] = 1'b0;
            WREADY_M [i] = 1'b0;
            BID_M    [i] = `AXI_ID_BITS'd0;
            BRESP_M  [i] = `AXI_RESP_OKAY;
            BVALID_M [i] = 1'b0;
        end

        // deault slave output
        for (int i = 0; i < `SLAVE_NUM; i++) begin
            ARID_S   [i] = `AXI_IDS_BITS'd0;
            ARADDR_S [i] = `AXI_ADDR_BITS'd0;
            ARLEN_S  [i] = `AXI_LEN_ONE;
            ARSIZE_S [i] = `AXI_SIZE_WORD;
            ARBURST_S[i] = `AXI_BURST_INC;
            ARVALID_S[i] = 1'b0;
            RREADY_S [i] = 1'b0;
            AWID_S   [i] = `AXI_IDS_BITS'd0;
            AWADDR_S [i] = `AXI_ADDR_BITS'd0;
            AWLEN_S  [i] = `AXI_LEN_ONE;
            AWSIZE_S [i] = `AXI_SIZE_WORD;
            AWBURST_S[i] = `AXI_BURST_INC;
            AWVALID_S[i] = 1'b0;
            WDATA_S  [i] = `AXI_DATA_BITS'd0;
            WSTRB_S  [i] = `AXI_STRB_WORD;
            WLAST_S  [i] = 1'b0;
            WVALID_S [i] = 1'b0;
            BREADY_S [i] = 1'b0;
        end

        // connect master to slave according to slave status
        for (int i = 0; i < `SLAVE_NUM; i++) begin
            if (slave_status_q[i].busy) begin
                // connect read port (AR, R)
                if (slave_status_q[i].transaction_type == READ) begin
                    ARREADY_M[slave_status_q[i].current_master] = ARREADY_S[i];
                    RID_M    [slave_status_q[i].current_master] = RID_S    [i][3:0];
                    RDATA_M  [slave_status_q[i].current_master] = RDATA_S  [i];
                    RRESP_M  [slave_status_q[i].current_master] = RRESP_S  [i];
                    RLAST_M  [slave_status_q[i].current_master] = RLAST_S  [i];
                    RVALID_M [slave_status_q[i].current_master] = RVALID_S [i];
                
                    ARID_S   [i] = {4'd0, ARID_M[slave_status_q[i].current_master]};
                    ARADDR_S [i] = ARADDR_M [slave_status_q[i].current_master];
                    ARLEN_S  [i] = ARLEN_M  [slave_status_q[i].current_master];
                    ARSIZE_S [i] = ARSIZE_M [slave_status_q[i].current_master];
                    ARBURST_S[i] = ARBURST_M[slave_status_q[i].current_master];
                    ARVALID_S[i] = ARVALID_M[slave_status_q[i].current_master];
                    RREADY_S [i] = RREADY_M [slave_status_q[i].current_master];

                // connect write port (AW, W, B)
                end else begin
                    AWREADY_M[slave_status_q[i].current_master] = AWREADY_S[i];
                    WREADY_M [slave_status_q[i].current_master] = WREADY_S [i];
                    BID_M    [slave_status_q[i].current_master] = BID_S    [i][3:0];
                    BRESP_M  [slave_status_q[i].current_master] = BRESP_S  [i];
                    BVALID_M [slave_status_q[i].current_master] = BVALID_S [i];

                    AWID_S   [i] = {4'd0, AWID_M[slave_status_q[i].current_master]};
                    AWADDR_S [i] = AWADDR_M [slave_status_q[i].current_master];
                    AWLEN_S  [i] = AWLEN_M  [slave_status_q[i].current_master];
                    AWSIZE_S [i] = AWSIZE_M [slave_status_q[i].current_master];
                    AWBURST_S[i] = AWBURST_M[slave_status_q[i].current_master];
                    AWVALID_S[i] = AWVALID_M[slave_status_q[i].current_master];
                    WDATA_S  [i] = WDATA_M  [slave_status_q[i].current_master];
                    WSTRB_S  [i] = WSTRB_M  [slave_status_q[i].current_master];
                    WLAST_S  [i] = WLAST_M  [slave_status_q[i].current_master];
                    WVALID_S [i] = WVALID_M [slave_status_q[i].current_master];
                    BREADY_S [i] = BREADY_M [slave_status_q[i].current_master];
                end

            // can save one cycle for early connect
            end else if (slave_status_n[i].busy) begin
                // connect read port (AR, R)
                if (slave_status_n[i].transaction_type == READ) begin
                    ARREADY_M[slave_status_n[i].current_master] = ARREADY_S[i];
                    RID_M    [slave_status_n[i].current_master] = RID_S    [i][3:0];
                    RDATA_M  [slave_status_n[i].current_master] = RDATA_S  [i];
                    RRESP_M  [slave_status_n[i].current_master] = RRESP_S  [i];
                    RLAST_M  [slave_status_n[i].current_master] = RLAST_S  [i];
                    RVALID_M [slave_status_n[i].current_master] = RVALID_S [i];
                
                    ARID_S   [i] = {4'd0, ARID_M[slave_status_n[i].current_master]};
                    ARADDR_S [i] = ARADDR_M [slave_status_n[i].current_master];
                    ARLEN_S  [i] = ARLEN_M  [slave_status_n[i].current_master];
                    ARSIZE_S [i] = ARSIZE_M [slave_status_n[i].current_master];
                    ARBURST_S[i] = ARBURST_M[slave_status_n[i].current_master];
                    ARVALID_S[i] = ARVALID_M[slave_status_n[i].current_master];
                    RREADY_S [i] = RREADY_M [slave_status_n[i].current_master];

                // connect write port (AW, W, B)
                end else begin
                    AWREADY_M[slave_status_n[i].current_master] = AWREADY_S[i];
                    WREADY_M [slave_status_n[i].current_master] = WREADY_S [i];
                    BID_M    [slave_status_n[i].current_master] = BID_S    [i][3:0];
                    BRESP_M  [slave_status_n[i].current_master] = BRESP_S  [i];
                    BVALID_M [slave_status_n[i].current_master] = BVALID_S [i];

                    AWID_S   [i] = {4'd0, AWID_M[slave_status_n[i].current_master]};
                    AWADDR_S [i] = AWADDR_M [slave_status_n[i].current_master];
                    AWLEN_S  [i] = AWLEN_M  [slave_status_n[i].current_master];
                    AWSIZE_S [i] = AWSIZE_M [slave_status_n[i].current_master];
                    AWBURST_S[i] = AWBURST_M[slave_status_n[i].current_master];
                    AWVALID_S[i] = AWVALID_M[slave_status_n[i].current_master];
                    WDATA_S  [i] = WDATA_M  [slave_status_n[i].current_master];
                    WSTRB_S  [i] = WSTRB_M  [slave_status_n[i].current_master];
                    WLAST_S  [i] = WLAST_M  [slave_status_n[i].current_master];
                    WVALID_S [i] = WVALID_M [slave_status_n[i].current_master];
                    BREADY_S [i] = BREADY_M [slave_status_n[i].current_master];
                end
            end
        end
    end

endmodule