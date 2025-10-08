module L1C_inst (
    input  logic        clk_i,
    input  logic        rst_i,

    // core <-> D$
    input  logic        core_req_i,
    input  logic [31:0] core_pc_i,
    output logic        core_wait_o,
    output logic [31:0] core_addr_o,
    output logic [31:0] core_out_o,

    // D$ <-> master0
    output logic        D_req_o,
    output logic [31:0] D_addr_o,
    input  logic        D_wait_i,
    input  logic        D_out_valid_i,
    input  logic [31:0] D_out_i
);

    // --------------------------------------------
    //              Signal Declaration             
    // --------------------------------------------
    typedef enum logic [1:0] {
        IDLE,       // accept a read/write request from core
        READ,       // read the data from cache line
        WAIT_AXI    // wait for axi transfer
    } CACHE_STATE_t;

    typedef struct packed {
        logic        valid;
        logic [31:0] core_addr;
        logic [ 3:0] core_count;
        logic [31:0] core_out;
    } REQ_BUF_t;

    CACHE_STATE_t                 icache_state_q, icache_state_n;
    REQ_BUF_t                     request_buffer_q, request_buffer_n;

    logic [`CACHE_WRITE_BITS-1:0] DA_write1, DA_write2;
    logic [`CACHE_DATA_BITS -1:0] DA_in;
    logic                         DA_read;
    logic [`CACHE_DATA_BITS -1:0] DA_out1, DA_out2;
    logic [31:0]                  read_data1, read_data2;

    logic                         TA_write1, TA_write2;
    logic [`CACHE_TAG_BITS  -1:0] TA_in;
    logic                         TA_read;
    logic [`CACHE_TAG_BITS  -1:0] TA_out1, TA_out2;

    logic [`CACHE_INDEX_BITS-1:0] index, read_index;    // address to tag/data array
    logic [`CACHE_LINES     -1:0] valid1_q, valid1_n;   // valid bit of each cache line (way1)
    logic [`CACHE_LINES     -1:0] valid2_q, valid2_n;   // valid bit of each cache line (way2)
    logic [`CACHE_LINES     -1:0] replace_q, replace_n; // the way to replace
    logic                         hit1, hit2;

    // --------------------------------------------
    //               Dcache Controller             
    // --------------------------------------------
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            icache_state_q   <= IDLE;
            request_buffer_q <= REQ_BUF_t'(0);
            valid1_q         <= 32'd0;
            valid2_q         <= 32'd0;
            replace_q        <= 32'd0;
        end else begin
            icache_state_q   <= icache_state_n;
            request_buffer_q <= request_buffer_n;
            valid1_q         <= valid1_n;
            valid2_q         <= valid2_n;
            replace_q        <= replace_n;
        end
    end

    always_comb begin
        index = request_buffer_q.core_addr[`CACHE_INDEX];
        hit1  = valid1_q[index] && (TA_out1 == request_buffer_q.core_addr[`CACHE_TAG]);
        hit2  = valid2_q[index] && (TA_out2 == request_buffer_q.core_addr[`CACHE_TAG]);

        case (request_buffer_q.core_addr[`CACHE_OFFEST])
            2'b00   : {read_data1, read_data2} = {DA_out1[127:96], DA_out2[127:96]};
            2'b01   : {read_data1, read_data2} = {DA_out1[95 :64], DA_out2[95 :64]};
            2'b10   : {read_data1, read_data2} = {DA_out1[63 :32], DA_out2[63 :32]};
            2'b11   : {read_data1, read_data2} = {DA_out1[31 : 0], DA_out2[31 : 0]};
        endcase
    end

    always_comb begin
        icache_state_n   = icache_state_q;
        request_buffer_n = request_buffer_q;
        valid1_n         = valid1_q;
        valid2_n         = valid2_q;
        replace_n        = replace_q;

        // default TA / DA assignment
        read_index = index;
        TA_read    = 1'b0;
        TA_write1  = 1'b0;
        TA_write2  = 1'b0;
        TA_in      = request_buffer_q.core_addr[`CACHE_TAG];
        DA_read    = 1'b0;
        DA_write1  = 16'd0;
        DA_write2  = 16'd0;
        DA_in      = {D_out_i, 96'd0} >> ({request_buffer_q.core_count, 5'd0});

        // default dcahce request assignment
        D_req_o   = 1'b0;
        D_addr_o  = request_buffer_q.core_addr;

        // default core request assignmnet
        core_wait_o = request_buffer_q.valid | core_req_i;
        core_addr_o = request_buffer_q.core_addr;
        core_out_o  = request_buffer_q.core_out;

        unique case (icache_state_q)
            IDLE : begin
                // receive a read/write request
                if (core_req_i) begin
                    icache_state_n = READ;

                    // store request info to buffer
                    request_buffer_n = {1'b1, core_pc_i, 4'd0, 32'd0};

                    // set up tag/data array read
                    TA_read    = 1'b1;
                    DA_read    = 1'b1;
                    read_index = core_pc_i[`CACHE_INDEX];
                end
            end

            READ : begin
                // if hit -> just read out
                if (hit1 || hit2) begin
                    icache_state_n            = IDLE;
                    request_buffer_n.valid    = 1'b0;
                    request_buffer_n.core_out = (hit1) ? (read_data1) : (read_data2);
                    replace_n[index]          = (hit1) ? (1'b1) : (1'b0);

                    // send data back to core earlier
                    core_wait_o = 1'b0;
                    core_out_o  = request_buffer_n.core_out;

                    // may receive next request
                    if (core_req_i) begin
                        icache_state_n = READ;

                        // store request info to buffer
                        request_buffer_n = {1'b1, core_pc_i, 4'd0, 32'd0};

                        // set up tag/data array read
                        TA_read    = 1'b1;
                        DA_read    = 1'b1;
                        read_index = core_pc_i[`CACHE_INDEX];
                    end

                // not hit --> read allocate
                end else begin
                    // send out read request to master
                    icache_state_n = WAIT_AXI;
                    D_req_o        = 1'b1;
                    D_addr_o       = {request_buffer_q.core_addr[31:4], 4'd0};

                    // set up tag array write request
                    TA_write1        = ~replace_q[index];
                    TA_write2        =  replace_q[index];
                    valid1_n[index]  = (TA_write1) ? (1'b1) : valid1_q[index];
                    valid2_n[index]  = (TA_write2) ? (1'b1) : valid2_q[index];
                    replace_n[index] = ~replace_q[index];
                end
            end

            WAIT_AXI : begin
                // read allocate (whole cache line to wrire)
                if (D_out_valid_i) begin
                    // set up data array write request, replace_q is already updated in read state
                    // --> when replace_q is way 1 (1'b0), we need to write data in way2
                    // --> when replace_q is way 2 (1'b1), we need to write data in way1
                    if (replace_q[index] == 1'b0) begin
                        DA_write2 = 16'hf000 >> ({request_buffer_q.core_count, 2'd0});
                    end else begin
                        DA_write1 = 16'hf000 >> ({request_buffer_q.core_count, 2'd0});
                    end

                    // use core_wrire to indicate how many words we have read
                    request_buffer_n.core_count = request_buffer_q.core_count + 4'd1;
                    
                    // store the read data for core in request buffer
                    if (request_buffer_q.core_count[1:0] == request_buffer_q.core_addr[3:2]) begin
                        request_buffer_n.core_out = D_out_i;
                    end

                // the data is all writen in data array
                end else if (!D_wait_i) begin
                    icache_state_n         = IDLE;
                    request_buffer_n.valid = 1'b0;
                    core_wait_o            = 1'b0;

                    // receive next read/write request
                    if (core_req_i) begin
                        icache_state_n = READ;

                        // store request info to buffer
                        request_buffer_n = {1'b1, core_pc_i, 4'd0, 32'd0};

                        // set up tag/data array read
                        TA_read    = 1'b1;
                        DA_read    = 1'b1;
                        read_index = core_pc_i[`CACHE_INDEX];
                    end
                end
            end

            default : ; // nothing to do
        endcase
    end

    data_array_wrapper DA (
        .CK   ( clk_i      ),
        .CS   ( 1'b1       ),
        .OE   ( DA_read    ),
        .A    ( read_index ),
        .WEB1 ( DA_write1  ),
        .WEB2 ( DA_write2  ),
        .DI   ( DA_in      ),
        .DO1  ( DA_out1    ),
        .DO2  ( DA_out2    )
    );

    tag_array_wrapper TA (
        .CK   ( clk_i      ),
        .CS   ( 1'b1       ),
        .OE   ( TA_read    ),
        .A    ( read_index ),
        .DI   ( TA_in      ),
        .WEB1 ( TA_write1  ),
        .WEB2 ( TA_write2  ),
        .DO1  ( TA_out1    ),
        .DO2  ( TA_out2    )
    );

    // --------------------------------------------
    //              Performance Counts             
    // --------------------------------------------
    integer read_hit, read_miss;

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            read_hit   <= 0;
            read_miss  <= 0;
        end else begin
            if (icache_state_q == READ) begin
                if (hit1 || hit2) read_hit  <= read_hit  + 1;
                else              read_miss <= read_miss + 1;
            end
        end
    end

    final begin
        real L1CI_Hit__Rate;
        if (read_hit + read_miss > 33'd0) begin // avoid divide 0
            L1CI_Hit__Rate = (read_hit * 100.0) / (read_hit + read_miss);
        end
        else begin
            L1CI_Hit__Rate = 0.0;
        end	
        $display("Cache hit rate information:");
        $display("L1CI:");
        $display("L1CI Hit  Count = %0d", read_hit);
        $display("L1CI Miss Count = %0d", read_miss);
        $display("L1CI Hit  Rate  = %0.2f%%", L1CI_Hit__Rate);
    end

endmodule