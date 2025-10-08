module WDT_wrapper (
    input  logic                      clk,
    input  logic                      rst,
    input  logic                      wdt_clk,
    input  logic                      wdt_rst,
    input  logic [31:0]               BASE_ADDR,
    output logic                      WDT_interrupt_o,

    // AXI SLAVE INTERFACE
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
    //                  Async FIFO                 
    // --------------------------------------------
    logic        WDEN_write_q, WDLIVE_write_q, WTOCNT_write_q;
    logic [31:0] WDT_DATA;
    
    // Store the request, and check which one to write
    always_ff @(posedge clk) begin
        if (rst) begin
            WDEN_write_q   <= 1'b0;
            WDLIVE_write_q <= 1'b0;
            WTOCNT_write_q <= 1'b0;
            WDT_DATA       <= 32'd0;
        end else begin
            WDEN_write_q   <= WRITE_REQ & (ADDRESS - BASE_ADDR == 32'h0000_0100);
            WDLIVE_write_q <= WRITE_REQ & (ADDRESS - BASE_ADDR == 32'h0000_0200);
            WTOCNT_write_q <= WRITE_REQ & (ADDRESS - BASE_ADDR == 32'h0000_0300);
            WDT_DATA       <= WRITE_DATA;
        end
    end

    logic        WDEN_rempty_n, WDLIVE_rempty_n, WTOCNT_rempty_n, WTO_rempty_n;
    logic        WDEN_valid, WDLIVE_valid, WTOCNT_valid, WTO_valid;
    logic        WDEN_q, WDEN_n;
    logic        WDLIVE_q, WDLIVE_n;
    logic [31:0] WTOCNT_q, WTOCNT_n;
    logic        WTO_q, WTO_n;
    logic        WTO_write, WDT_interrupt;

    // Store the read value from FIFO
    always_ff @(posedge clk) begin
        if (rst) begin
            WTO_q     <= 1'b0;
            WTO_valid <= 1'b0;
        end else begin
            WTO_valid <= ~WTO_rempty_n;
            WTO_q     <= (WTO_valid) ? (WTO_n) : (WTO_q);
        end
    end

    // Store the read value form FIFO
    always_ff @(posedge wdt_clk) begin
        if (wdt_rst)  begin
            WDEN_q       <= 1'b0;
            WDLIVE_q     <= 1'b0;
            WTOCNT_q     <= 32'd0;
            WDEN_valid   <= 1'b0;
            WDLIVE_valid <= 1'b0;
            WTOCNT_valid <= 1'b0;
        end else begin
            WDEN_valid   <= ~WDEN_rempty_n;
            WDLIVE_valid <= ~WDLIVE_rempty_n;
            WTOCNT_valid <= ~WTOCNT_rempty_n;
            WDEN_q       <= (WDEN_valid  ) ? (WDEN_n  ) : (WDEN_q);
            WDLIVE_q     <= (WDLIVE_valid) ? (WDLIVE_n) : (WDLIVE_q);
            WTOCNT_q     <= (WTOCNT_valid) ? (WTOCNT_n) : (WTOCNT_q);
        end
    end


    Async_FIFO_1bit WDEN_FIFO (
        .w_clk   (clk          ),
        .w_rst   (rst          ),
        .w_push  (WDEN_write_q ),
        .w_data  (WDT_DATA[0]  ),
        .w_full  (             ),

        .r_clk   (wdt_clk      ),
        .r_rst   (wdt_rst      ),
        .r_pop   (1'b1         ),
        .r_data  (WDEN_n       ),
        .r_empty (WDEN_rempty_n)
    );

    Async_FIFO_1bit WDLIVE_FIFO (
        .w_clk   (clk            ),
        .w_rst   (rst            ),
        .w_push  (WDLIVE_write_q ),
        .w_data  (WDT_DATA[0]    ),
        .w_full  (               ),

        .r_clk   (wdt_clk        ),
        .r_rst   (wdt_rst        ),
        .r_pop   (1'b1           ),
        .r_data  (WDLIVE_n       ),
        .r_empty (WDLIVE_rempty_n)
    );

    Async_FIFO_32bit WTOCNT_FIFO (
        .w_clk   (clk            ),
        .w_rst   (rst            ),
        .w_push  (WTOCNT_write_q ),
        .w_data  (WDT_DATA       ),
        .w_full  (               ),

        .r_clk   (wdt_clk        ),
        .r_rst   (wdt_rst        ),
        .r_pop   (1'b1           ),
        .r_data  (WTOCNT_n       ),
        .r_empty (WTOCNT_rempty_n)
    );

    Async_FIFO_1bit WTO_FIFO (
        .w_clk   (wdt_clk      ),
        .w_rst   (wdt_rst      ),
        .w_push  (WTO_write    ),
        .w_data  (WTO_interrupt),
        .w_full  (             ),

        .r_clk   (clk          ),
        .r_rst   (rst          ),
        .r_pop   (1'b1         ),
        .r_data  (WTO_n        ),
        .r_empty (WTO_rempty_n )
    );

    // --------------------------------------------
    //                  DMA                 
    // --------------------------------------------
    WDT WDT(
        .clk      (wdt_clk      ),
        .rst      (wdt_rst      ),
        .WDEN     (WDEN_q       ),
        .WDLIVE   (WDLIVE_q     ),
        .WTOCNT   (WTOCNT_q     ),
        .WTO      (WTO_interrupt),
        .WTO_write(WTO_write    )
    );

    assign WDT_interrupt_o = WTO_q;

endmodule