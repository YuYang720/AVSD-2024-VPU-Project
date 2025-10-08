module DMA_wrapper (
    input  logic                      clk,
    input  logic                      rst,
    input  logic [31:0]               BASE_ADDR,

    // DMA interrupt port
    output logic                      DMA_interrupt_o,

    // AXI MASTER INTERFACE
    // AR channel
    output logic [`AXI_ID_BITS  -1:0] ARID_M,
    output logic [`AXI_DATA_BITS-1:0] ARADDR_M,
    output logic [`AXI_LEN_BITS -1:0] ARLEN_M,
    output logic [`AXI_SIZE_BITS-1:0] ARSIZE_M,
    output logic [1:0]                ARBURST_M,
    output logic                      ARVALID_M,
    input  logic                      ARREADY_M,
    // R channel
    input  logic [`AXI_ID_BITS  -1:0] RID_M,
    input  logic [`AXI_DATA_BITS-1:0] RDATA_M,
    input  logic [1:0]                RRESP_M,
    input  logic                      RLAST_M,
    input  logic                      RVALID_M,
    output logic                      RREADY_M,
    // AW channel
    output logic [`AXI_ID_BITS  -1:0] AWID_M,
    output logic [`AXI_ADDR_BITS-1:0] AWADDR_M,
    output logic [`AXI_LEN_BITS -1:0] AWLEN_M,
    output logic [`AXI_SIZE_BITS-1:0] AWSIZE_M,
    output logic [1:0]                AWBURST_M,
    output logic                      AWVALID_M,
    input  logic                      AWREADY_M,
    // W channel
    output logic [`AXI_DATA_BITS-1:0] WDATA_M,
    output logic [`AXI_STRB_BITS-1:0] WSTRB_M,
    output logic                      WLAST_M,
    output logic                      WVALID_M,
    input  logic                      WREADY_M,
    // B channel
    input  logic [`AXI_ID_BITS  -1:0] BID_M,
    input  logic [1:0]                BRESP_M,
    input  logic                      BVALID_M,
    output logic                      BREADY_M,

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
    //             Master : For reading            
    // --------------------------------------------
    // master reading FSM
    typedef enum logic [1:0] {
        MR_IDLE, MR_ADDR_TRANS, MR_DATA_TRANS
    } READ_STATE_t;

    READ_STATE_t               READ_STATE_q, READ_STATE_n;
    logic                      read_request; // <-- DMA
    logic [`AXI_ADDR_BITS-1:0] read_address; // <-- DMA
    logic [`AXI_LEN_BITS -1:0] read_length;  // <-- DMA
    logic                      read_finish;  // --> DMA
    logic                      read_valid;   // --> DMA
    logic [`AXI_DATA_BITS-1:0] read_data;    // --> DMA

    always_ff @(posedge clk) begin
        if (rst) READ_STATE_q <= MR_IDLE;
        else     READ_STATE_q <= READ_STATE_n;
    end

    always_comb begin
        READ_STATE_n = READ_STATE_q;

        // default AXI assignment
        ARVALID_M    = 1'b0;
        ARID_M       = `AXI_ID_BITS'd0;
        ARLEN_M      = `AXI_LEN_ONE;
        ARSIZE_M     = `AXI_SIZE_WORD;
        ARBURST_M    = `AXI_BURST_INC;
        ARADDR_M     = `AXI_ADDR_BITS'd0;
        RREADY_M     = 1'b0;

        // default output assignment
        read_finish  = 1'b0;
        read_valid   = 1'b0;
        read_data    = 32'd0;

        unique case (READ_STATE_q)
            MR_IDLE : begin
                // receive DMA request when read_request is asserted
                // otherwise, keep the previous read request
                if (read_request) begin
                    READ_STATE_n = MR_ADDR_TRANS;

                    // actually we can send request to AXI bridge right now
                    // assert AR valid, and set up read address
                    ARVALID_M = 1'b1;
                    ARADDR_M  = read_address;
                    ARLEN_M   = read_length;

                    // if AR handshake, go to next to receive data
                    if (ARREADY_M) READ_STATE_n = MR_DATA_TRANS;
                end
            end

            MR_ADDR_TRANS: begin
                ARVALID_M = 1'b1;
                ARADDR_M  = read_address;
                ARLEN_M   = read_length;

                // If AR handshake, go to next to receive data
                if (ARREADY_M) READ_STATE_n = MR_DATA_TRANS;
            end

            MR_DATA_TRANS: begin
                RREADY_M = 1'b1;

                // if R handshake, the data is valid right now
                if (RVALID_M) begin
                    read_valid = 1'b1;
                    read_data  = RDATA_M;
                end

                // received last data, go back to idle
                if (RVALID_M && RLAST_M) begin
                    read_finish  = 1'b1;
                    READ_STATE_n = MR_IDLE;
                end
            end

            default : READ_STATE_n = MR_IDLE;
        endcase
    end

    // --------------------------------------------
    //             Master : For writing            
    // --------------------------------------------
    // master writing FSM
    typedef enum logic [2:0] {
        MW_IDLE, MW_ADDR_TRANS, MW_DATA_TRANS, MW_RESSPONSE
    } WRITE_STATE_t;

    WRITE_STATE_t              WRITE_STATE_q, WRITE_STATE_n;
    logic                      write_request; // <-- DMA
    logic [`AXI_ADDR_BITS-1:0] write_address; // <-- DMA
    logic [`AXI_LEN_BITS -1:0] write_length;  // <-- DMA
    logic [`AXI_DATA_BITS-1:0] write_wData;   // <-- DMA
    logic                      write_last;    // <-- DMA
    logic                      write_valid;   // --> DMA
    logic                      write_finish;  // --> DMA

    always_ff @(posedge clk) begin
        if (rst) WRITE_STATE_q <= MW_IDLE;
        else     WRITE_STATE_q <= WRITE_STATE_n;
    end

    always_comb begin
        WRITE_STATE_n   = WRITE_STATE_q;

        // default AXI output assignment
        AWVALID_M = 1'b0;
        AWID_M    = 4'd0;
        AWLEN_M   = `AXI_LEN_ONE;
        AWSIZE_M  = `AXI_SIZE_WORD;
        AWBURST_M = `AXI_BURST_INC;
        AWADDR_M  = `AXI_ADDR_BITS'd0;
        WVALID_M  = 1'b0;
        WDATA_M   = `AXI_DATA_BITS'd0;
        WSTRB_M   = `AXI_STRB_WORD;
        WLAST_M   = 1'b0;
        BREADY_M  = 1'b0;

        // default DMA output assignment
        write_valid  = 1'b0;
        write_finish = 1'b0;

        unique case(WRITE_STATE_q)
            MW_IDLE : begin
                // receive DMA store request when store_request is asserted
                // otherwise, keep the previous store request
                if (write_request) begin
                    WRITE_STATE_n = MW_ADDR_TRANS;

                    // actually we can send request to AXI bridge right now
                    // if AW handshake, go to next to send data
                    // to speed up, the W channel can send right away when AW channel handshake
                    AWVALID_M = 1'b1;
                    AWADDR_M  = write_address;
                    AWLEN_M   = write_length;

                    if (AWREADY_M) begin
                        WRITE_STATE_n = MW_DATA_TRANS;

                        WVALID_M = 1'b1;
                        WDATA_M  = write_wData;
                        WLAST_M  = write_last;
                        
                        if (WREADY_M) write_valid = 1'b1;
                        if (WREADY_M && write_last) WRITE_STATE_n = MW_RESSPONSE;
                    end
                end
            end

            MW_ADDR_TRANS : begin
                AWVALID_M = 1'b1;
                AWADDR_M  = write_address;

                // if AW handshake, go to next to send data
                // to speed up, the W channel can send right away when AW channel handshake
                if (AWREADY_M) begin
                    WRITE_STATE_n = MW_DATA_TRANS;
                    
                    WVALID_M = 1'b1;
                    WDATA_M  = write_wData;
                    WLAST_M  = write_last;

                    if (WREADY_M) write_valid = 1'b1;
                    if (WREADY_M && write_last) WRITE_STATE_n = MW_RESSPONSE;
                end
            end

            MW_DATA_TRANS : begin
                WVALID_M = 1'b1;
                WDATA_M  = write_wData;
                WLAST_M  = write_last;

                if (WREADY_M) write_valid = 1'b1;
                if (WREADY_M && write_last) WRITE_STATE_n = MW_RESSPONSE;
            end

            MW_RESSPONSE : begin
                BREADY_M = 1'b1;

                if (BVALID_M) begin
                    WRITE_STATE_n = MW_IDLE;
                    write_finish  = 1'b1;
                end
            end

            default : WRITE_STATE_n = MW_IDLE;
        endcase
    end

    // --------------------------------------------
    //      Slave : Write DMA CSR (Write Only)     
    // --------------------------------------------
    // slave FSM
    typedef enum logic [2:0] {
        S_IDLE, S_WRITE, S_WAIT_WVALID, S_RESPONSE
    } SLAVE_STATE_t;

    // Request structute
    typedef struct packed {
        logic [`AXI_IDS_BITS -1:0] id;
        logic [`AXI_ADDR_BITS-1:0] addr;
        logic [`AXI_LEN_BITS -1:0] len;
        logic [`AXI_SIZE_BITS-1:0] size;
    } REQUEST_t;

    SLAVE_STATE_t SLAVE_STATE_q, SLAVE_STATE_n;
    logic         WRITE_REQ;
    logic [31:0]  ADDRESS, WRITE_DATA;
    logic [ 3:0]  brust_counter_q, brust_counter_n;
    REQUEST_t     REQUEST_q, REQUEST_n;

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
            S_IDLE : begin
                // assert AR/SW ready to receive load/store request
                AWREADY_S = 1'b1;

                // wait for a write (AW HandShake)
                if (AWVALID_S) begin
                    SLAVE_STATE_n = S_WAIT_WVALID;
                    REQUEST_n     = {AWID_S, AWADDR_S, AWLEN_S, AWSIZE_S};
                    WREADY_S      = 1'b1;

                    // we can now request the first write
                    // --> this can save time (No need one more cycle to store, AW/W channel work together)
                    // --> but we still need to wait for W channel handshake
                    if (WVALID_S) begin
                        WRITE_REQ       = 1'b1;
                        ADDRESS         = AWADDR_S;
                        brust_counter_n = 4'd1;
                        SLAVE_STATE_n   = (WLAST_S) ? (S_RESPONSE) : (S_WRITE);
                    end
                end
            end

            S_WAIT_WVALID : begin
                WREADY_S = 1'b1;

                // we can now request the first write
                if (WVALID_S) begin
                    WRITE_REQ       = 1'b1;
                    ADDRESS         = REQUEST_q.addr;
                    brust_counter_n = 4'd1;
                    SLAVE_STATE_n   = (WLAST_S) ? (S_RESPONSE) : (S_WRITE);
                end
            end

            S_WRITE : begin
                WREADY_S = 1'b1;

                // wait W channel handshake
                if (WVALID_S) begin
                    WRITE_REQ       = 1'b1;
                    REQUEST_n.addr  = REQUEST_q.addr + (32'd1 << REQUEST_q.size);
                    ADDRESS         = REQUEST_q.addr;
                    brust_counter_n = brust_counter_q + 4'd1;
                    SLAVE_STATE_n   = (WLAST_S) ? (S_RESPONSE) : (S_WRITE);
                end

            end

            S_RESPONSE : begin
                BVALID_S = 1'b1;
                BID_S    = REQUEST_q.id;

                // wait B channel handshake
                if (BREADY_S) begin
                    BRESP_S       = `AXI_RESP_OKAY;
                    SLAVE_STATE_n = S_IDLE;
                end
            end

            default: SLAVE_STATE_n = S_IDLE;
        endcase
    end

    // --------------------------------------------
    //           Master / Slave <---> DMA          
    // --------------------------------------------
    DMA DMA(
        .clk,
        .rst,

        .DMA_interrupt_o,
        .valid_i        (WRITE_REQ          ),
        .address_i      (ADDRESS - BASE_ADDR),
        .DMAEN          (WRITE_DATA[0]      ),
        .DMASRC         (WRITE_DATA         ),
        .DMADST         (WRITE_DATA         ),
        .DMALEN         (WRITE_DATA         ),

        .READ_REQUEST   (read_request       ),
        .READ_ADDRESS   (read_address       ),
        .READ_LEN       (read_length        ),
        .READ_VALID     (read_valid         ),
        .READ_DATA      (read_data          ),
        .READ_FINISH    (read_finish        ),
    
        .WRITE_REQUEST  (write_request      ),
        .WRITE_ADDRESS  (write_address      ),
        .WRITE_LEN      (write_length       ),
        .WRITE_DATA     (write_wData        ),
        .WRITE_LAST     (write_last         ),
        .WRITE_VALID    (write_valid        ),
        .WRITE_FINISH   (write_finish       )
    );

endmodule