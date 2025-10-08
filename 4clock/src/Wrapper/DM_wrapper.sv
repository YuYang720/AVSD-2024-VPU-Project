`include "../include/AXI_define.svh"

module DM_wrapper (
    input  logic                      clk,
    input  logic                      rst,
    input  logic [31:0]               BASE_ADDR,

    // --------------------------------------------
    //              AXI Slave Interface            
    // --------------------------------------------
    // AR channel
    input  logic [`AXI_IDS_BITS -1:0] ARID_S,
    input  logic [`AXI_DATA_BITS-1:0] ARADDR_S,
    input  logic [`AXI_LEN_BITS -1:0] ARLEN_S,
    input  logic [`AXI_SIZE_BITS-1:0] ARSIZE_S,
    input  logic [1:0]                ARBURST_S,
    input  logic                      ARVALID_S,
    output logic                      ARREADY_S,
    // R channel
    output logic [`AXI_IDS_BITS -1:0] RID_S,
    output logic [`AXI_DATA_BITS-1:0] RDATA_S,
    output logic [1:0]                RRESP_S,
    output logic                      RLAST_S,
    output logic                      RVALID_S,
    input  logic                      RREADY_S,
    // AW channel
    input  logic [`AXI_IDS_BITS -1:0] AWID_S,
    input  logic [`AXI_ADDR_BITS-1:0] AWADDR_S,
    input  logic [`AXI_LEN_BITS -1:0] AWLEN_S,
    input  logic [`AXI_SIZE_BITS-1:0] AWSIZE_S,
    input  logic [1:0]                AWBURST_S,
    input  logic                      AWVALID_S,
    output logic                      AWREADY_S,
    // W channel
    input  logic [`AXI_DATA_BITS-1:0] WDATA_S,
    input  logic [`AXI_STRB_BITS-1:0] WSTRB_S,
    input  logic                      WLAST_S,
    input  logic                      WVALID_S,
    output logic                      WREADY_S,
    // B channel
    output logic [`AXI_IDS_BITS -1:0] BID_S,
    output logic [1:0]                BRESP_S,
    output logic                      BVALID_S,
    input  logic                      BREADY_S
);

    // --------------------------------------------
    //              Signal Declaration             
    // --------------------------------------------
    // slave FSM
    typedef enum logic [2:0] {
        INIT, IDLE, READ, WRITE, WAIT_WVALID, RESPONSE
    } STATE_t;

    // request structute
    typedef struct packed {
        logic [`AXI_IDS_BITS -1:0] id;
        logic [`AXI_ADDR_BITS-1:0] addr;
        logic [`AXI_LEN_BITS -1:0] len;
        logic [`AXI_SIZE_BITS-1:0] size;
    } REQUEST_t;

    STATE_t      STATE_q, STATE_n;
    REQUEST_t    REQUEST_q, REQUEST_n;
    logic [ 3:0] brust_counter_q, brust_counter_n;
    logic        CEB, WEB, WRITE_REQ, LOAD_REQ;
    logic [13:0] A;
    logic [31:0] DI, BWEB, DO, ADDRESS, real_addr;
    
    logic        SRAM_CEB[2];
    logic [31:0] SRAM_DO [2];
    
    // --------------------------------------------
    //                 SRAM Module                 
    // --------------------------------------------
    assign real_addr = ADDRESS - BASE_ADDR;
    assign A         = real_addr[15:2];
    assign CEB       = ~(WRITE_REQ | LOAD_REQ);
    assign WEB       = ~WRITE_REQ;
    assign BWEB      = {{8{~WSTRB_S[3]}}, {8{~WSTRB_S[2]}}, {8{~WSTRB_S[1]}}, {8{~WSTRB_S[0]}}};

    assign SRAM_CEB[0] = (real_addr <= 32'hffff) & CEB;
    assign SRAM_CEB[1] = (real_addr  > 32'hffff) & CEB;
    assign DO          = (real_addr  > 32'hffff) ? (SRAM_DO[1]) : (SRAM_DO[0]);

    TS1N16ADFPCLLLVTA512X45M4SWSHOD i_SRAM0 (
        .SLP     ( 1'b0        ),
        .DSLP    ( 1'b0        ),
        .SD      ( 1'b0        ),
        .PUDELAY (             ),
        .CLK     ( clk         ),
        .CEB     ( SRAM_CEB[0] ),
        .WEB     ( WEB         ),
        .A       ( A           ),
        .D       ( DI          ),
        .BWEB    ( BWEB        ),
        .RTSEL   ( 2'b01       ),
        .WTSEL   ( 2'b01       ),
        .Q       ( SRAM_DO[0]  )
    );

    TS1N16ADFPCLLLVTA512X45M4SWSHOD i_SRAM1 (
        .SLP     ( 1'b0        ),
        .DSLP    ( 1'b0        ),
        .SD      ( 1'b0        ),
        .PUDELAY (             ),
        .CLK     ( clk         ),
        .CEB     ( SRAM_CEB[1] ),
        .WEB     ( WEB         ),
        .A       ( A           ),
        .D       ( DI          ),
        .BWEB    ( BWEB        ),
        .RTSEL   ( 2'b01       ),
        .WTSEL   ( 2'b01       ),
        .Q       ( SRAM_DO[1]  )
    );

    // --------------------------------------------
    //                  AXI Slave                  
    // --------------------------------------------
    always_comb begin
        STATE_n         = STATE_q;
        REQUEST_n       = REQUEST_q;
        brust_counter_n = brust_counter_q;

        // Memory default assignment
        ADDRESS         = ARADDR_S;
        DI              = WDATA_S;
        LOAD_REQ        = 1'b0;
        WRITE_REQ       = 1'b0;

        // AXI default assignment
        ARREADY_S       = 1'b0;
        RID_S           = REQUEST_q.id;
        RDATA_S         = DO;
        RRESP_S         = `AXI_RESP_OKAY;
        RLAST_S         = 1'b0;
        RVALID_S        = 1'b0;
        AWREADY_S       = 1'b0;
        WREADY_S        = 1'b0;
        BID_S           = REQUEST_q.id;
        BRESP_S         = `AXI_RESP_OKAY;
        BVALID_S        = 1'b0;

        unique case (STATE_q)
            IDLE: begin
                // assert AR/SW ready to receive load/store request
                ARREADY_S = 1'b1;
                AWREADY_S = 1'b1;

                // wait for a read or write (AR/AW HandShake)
                if (ARVALID_S) begin
                    STATE_n   = READ;
                    REQUEST_n = {ARID_S, ARADDR_S, ARLEN_S, ARSIZE_S};

                    // We can now request the first read
                    // --> This can save time (SRAM needs two cycle to read)
                    LOAD_REQ        = 1'b1;
                    ADDRESS         = ARADDR_S;
                    brust_counter_n = 4'd1;

                end else if (AWVALID_S) begin
                    STATE_n   = WAIT_WVALID;
                    REQUEST_n = {AWID_S, AWADDR_S, AWLEN_S, AWSIZE_S};
                    WREADY_S  = 1'b1;

                    // we can now request the first write
                    // --> this can save time (No need one more cycle to store, AW/W channel work together)
                    // --> but we still need to wait for W channel handshake
                    if (WVALID_S) begin
                        WRITE_REQ       = 1'b1;
                        ADDRESS         = AWADDR_S;
                        brust_counter_n = 4'd1;
                        STATE_n         = (WLAST_S) ? (RESPONSE) : (WRITE);
                    end
                end
            end

            READ: begin
                // keep reading the same address
                LOAD_REQ = 1'b1;
                ADDRESS  = REQUEST_q.addr;

                // R channel response
                RVALID_S = 1'b1;
                RID_S    = REQUEST_q.id;
                RDATA_S  = DO;
                RLAST_S  = (brust_counter_q == REQUEST_q.len + 4'd1);

                // R channel handshake (Data is successfully transfered)
                // we can send next read address to SRAM
                if (RREADY_S) begin
                    RRESP_S         = `AXI_RESP_OKAY;
                    STATE_n         = (RLAST_S) ? IDLE : READ;
                    brust_counter_n = brust_counter_q + 4'd1;
                    
                    // calculate next read address
                    REQUEST_n.addr  = REQUEST_q.addr + (32'd1 << REQUEST_q.size);
                    ADDRESS         = REQUEST_n.addr;
                end
            end

            WAIT_WVALID : begin
                WREADY_S = 1'b1;

                // we can now request the first write
                if (WVALID_S) begin
                    WRITE_REQ       = 1'b1;
                    ADDRESS         = REQUEST_q.addr;
                    brust_counter_n = 4'd1;
                    STATE_n         = (WLAST_S) ? (RESPONSE) : (WRITE);
                end
            end

            WRITE : begin
                WREADY_S = 1'b1;

                // wait W channel handshake
                if (WVALID_S) begin
                    WRITE_REQ       = 1'b1;
                    REQUEST_n.addr  = REQUEST_q.addr + (32'd1 << REQUEST_q.size);
                    ADDRESS         = REQUEST_n.addr;
                    brust_counter_n = brust_counter_q + 4'd1;
                    STATE_n         = (WLAST_S) ? (RESPONSE) : (WRITE);
                end
            end

            RESPONSE : begin
                BVALID_S = 1'b1;
                BID_S    = REQUEST_q.id;

                // wait B channel handshake
                if (BREADY_S) begin
                    STATE_n = IDLE;
                    BRESP_S = `AXI_RESP_OKAY;
                end
            end

            default: STATE_n = IDLE;
        endcase
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            STATE_q         <= INIT;
            brust_counter_q <= 4'd0;
            REQUEST_q       <= REQUEST_t'(0);
        end else begin
            STATE_q         <= STATE_n;
            brust_counter_q <= brust_counter_n;
            REQUEST_q       <= REQUEST_n;
        end
    end

endmodule