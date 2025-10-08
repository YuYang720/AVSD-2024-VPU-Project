module ROM_wrapper (
    input  logic                      clk,
    input  logic                      rst,
    input  logic [31:0]               BASE_ADDR,

    // ROM memory port
    input  logic [31:0]               ROM_out,
    output logic                      ROM_read,
    output logic                      ROM_enable,
    output logic [11:0]               ROM_address,

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
    // slave FSM
    typedef enum logic [1:0] {IDLE, READ} STATE_t;

    // request structute
    typedef struct packed {
        logic [`AXI_IDS_BITS -1:0] id;
        logic [`AXI_ADDR_BITS-1:0] addr;
        logic [`AXI_LEN_BITS -1:0] len;
        logic [`AXI_SIZE_BITS-1:0] size;
    } REQUEST_t;

    STATE_t      STATE_q, STATE_n;
    REQUEST_t    REQUEST_q, REQUEST_n;
    logic [3:0]  brust_counter_q, brust_counter_n;
    logic [31:0] read_addr;

    // --------------------------------------------
    //                  AXI Slave                  
    // --------------------------------------------
    always_comb begin
        STATE_n         = STATE_q;
        REQUEST_n       = REQUEST_q;
        brust_counter_n = brust_counter_q;

        // Memory port assignment
        read_addr       = REQUEST_q.addr - BASE_ADDR;
        ROM_enable      = 1'b0;
        ROM_read        = 1'b0;
        ROM_address     = read_addr[13:2];

        // AXI default assignment
        ARREADY_S       = 1'b0;
        RID_S           = REQUEST_q.id;
        RDATA_S         = ROM_out;
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
                // assert AR ready to receive load request
                ARREADY_S = 1'b1;

                // wait for ROM_address read (AR HandShake)
                if (ARVALID_S) begin
                    STATE_n   = READ;
                    REQUEST_n = {ARID_S, ARADDR_S, ARLEN_S, ARSIZE_S};

                    // we can now request the first read
                    // --> this can save time (ROM needs two cycle to read)
                    ROM_enable      = 1'b1;
                    ROM_address     = ARADDR_S[13:2];
                    brust_counter_n = 4'd1;
                end
            end

            READ : begin
                // keep reading the same address, the output is valid right now
                ROM_enable  = 1'b1;
                ROM_read    = 1'b1;
                ROM_address = REQUEST_q.addr[13:2];

                // R channel response
                RVALID_S    = 1'b1;
                RID_S       = REQUEST_q.id;
                RDATA_S     = ROM_out;
                RLAST_S     = (brust_counter_q == REQUEST_q.len + 4'd1);

                // R channel handshake (Data is successfully transfered)
                // we can send next read address to SRAM
                if (RREADY_S) begin
                    RRESP_S         = `AXI_RESP_OKAY;
                    STATE_n         = (RLAST_S) ? IDLE : READ;
                    brust_counter_n = brust_counter_q + 4'd1;
                    
                    // calculate next read address
                    REQUEST_n.addr  = REQUEST_q.addr + (32'd1 << REQUEST_q.size);
                    ROM_address     = REQUEST_n.addr[13:2];
                end
            end

            default : STATE_n = IDLE;// Do nothing
        endcase
    end

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

endmodule