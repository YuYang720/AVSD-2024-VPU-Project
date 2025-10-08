module DRAM_wrapper (
    input  logic                      clk,
    input  logic                      rst,
    input  logic [31:0]               BASE_ADDR,

    // DRAM memory ports
    input  logic [31:0]               DRAM_Q,
    input  logic                      DRAM_valid,
    output logic                      DRAM_CSn,
    output logic [3:0]                DRAM_WEn,
    output logic                      DRAM_RASn,
    output logic                      DRAM_CASn,
    output logic [10:0]               DRAM_A,
    output logic [31:0]               DRAM_D,

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
    //              Signal Declaration             
    // --------------------------------------------
    // AXI Slave FSM
    typedef enum logic [2:0] {
        IDLE, READ, WAIT_RREADY, WRITE, WAIT_WVALID, RESPONSE
    } AXI_STATE_t;

    // DRAM FSM
    typedef enum logic [2:0] {
        INIT, DRAM_ACT, DRAM_READ, DRAM_WRITE, DRAM_PRE
    } DRAM_STATE_t;

    // AXI slave request
    typedef struct packed {
        logic [`AXI_IDS_BITS -1:0] id;    // AXI id
        logic [`AXI_ADDR_BITS-1:0] addr;  // Read/Write address
        logic [`AXI_LEN_BITS -1:0] len;   // Burst number
        logic [`AXI_SIZE_BITS-1:0] size;  // Burst size
        logic [`AXI_DATA_BITS-1:0] data;  // Read/Write Data
        logic [`AXI_STRB_BITS-1:0] wstrb; // Write enable
        logic                      wlast; // Last write
    } REQUEST_t;

    // AXI slave control
    AXI_STATE_t  STATE_q, STATE_n;
    logic [ 3:0] brust_counter_q, brust_counter_n;
    REQUEST_t    REQUEST_q, REQUEST_n;
    
    // <--> DRAM controller (DRAM request)
    logic        WRITE_REQ, LOAD_REQ, VALID;
    logic [31:0] READ_DATA, WRITE_DATA, ADDRESS;
    logic [ 3:0] BWEB;

    // DRAM control signal
    DRAM_STATE_t DRAM_STATE_q, DRAM_STATE_n;
    logic [31:0] dram_address;
    logic [10:0] row_addr, col_addr;
    logic [10:0] activated_row_q, activated_row_n;
    logic [2:0]  row_delay_q, column_delay_q, precharge_q;
    logic [2:0]  row_delay_n, column_delay_n, precharge_n;

    // --------------------------------------------
    //            AXI Slave Controller             
    // --------------------------------------------
    always_ff @(posedge clk) begin
        if (rst) begin
            STATE_q         <= IDLE;
            brust_counter_q <= 4'd0;
            REQUEST_q       <= REQUEST_t'(0);
        end else begin
            STATE_q         <= STATE_n;
            brust_counter_q <= brust_counter_n;
            REQUEST_q       <= REQUEST_n;
        end
    end
    
    always_comb begin
        STATE_n         = STATE_q;
        REQUEST_n       = REQUEST_q;
        brust_counter_n = brust_counter_q;

        // DRAM request default assignment
        LOAD_REQ        = 1'b0;
        WRITE_REQ       = 1'b0;
        ADDRESS         = 32'd0;
        WRITE_DATA      = 32'd0;
        BWEB            = 4'd0;

        // AXI slave output default assignment
        ARREADY_S       = 1'b0;
        RID_S           = REQUEST_q.id;
        RDATA_S         = DRAM_Q;
        RRESP_S         = `AXI_RESP_OKAY;
        RLAST_S         = 1'b0;
        RVALID_S        = 1'b0;
        AWREADY_S       = 1'b0;
        WREADY_S        = 1'b0;
        BID_S           = REQUEST_q.id;
        BRESP_S         = `AXI_RESP_OKAY;
        BVALID_S        = 1'b0;

        unique case (STATE_q)
            IDLE : begin
                // assert AR/SW ready to receive load/store request
                ARREADY_S = 1'b1;
                AWREADY_S = 1'b1;

                // wait for a read or write (AR/AW HandShake)
                if (ARVALID_S) begin
                    REQUEST_n.id    = ARID_S;
                    REQUEST_n.addr  = ARADDR_S;
                    REQUEST_n.len   = ARLEN_S;
                    REQUEST_n.size  = ARSIZE_S;
                    REQUEST_n.data  = 32'd0;

                    // we can now request the first read to DRAM
                    STATE_n         = READ;
                    brust_counter_n = 4'd1;
                    LOAD_REQ        = 1'b1;
                    ADDRESS         = ARADDR_S;

                end else if (AWVALID_S) begin
                    REQUEST_n.id    = AWID_S;
                    REQUEST_n.addr  = AWADDR_S;
                    REQUEST_n.len   = AWLEN_S;
                    REQUEST_n.size  = AWSIZE_S;
                    REQUEST_n.data  = 32'd0;
                    REQUEST_n.wstrb = 4'd0;
                    REQUEST_n.wlast = 1'b0;

                    // we can now request the first write
                    // --> this can save time (AW/W channel work together)
                    // --> but we still need to wait for W channel handshake
                    WREADY_S = 1'b1;
                    STATE_n  = WAIT_WVALID;

                    if (WVALID_S) begin
                        REQUEST_n.data  = WDATA_S;
                        REQUEST_n.wstrb = WSTRB_S;
                        REQUEST_n.wlast = WLAST_S;
                        brust_counter_n = 4'd1;
                        STATE_n         = WRITE;

                        // send request to DRAM controller
                        WRITE_REQ       = 1'b1;
                        ADDRESS         = AWADDR_S;
                        WRITE_DATA      = WDATA_S;
                        BWEB            = WSTRB_S;
                    end
                end
            end

            READ : begin
                // keep reading the same address until data is read out
                LOAD_REQ = 1'b1;
                ADDRESS  = REQUEST_q.addr;

                // whenever the data is read out from DRAM (VALID == 1)
                // we can give R channel response, and turn off the load request
                if (VALID) begin
                    LOAD_REQ       = 1'b0;      // turn off load request
                    REQUEST_n.data = READ_DATA; // update the request result

                    // R channel response
                    RVALID_S = 1'b1;
                    RID_S    = REQUEST_q.id;
                    RDATA_S  = READ_DATA;
                    RLAST_S  = (brust_counter_q == REQUEST_q.len + 4'd1);
                end

                // R channel handshake (Data is successfully transfered)
                if (RVALID_S && RREADY_S) begin
                    RRESP_S         = `AXI_RESP_OKAY;
                    STATE_n         = IDLE;
                    brust_counter_n = brust_counter_q + 4'd1;
                    
                    // if have left burst request
                    // we can send next read address to SRAM
                    if (!RLAST_S) begin
                        STATE_n        = READ;
                        REQUEST_n.addr = REQUEST_q.addr + (32'd1 << REQUEST_q.size);
                        LOAD_REQ       = 1'b1;
                        ADDRESS        = REQUEST_n.addr;
                    end
                end

                // if only RVALID is asserted
                // the data is valid but can't transfer right away
                // go to WAIT_RREADY to wait data transfer
                if (RVALID_S && !RREADY_S) STATE_n = WAIT_RREADY;
            end

            WAIT_RREADY : begin
                // give R channel response
                RVALID_S = 1'b1;
                RID_S    = REQUEST_q.id;
                RDATA_S  = REQUEST_q.data;
                RLAST_S  = (brust_counter_q == REQUEST_q.len + 4'd1);

                // R channel handshake (data is successfully transfered)
                if (RVALID_S && RREADY_S) begin
                    RRESP_S         = `AXI_RESP_OKAY;
                    STATE_n         = IDLE;
                    brust_counter_n = brust_counter_q + 4'd1;

                    // if have left burst request
                    // we can send next read address to SRAM
                    if (!RLAST_S) begin
                        STATE_n        = READ;
                        REQUEST_n.addr = REQUEST_q.addr + (32'd1 << REQUEST_q.size);
                        LOAD_REQ       = 1'b1;
                        ADDRESS        = REQUEST_n.addr;
                    end
                end
            end

            WAIT_WVALID : begin
                WREADY_S = 1'b1;

                // we can now request the first write
                if (WVALID_S) begin
                    REQUEST_n.data  = WDATA_S;
                    REQUEST_n.wstrb = WSTRB_S;
                    REQUEST_n.wlast = WLAST_S;
                    brust_counter_n = 4'd1;
                    STATE_n         = WRITE;

                    // send request to DRAM controller
                    WRITE_REQ       = 1'b1;
                    ADDRESS         = REQUEST_q.addr;
                    WRITE_DATA      = REQUEST_q.data;
                    BWEB            = REQUEST_q.wstrb;
                end
            end

            WRITE : begin
                // the data is received by W channel
                // keep sending store request to DRAM, and wait for store valid
                WRITE_REQ  = 1'b1;
                ADDRESS    = REQUEST_q.addr;
                WRITE_DATA = REQUEST_q.data;
                BWEB       = REQUEST_q.wstrb;

                // whenever the data is writen in the DRAM (VALID == 1)
                // we can turn off the store request, and check if have left burst request
                if (VALID && !REQUEST_q.wlast) begin
                    // turn off store request
                    WRITE_REQ = 1'b0;

                    // we can received next write (if have)
                    WREADY_S  = 1'b1;
                    STATE_n   = WAIT_WVALID;

                    if (WVALID_S) begin
                        REQUEST_n.addr  = REQUEST_q.addr + (32'd1 << REQUEST_q.size);
                        REQUEST_n.data  = WDATA_S;
                        REQUEST_n.wstrb = WSTRB_S;
                        REQUEST_n.wlast = WLAST_S;
                        brust_counter_n = brust_counter_q + 4'd1;
                        STATE_n         = WRITE;

                        // send next request to DRAM controller
                        WRITE_REQ       = 1'b1;
                        ADDRESS         = REQUEST_n.addr;
                        WRITE_DATA      = WDATA_S;
                        BWEB            = WSTRB_S;
                    end
                end

                // if the last write is finish, go to RESPONSE state
                if (VALID && REQUEST_q.wlast) begin
                    WRITE_REQ = 1'b0;   // turn off store request
                    STATE_n = RESPONSE;
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

    // --------------------------------------------
    //              DRAM Controller                
    // --------------------------------------------
    always_ff @(posedge clk) begin
        if (rst) begin
            DRAM_STATE_q    <= INIT;
            activated_row_q <= 11'd0;
            row_delay_q     <= 3'd0;
            column_delay_q  <= 3'd0;
            precharge_q     <= 3'd0;
        end else begin
            DRAM_STATE_q    <= DRAM_STATE_n;
            activated_row_q <= activated_row_n;
            row_delay_q     <= row_delay_n;
            column_delay_q  <= column_delay_n;
            precharge_q     <= precharge_n;
        end
    end

    always_comb begin
        DRAM_STATE_n    = DRAM_STATE_q;
        activated_row_n = activated_row_q;
        row_delay_n     = row_delay_q;
        column_delay_n  = column_delay_q;
        precharge_n     = precharge_q;

        // default address assignment
        dram_address    = ADDRESS - BASE_ADDR;
        row_addr        = dram_address[22:12];
        col_addr        = {1'b0, dram_address[11: 2]};

        // DRAM memory port default assignment
        DRAM_CSn  = 1'b0;    // active low --> always turn on DRAM
        DRAM_RASn = 1'b1;    // active low
        DRAM_CASn = 1'b1;    // active low
        DRAM_WEn  = 4'hf;    // active low
        DRAM_A    = 11'd0;
        DRAM_D    = 32'd0;

        // DRAM request default assignment
        VALID     = 1'b0;
        READ_DATA = 32'd0;

        unique case (DRAM_STATE_q)
            // init the first row to become activated (row = 0)
            // DRAM will activate the row, so we just set the precharge to 5
            INIT : begin
                precharge_n  = 3'd5;

                if(LOAD_REQ | WRITE_REQ) DRAM_STATE_n = DRAM_ACT;
            end

            // in this state, a row will be activated
            // --> we use row_addr to perform row access
            // --> after a row is activated,
            // --> we can probe CASn once and go to next state waiting column access
            DRAM_ACT : begin
                // waiting for the row access
                priority if (row_delay_q > 3'd0 && row_delay_q < 3'd5) begin
                    row_delay_n = row_delay_q + 3'd1;

                // probe RASn to access a new row
                end else if (precharge_q == 3'd5) begin
                    DRAM_RASn       = 1'b0;
                    DRAM_CASn       = 1'b1;
                    DRAM_WEn        = 4'hf;
                    DRAM_A          = row_addr;

                    row_delay_n     = 3'd1; // start counting the delay
                    precharge_n     = 3'd0; // reset precharge
                    activated_row_n = row_addr;
                    DRAM_STATE_n    = DRAM_ACT;

                // wow is activated, wait for a read or write operation
                // the request row address hit activated row
                end else begin

                    if (LOAD_REQ) begin
                        DRAM_RASn      = 1'b1;
                        DRAM_CASn      = 1'b0;
                        DRAM_WEn       = 4'hf;
                        DRAM_A         = col_addr;

                        column_delay_n = 3'd1;
                        DRAM_STATE_n   = DRAM_READ;
                    end else if (WRITE_REQ) begin
                        DRAM_RASn      = 1'b1;
                        DRAM_CASn      = 1'b0;
                        DRAM_WEn       = ~BWEB;
                        DRAM_A         = col_addr;

                        column_delay_n = 3'd1;
                        DRAM_STATE_n   = DRAM_WRITE;
                    end
                end
            end

            DRAM_READ : begin
                // waiting for column access
                if (column_delay_q > 3'd0 && column_delay_q < 3'd5) begin
                    column_delay_n = column_delay_q + 3'd1;

                // the access is finish, wait for next read or write operation
                end else begin
 
                    if (DRAM_valid) begin
                        VALID     = 1'b1;
                        READ_DATA = DRAM_Q;
                    end

                    // wait for next read or write operation
                    // but still need to check if row hit
                    if ((LOAD_REQ || WRITE_REQ) && (activated_row_q != row_addr)) begin
                        DRAM_RASn    = 1'b0;
                        DRAM_CASn    = 1'b1;
                        DRAM_WEn     = 4'h0;
                        DRAM_A       = activated_row_q;

                        precharge_n  = 3'd1; // reset the row delay
                        DRAM_STATE_n = DRAM_PRE;

                    // the request row address hit activated row
                    end else begin

                        if (LOAD_REQ) begin
                            DRAM_RASn      = 1'b1;
                            DRAM_CASn      = 1'b0;
                            DRAM_WEn       = 4'hf;
                            DRAM_A         = col_addr;

                            column_delay_n = 3'd1;
                            DRAM_STATE_n   = DRAM_READ;
                        end else if (WRITE_REQ) begin
                            DRAM_RASn      = 1'b1;
                            DRAM_CASn      = 1'b0;
                            DRAM_WEn       = ~BWEB;
                            DRAM_A         = col_addr;

                            column_delay_n = 3'd1;
                            DRAM_STATE_n   = DRAM_WRITE;
                        end
                    end
                end
            end

            DRAM_WRITE : begin
                // waiting for column access
                if (column_delay_q > 3'd0 && column_delay_q < 3'd5) begin
                    column_delay_n = column_delay_q + 3'd1;
                    
                    VALID  = (column_delay_q == 3'd4);
                    DRAM_D = WRITE_DATA;

                // the access is finish, wait for next read or write operation
                end else begin

                    // wait for next read or write operation
                    // but still need to check if row hit
                    if ((LOAD_REQ || WRITE_REQ) && (activated_row_q != row_addr)) begin
                        DRAM_RASn    = 1'b0;
                        DRAM_CASn    = 1'b1;
                        DRAM_WEn     = 4'h0;
                        DRAM_A       = activated_row_q;

                        precharge_n  = 3'd1; // reset the row delay
                        DRAM_STATE_n = DRAM_PRE;

                    // the request row address hit activated row
                    end else begin

                        if (LOAD_REQ) begin
                            DRAM_RASn      = 1'b1;
                            DRAM_CASn      = 1'b0;
                            DRAM_WEn       = 4'hf;
                            DRAM_A         = col_addr;

                            column_delay_n = 3'd1;
                            DRAM_STATE_n   = DRAM_READ;
                        end else if (WRITE_REQ) begin
                            DRAM_RASn      = 1'b1;
                            DRAM_CASn      = 1'b0;
                            DRAM_WEn       = ~BWEB;
                            DRAM_A         = col_addr;

                            column_delay_n = 3'd1;
                            DRAM_STATE_n   = DRAM_WRITE;
                        end
                    end
                end
            end

            DRAM_PRE : begin
                precharge_n = precharge_q + 3'd1;
                if (precharge_q == 3'd4) DRAM_STATE_n = DRAM_ACT;
            end

            default : begin
                // Nothing to do
            end
        endcase
    end

endmodule