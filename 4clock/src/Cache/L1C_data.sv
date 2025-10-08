module L1C_data (
    input  logic        clk_i,
    input  logic        rst_i,

    // core <-> D$
    input  logic        core_req_i,
    input  logic [ 3:0] core_write_i,
    input  logic [31:0] core_addr_i,
    input  logic [31:0] core_in_i,
    output logic        core_wait_o,
    output logic [31:0] core_out_o,

    input  logic        vpu_request_i,
    input  logic [ 3:0] vpu_write_i,
    input  logic [31:0] vpu_addr_i,
    input  logic [31:0] vpu_in_i,
    output logic        vpu_wait_o,
    output logic [31:0] vpu_out_o,

    // D$ <-> master1
    output logic        D_req_o,
    output logic [ 3:0] D_write_o,
    output logic [31:0] D_addr_o,
    output logic [31:0] D_in_o,
    input  logic        D_wait_i,
    input  logic        D_out_valid_i,
    input  logic [31:0] D_out_i
);

    // --------------------------------------------
    //              Signal Declaration             
    // --------------------------------------------
    typedef enum logic [2:0] {
        IDLE,       // accept a read/write request from core
        READ,       // read the data from cache line
        WRITE,      // write the data from core to cache line
        WAIT_AXI    // wait for axi transfer
    } CACHE_STATE_t;

    typedef struct packed {
        logic        valid;
        logic        is_vpu;
        logic [31:0] core_addr;
        logic [ 3:0] core_write;
        logic [31:0] core_in;
    } REQ_BUF_t;

    CACHE_STATE_t                 dcache_state_q, dcache_state_n;
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
            dcache_state_q   <= IDLE;
            request_buffer_q <= REQ_BUF_t'(0);
            valid1_q         <= 32'd0;
            valid2_q         <= 32'd0;
            replace_q        <= 32'd0;
        end else begin
            dcache_state_q   <= dcache_state_n;
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
            2'b00 : {read_data1, read_data2} = {DA_out1[127:96], DA_out2[127:96]};
            2'b01 : {read_data1, read_data2} = {DA_out1[95 :64], DA_out2[95 :64]};
            2'b10 : {read_data1, read_data2} = {DA_out1[63 :32], DA_out2[63 :32]};
            2'b11 : {read_data1, read_data2} = {DA_out1[31 : 0], DA_out2[31 : 0]};
        endcase
    end

    always_comb begin
        dcache_state_n   = dcache_state_q;
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
        DA_in      = {D_out_i, 96'd0} >> ({request_buffer_q.core_write, 5'd0});

        // default dcahce request assignment
        D_req_o   = 1'b0;
        D_write_o = request_buffer_q.core_write;
        D_addr_o  = request_buffer_q.core_addr;
        D_in_o    = request_buffer_q.core_in;

        // default core request assignmnet
        core_wait_o = (request_buffer_q.valid && ~request_buffer_q.is_vpu) | core_req_i;
        core_out_o  = request_buffer_q.core_in;

        // default vpu request assignmnet
        vpu_wait_o = (request_buffer_q.valid && request_buffer_q.is_vpu) | vpu_request_i;
        vpu_out_o  = request_buffer_q.core_in;

        unique case (dcache_state_q)
            IDLE : begin
                // receive a read/write request
                if (core_req_i) begin
                    // if core wirte != 0 -> read request
                    dcache_state_n = (|core_write_i) ? (WRITE) : (READ);

                    // store request info to buffer
                    request_buffer_n = {1'b1, 1'b0, core_addr_i, core_write_i, core_in_i};

                    // set up tag/data array read
                    TA_read    = 1'b1;
                    DA_read    = 1'b1;
                    read_index = core_addr_i[`CACHE_INDEX];

                // receive vpu request
                end else if (vpu_request_i) begin
                    // if core wirte != 0 -> read request
                    dcache_state_n = (|vpu_write_i) ? (WRITE) : (READ);

                    // store request info to buffer
                    request_buffer_n = {1'b1, 1'b1, vpu_addr_i, vpu_write_i, vpu_in_i};

                    // set up tag/data array read
                    TA_read    = 1'b1;
                    DA_read    = 1'b1;
                    read_index = vpu_addr_i[`CACHE_INDEX];
                end
            end

            READ : begin
                // if hit -> just read out
                if (hit1 || hit2) begin
                    dcache_state_n           = IDLE;
                    request_buffer_n.valid   = 1'b0;
                    request_buffer_n.core_in = (hit1) ? (read_data1) : (read_data2);
                    replace_n[index]         = (hit1) ? (1'b1) : (1'b0);

                    // send data back to core earlier
                    if (request_buffer_q.is_vpu) begin
                        vpu_wait_o  = 1'b0;
                        vpu_out_o   = request_buffer_n.core_in;
                    end else begin
                        core_wait_o = 1'b0;
                        core_out_o  = request_buffer_n.core_in;
                    end

                    // may receive next request
                    if (core_req_i) begin
                        // if core wirte != 0 -> read request
                        dcache_state_n = (|core_write_i) ? (WRITE) : (READ);

                        // store request info to buffer
                        request_buffer_n = {1'b1, 1'b0, core_addr_i, core_write_i, core_in_i};

                        // set up tag/data array read
                        TA_read    = 1'b1;
                        DA_read    = 1'b1;
                        read_index = core_addr_i[`CACHE_INDEX];

                     // receive vpu request
                    end else if (vpu_request_i) begin
                        // if core wirte != 0 -> read request
                        dcache_state_n = (|vpu_write_i) ? (WRITE) : (READ);

                        // store request info to buffer
                        request_buffer_n = {1'b1, 1'b1, vpu_addr_i, vpu_write_i, vpu_in_i};

                        // set up tag/data array read
                        TA_read    = 1'b1;
                        DA_read    = 1'b1;
                        read_index = vpu_addr_i[`CACHE_INDEX];
                    end

                // not hit --> read allocate
                end else begin
                    // send out read request to master
                    dcache_state_n = WAIT_AXI;
                    D_req_o        = 1'b1;
                    D_addr_o       = {request_buffer_q.core_addr[31:4], 4'd0};

                    // set up tag array write request
                    TA_write1        = ~replace_q[index];
                    TA_write2        =  replace_q[index];
                    valid1_n[index]  = (TA_write1) ? (1'b1) : valid1_q[index];
                    valid2_n[index]  = (TA_write2) ? (1'b1) : valid2_q[index];
                    replace_n[index] = (TA_write1) ? (1'b1) : (1'b0);
                end
            end

            WRITE : begin
                // if hit -> write through
                if (hit1 || hit2) begin
                    // set up data array write request
                    if (hit1) DA_write1 = {request_buffer_q.core_write, 12'd0} >> ({request_buffer_q.core_addr[`CACHE_OFFEST], 2'd0});
                    else      DA_write2 = {request_buffer_q.core_write, 12'd0} >> ({request_buffer_q.core_addr[`CACHE_OFFEST], 2'd0});

                    DA_in = {request_buffer_q.core_in, 96'd0} >> ({request_buffer_q.core_addr[`CACHE_OFFEST], 5'd0});

                    // update lru
                    replace_n[index] = (hit1) ? (1'b1) : (1'b0);
                end

                // send out write request to memory
                D_req_o        = 1'b1;
                dcache_state_n = WAIT_AXI;
            end

            WAIT_AXI : begin
                // read allocate (whole cache line to wrire)
                if (D_out_valid_i) begin
                    // set up data array write request, replace_q is already updated in read state
                    // --> when replace_q is way 1 (1'b0), we need to write data in way2
                    // --> when replace_q is way 2 (1'b1), we need to write data in way1
                    if (replace_q[index] == 1'b0) begin
                        DA_write2 = 16'hf000 >> ({request_buffer_q.core_write, 2'd0});
                    end else begin
                        DA_write1 = 16'hf000 >> ({request_buffer_q.core_write, 2'd0});
                    end

                    // use core_wrire to indicate how many words we have read
                    request_buffer_n.core_write = request_buffer_q.core_write + 4'd1;

                    // store the read data for core in request buffer
                    if (request_buffer_q.core_write[1:0] == request_buffer_q.core_addr[3:2]) begin
                        request_buffer_n.core_in = D_out_i;
                    end

                // the data is all writen in data array
                // or write through is finish
                end else if (!D_wait_i) begin
                    dcache_state_n         = IDLE;
                    request_buffer_n.valid = 1'b0;
                    
                    if (request_buffer_q.is_vpu) begin
                        vpu_wait_o  = 1'b0;
                    end else begin
                        core_wait_o = 1'b0;
                    end

                    // receive next read/write request
                    if (core_req_i) begin
                        // if core_wirte != 0 -> read request
                        dcache_state_n = (|core_write_i) ? (WRITE) : (READ);

                        // store request info to buffer
                        request_buffer_n = {1'b1, 1'b0, core_addr_i, core_write_i, core_in_i};

                        // set up tag/data array read
                        TA_read    = 1'b1;
                        DA_read    = 1'b1;
                        read_index = core_addr_i[`CACHE_INDEX];

                    // receive vpu request
                    end else if (vpu_request_i) begin
                        // if core wirte != 0 -> read request
                        dcache_state_n = (|vpu_write_i) ? (WRITE) : (READ);

                        // store request info to buffer
                        request_buffer_n = {1'b1, 1'b1, vpu_addr_i, vpu_write_i, vpu_in_i};

                        // set up tag/data array read
                        TA_read    = 1'b1;
                        DA_read    = 1'b1;
                        read_index = vpu_addr_i[`CACHE_INDEX];
                    end
                end
            end

            default : dcache_state_n = IDLE;
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
    integer write_hit, write_miss;

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            read_hit   <= 0;
            read_miss  <= 0;
            write_hit  <= 0;
            write_miss <= 0;
        end else begin
            if (dcache_state_q == READ) begin
                if (hit1 || hit2) read_hit  <= read_hit  + 1;
                else              read_miss <= read_miss + 1;
            end

            if (dcache_state_q == WRITE) begin
                if (hit1 || hit2) write_hit  <= write_hit  + 1;
                else              write_miss <= write_miss + 1;
            end
        end
    end

	final begin
		real L1CD_Hit__Rate,L1CD_Hit__Rate_R,L1CD_Hit__Rate_W;
		if ((read_hit + read_miss > 33'd0) && (write_hit + write_miss > 33'd0)) begin // avoid divide 0
			// Total
			L1CD_Hit__Rate = ( (read_hit + write_hit) * 100.0) / ((read_hit +write_hit) + (read_miss + write_miss));
			// Read
			L1CD_Hit__Rate_R = (read_hit * 100.0) / (read_hit + read_miss);
			// Write
			L1CD_Hit__Rate_W = (write_hit * 100.0) / (write_hit + write_miss);
		end
		else begin
			// Total
			L1CD_Hit__Rate = 0.0;
			// Read
			L1CD_Hit__Rate_R = 0.0;
			// Write
			L1CD_Hit__Rate_W = 0.0;
		end		
		$display("L1CD:");
		// Read
		$display("READ:");
		$display("READ  L1CD Hit  Count = %0d", read_hit);
		$display("READ  L1CD Miss Count = %0d", read_miss);
		$display("READ  L1CD Hit  Rate  = %0.2f%%", L1CD_Hit__Rate_R);
		// Write
		$display("WRITE:");
		$display("WRITE L1CD Hit  Count = %0d", write_hit);
		$display("WRITE L1CD Miss Count = %0d", write_miss);
		$display("WRITE L1CD Hit  Rate  = %0.2f%%", L1CD_Hit__Rate_W);
		// Total
		$display("TOTAL:");
		$display("TOTAL L1CD Hit  Count = %0d", (read_hit +  write_hit ));
		$display("TOTAL L1CD Miss Count = %0d", (read_miss + write_miss));
		$display("TOTAL L1CD Hit  Rate  = %0.2f%%", L1CD_Hit__Rate);
	end

endmodule