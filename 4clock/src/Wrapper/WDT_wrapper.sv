module WDT_wrapper (
    input  logic                      clk,
    input  logic                      rst,
    input  logic                      clk2, // cpu clk
    input  logic                      rst2, // cpu rst
    input  logic [31:0]               BASE_ADDR,
    output logic                      WDT_interrupt_o,

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
    //      Slave : Write WDT CSR (Write Only)     
    // --------------------------------------------

    // Slave FSM
    typedef enum logic [2:0] {
        S_IDLE, S_WRITE, S_WAIT_WVALID, S_RESPONSE
    } SLAVE_STATE;

    // Request structute
    typedef struct packed {
        logic [`AXI_IDS_BITS -1:0] id;
        logic [`AXI_ADDR_BITS-1:0] addr;
        logic [`AXI_LEN_BITS -1:0] len;
        logic [`AXI_SIZE_BITS-1:0] size;
    } REQUEST_t;

    SLAVE_STATE  SLAVE_STATE_q, SLAVE_STATE_n;
    logic        WRITE_REQ;
    logic [31:0] ADDRESS, WRITE_DATA;
    logic [ 3:0] brust_counter_q, brust_counter_n;
    REQUEST_t    REQUEST_q, REQUEST_n;

    always_ff @(posedge clk) begin
        if (rst) begin
            SLAVE_STATE_q   <= S_IDLE;
            brust_counter_q <= 4'd0;
            REQUEST_q       <= REQUEST_t'(0);
        end else begin
            SLAVE_STATE_q   <= SLAVE_STATE_n;
            brust_counter_q <= brust_counter_n;
            REQUEST_q       <= REQUEST_n;
        end
    end

    always_comb begin
        
        // default assignment
        SLAVE_STATE_n   = SLAVE_STATE_q;
        REQUEST_n       = REQUEST_q;
        brust_counter_n = brust_counter_q;

        // Memory default assignment
        WRITE_REQ       = 1'b0;
        ADDRESS         = 32'd0;
        WRITE_DATA      = WDATA_S;

        // AXI default assignment
        ARREADY_S       = 1'b0;
        RID_S           = REQUEST_q.id;
        RDATA_S         = 32'd0;
        RRESP_S         = `AXI_RESP_OKAY;
        RLAST_S         = 1'b0;
        RVALID_S        = 1'b0;
        AWREADY_S       = 1'b0;
        WREADY_S        = 1'b0;
        BID_S           = REQUEST_q.id;
        BRESP_S         = `AXI_RESP_OKAY;
        BVALID_S        = 1'b0;

        unique case (SLAVE_STATE_q)
            
            S_IDLE: begin

                // Assert AR/SW ready to receive load/store request
                AWREADY_S = 1'b1;

                // Wait for a write (AW HandShake)
                if(AWVALID_S) begin
                    SLAVE_STATE_n = S_WAIT_WVALID;
                    REQUEST_n     = {AWID_S, AWADDR_S, AWLEN_S, AWSIZE_S};
                    WREADY_S      = 1'b1;

                    // We can now request the first write
                    // --> This can save time (No need one more cycle to store, AW/W channel work together)
                    // --> But we still need to wait for W channel handshake
                    if(WVALID_S) begin
                        WRITE_REQ       = 1'b1;
                        ADDRESS         = AWADDR_S;
                        brust_counter_n = 4'd1;
                        SLAVE_STATE_n   = (WLAST_S) ? (S_RESPONSE) : (S_WRITE);
                    end
                end
            end

            S_WAIT_WVALID: begin
                WREADY_S = 1'b1;

                // We can now request the first write
                if(WVALID_S) begin
                    WRITE_REQ       = 1'b1;
                    ADDRESS         = REQUEST_q.addr;
                    brust_counter_n = 4'd1;
                    SLAVE_STATE_n   = (WLAST_S) ? (S_RESPONSE) : (S_WRITE);
                end
            end

            S_WRITE: begin
                WREADY_S = 1'b1;

                // Wait W channel handshake
                if(WVALID_S) begin
                    WRITE_REQ       = 1'b1;
                    REQUEST_n.addr  = REQUEST_q.addr + (32'd1 << REQUEST_q.size);
                    ADDRESS         = REQUEST_n.addr;
                    brust_counter_n = brust_counter_q + 4'd1;
                    SLAVE_STATE_n   = (WLAST_S) ? (S_RESPONSE) : (S_WRITE);
                end

            end

            S_RESPONSE: begin
                BVALID_S = 1'b1;
                BID_S    = REQUEST_q.id;

                // Wait B channel handshake
                if(BREADY_S) begin
                    BRESP_S       = `AXI_RESP_OKAY;
                    SLAVE_STATE_n = S_IDLE;
                end
            end

            default: begin
                // Nothing to do
            end
        endcase
    end
    
    // --------------------------------------------
    //                  DMA                 
    // --------------------------------------------
    logic        WDEN_q;
    logic        WDLIVE_q;
    logic [31:0] WTOCNT_q;
    logic        WDEN_write, WDLIVE_write, WTOCNT_write;

    logic        WTO_write, WTO_interrupt;
    logic        WTO_q, WTO_n, WTO_valid, WTO_rempty_n;
    
    // Store the request, and check which one to write
    assign WDEN_write   = WRITE_REQ & (ADDRESS - BASE_ADDR == 32'h0000_0100);
    assign WDLIVE_write = WRITE_REQ & (ADDRESS - BASE_ADDR == 32'h0000_0200);
    assign WTOCNT_write = WRITE_REQ & (ADDRESS - BASE_ADDR == 32'h0000_0300);

    always_ff @(posedge clk) begin
        if (rst) begin
            WDEN_q   <= 1'b0;
            WDLIVE_q <= 1'b0;
            WTOCNT_q <= 32'd0;
        end else begin
            WDEN_q   <= (WDEN_write  ) ? (WRITE_DATA[0]) : (WDEN_q  );
            WDLIVE_q <= (WDLIVE_write) ? (|WRITE_DATA  ) : (WDLIVE_q);
            WTOCNT_q <= (WTOCNT_write) ? (WRITE_DATA   ) : (WTOCNT_q);
        end
    end

    WDT WDT(
        .clk      (clk          ),
        .rst      (rst          ),
        .WDEN     (WDEN_q       ),
        .WDLIVE   (WDLIVE_q     ),
        .WTOCNT   (WTOCNT_q     ),
        .WTO      (WTO_interrupt),
        .WTO_write(WTO_write    )
    );

    Async_FIFO_1bit WTO_FIFO (
        .w_clk   (clk          ),
        .w_rst   (rst          ),
        .w_push  (WTO_write    ),
        .w_data  (WTO_interrupt),
        .w_full  (             ),

        .r_clk   (clk2         ),
        .r_rst   (rst2         ),
        .r_pop   (1'b1         ),
        .r_data  (WTO_n        ),
        .r_empty (WTO_rempty_n )
    );

    // Store the read value from FIFO
    always_ff @(posedge clk2) begin
        if (rst2) begin
            WTO_q     <= 1'b0;
            WTO_valid <= 1'b0;
        end else begin
            WTO_valid <= ~WTO_rempty_n;
            WTO_q     <= (WTO_valid) ? (WTO_n) : (WTO_q);
        end
    end

    assign WDT_interrupt_o = WTO_q;

endmodule