module VPU_lsu (
    input  logic               clk_i,
    input  logic               rst_i,

    // execute control
    input  logic               valid_i,
    input  VLSU_OP_t           mode_i,
    input  logic [VL_BITS-1:0] vl_i,
    input  logic [VL_BITS-1:0] vl_count_i,
    output logic [VL_BITS-1:0] vl_update_o,
    output logic               done_o,

    // input source
    input  logic [31:0]        base_address_i,
    input  logic [63:0]        address_offset_i,
    input  logic [31:0]        stride_i,
    input  logic [VLEN-1:0]    mask_i,
    input  logic [63:0]        store_data_i,

    // output result (register writeback)
    input  logic [4:0]         rd_addr_i,
    output logic               result_valid_o,
    output logic [4:0]         result_addr_o,
    output logic [VLEN/8-1:0]  result_bweb_o,
    output logic [VLEN-1:0]    result_data_o,

    // request to D$
    output logic               dcache_vpu_request_o,
    output logic [ 3:0]        dcache_vpu_write_o,
    output logic [31:0]        dcache_vpu_addr_o,
    output logic [31:0]        dcache_vpu_in_o,

    // response from D$
    input  logic               dcache_vpu_wait_i,
    input  logic [31:0]        dcache_vpu_out_i

);
    // --------------------------------------------
    //              Signal Declaration             
    // --------------------------------------------
    typedef enum logic [1:0] {
        IDLE, READ, WRITE
    } lsu_state_t;

    typedef struct packed {
        logic        valid;
        logic [31:0] addr;
        logic [31:0] vl_count_byte;
    } request_buffer_t;

    logic [31:0]       vl_byte, vl_count, vl_byte_left;
    lsu_state_t        lsu_state_q, lsu_state_n;
    request_buffer_t   request_buffer_q, request_buffer_n;
    
    // store signal
    logic [31:0]       store_data, align_data;
    logic [3:0]        store_bweb, store_mask;
    logic [31:0]       store_bytes, store_addr_offset;

    // load signal
    logic [63:0]       load_data;
    logic [VLEN/8-1:0] load_bweb, load_mask;
    logic [31:0]       load_bytes, load_addr_offset;
    logic [31:0]       element_byte;
    logic [31:0]       data_offset;

    // --------------------------------------------
    //                   Control                   
    // --------------------------------------------
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            lsu_state_q      <= IDLE;
            request_buffer_q <= request_buffer_t'(0);
        end else begin
            lsu_state_q      <= lsu_state_n;
            request_buffer_q <= request_buffer_n;
        end
    end

    always_comb begin
        request_buffer_n = request_buffer_q;
        lsu_state_n      = lsu_state_q;

        // default lsu output
        done_o      = 1'b0;
        vl_update_o = request_buffer_q.vl_count_byte >> mode_i.eew;;

        // default dcache request
        dcache_vpu_request_o = 1'b0;
        dcache_vpu_addr_o    = 32'd0;
        dcache_vpu_write_o   = 4'b0000;
        dcache_vpu_in_o      = 32'd0;

        // default vreg writebakc
        result_valid_o = 1'b0;
        result_addr_o  = 5'd0;
        result_bweb_o  = (VLEN/8)'(0);
        result_data_o  = (VLEN)'(0);

        unique case (lsu_state_q)
            // receive new request
            IDLE : begin
                if (valid_i) begin
                    request_buffer_n.valid         = 1'b1;
                    request_buffer_n.addr          = base_address_i;
                    request_buffer_n.vl_count_byte = 32'd0;
                    lsu_state_n                    = (mode_i.store) ? (WRITE) : (READ);

                    if (mode_i.store) begin
                        // send out request to D$
                        dcache_vpu_request_o = 1'b1;
                        dcache_vpu_addr_o    = base_address_i;
                        dcache_vpu_write_o   = store_bweb;
                        dcache_vpu_in_o      = align_data;

                        // update request buffer
                        // we can save whole 64 bit at one time for stride mode
                        // so we need to seperate to 2 store
                        // when 2 store finish(8 bytes is stored), then we can update next base address
                        if (mode_i.stride == VLSU_STRIDED && mode_i.eew == VSEW_64) begin
                            request_buffer_n.addr = base_address_i;
                        end else begin
                            request_buffer_n.addr = base_address_i + store_addr_offset;
                        end

                        // update request buffer
                        request_buffer_n.vl_count_byte = store_bytes;
                        vl_update_o                    = request_buffer_n.vl_count_byte >> mode_i.eew;

                    end else begin
                        // send out request to D$
                        dcache_vpu_request_o = 1'b1;
                        dcache_vpu_addr_o    = base_address_i;

                        // update request buffer
                        if (mode_i.stride == VLSU_STRIDED && mode_i.eew == VSEW_64) begin
                            request_buffer_n.addr = base_address_i;
                        end else begin
                            request_buffer_n.addr = base_address_i + load_addr_offset;
                        end
                    end
                end
            end

            READ : begin
                if (!dcache_vpu_wait_i) begin
                    // send out request to D$
                    dcache_vpu_request_o = 1'b1;
                    dcache_vpu_addr_o    = request_buffer_q.addr;

                    // update request buffer
                    request_buffer_n.addr          = request_buffer_q.addr + load_addr_offset;
                    request_buffer_n.vl_count_byte = request_buffer_q.vl_count_byte + load_bytes;
                    vl_update_o                    = request_buffer_n.vl_count_byte >> mode_i.eew;

                    // send out register writeback
                    result_valid_o = 1'b1;
                    result_addr_o  = rd_addr_i + (request_buffer_q.vl_count_byte >> 3);
                    result_bweb_o  = load_bweb;
                    result_data_o  = load_data;

                    if (request_buffer_n.vl_count_byte >= vl_byte) begin
                        dcache_vpu_request_o   = 1'b0;
                    end
                end

                if (request_buffer_q.vl_count_byte >= vl_byte) begin
                    lsu_state_n            = IDLE;
                    dcache_vpu_request_o   = 1'b0;
                    request_buffer_n.valid = 1'b0;
                    result_valid_o         = 1'b0;
                    done_o                 = 1'b1;
                end
            end

            WRITE : begin
                if (~dcache_vpu_wait_i) begin
                    // send out request to D$
                    dcache_vpu_request_o = 1'b1;
                    dcache_vpu_addr_o    = request_buffer_q.addr;
                    dcache_vpu_write_o   = store_bweb;
                    dcache_vpu_in_o      = align_data;

                    // update request buffer
                    request_buffer_n.vl_count_byte = request_buffer_q.vl_count_byte + store_bytes;
                    vl_update_o                    = request_buffer_n.vl_count_byte >> mode_i.eew;

                    // update request buffer
                    // we can save whole 64 bit at one time for stride mode
                    // so we need to seperate to 2 store
                    // when 2 store finish(8 bytes is stored), then we can update next base address
                    if (mode_i.stride == VLSU_STRIDED && mode_i.eew == VSEW_64) begin
                        dcache_vpu_addr_o     = request_buffer_q.addr + store_bytes;
                        request_buffer_n.addr = request_buffer_q.addr;

                        if (request_buffer_q.vl_count_byte[2:0] == 3'd0) begin
                            dcache_vpu_addr_o = request_buffer_q.addr;
                        end

                        if (request_buffer_n.vl_count_byte[2:0] == 3'd0) begin
                            request_buffer_n.addr = request_buffer_q.addr + store_addr_offset;
                        end

                    end else begin
                        request_buffer_n.addr = request_buffer_q.addr + store_addr_offset;
                    end

                    if (request_buffer_q.vl_count_byte >= vl_byte) begin
                        lsu_state_n            = IDLE;
                        dcache_vpu_request_o   = 1'b0;
                        request_buffer_n.valid = 1'b0;
                        done_o                 = 1'b1;
                    end
                end
            end

            default : lsu_state_n = IDLE;
        endcase
    end

    // --------------------------------------------
    //       Calculate the bytes to operate        
    // --------------------------------------------
    always_comb begin
        // the total bytes to store (vl_i * eew)
        vl_byte  = {(32-VL_BITS)'(0), vl_i} << mode_i.eew;

        // the byte left
        if (lsu_state_q == IDLE && valid_i) begin
            vl_byte_left = vl_byte;
        end else begin
            vl_byte_left = vl_byte - request_buffer_q.vl_count_byte;
        end
    end

    // --------------------------------------------
    //             Generate read data             
    // --------------------------------------------
    always_comb begin
        load_bytes  = (vl_byte_left < 32'd4) ? (vl_byte_left) : (32'd4);
        load_mask   = 8'b00001111; // we can only writeback 4 bytes in a time
        load_bweb   = (VLEN/8)'(0);
        load_data   = (VLEN)'(0);
        data_offset = 32'd0;

        if (mode_i.stride == VLSU_STRIDED) begin
            unique case (mode_i.eew)
                VSEW_8  : load_bytes = 32'd1;
                VSEW_16 : load_bytes = 32'd2;
                VSEW_32 : load_bytes = 32'd4;
                default : ; // nothing to do
            endcase

            unique case (mode_i.eew)
                VSEW_8  : load_mask = 8'b00000001;
                VSEW_16 : load_mask = 8'b00000011;
                VSEW_32 : load_mask = 8'b00001111;
                default : ; // nothing to do
            endcase
        end

        // we can handle 4 bytes at one time for UNITSTRIDE
        if (mode_i.stride == VLSU_UNITSTRIDE) begin
            unique case (vl_byte_left)
                32'd1   : load_mask = 8'b00000001;
                32'd2   : load_mask = 8'b00000011;
                32'd3   : load_mask = 8'b00000111;
                default : ; // nothing to do
            endcase
        end

        data_offset = {29'd0, request_buffer_q.vl_count_byte[2:0]} << 3'd3;

        // if we have writeback 4 bytes, then mask should shift 4 bits for higer bits (register[63:32])
        if (lsu_state_q == READ && mode_i.stride == VLSU_UNITSTRIDE) begin
            load_bweb  = load_mask        << ((request_buffer_q.vl_count_byte[2]) ? (3'd4 ) : (3'd0));
            load_data  = ({32'd0, dcache_vpu_out_i} << ((request_buffer_q.vl_count_byte[2]) ? (6'd32) : (6'd0)));
        // if stirde --> load bweb is base on element index
        end else if (lsu_state_q == READ && mode_i.stride == VLSU_STRIDED) begin
            load_bweb  = load_mask        << request_buffer_q.vl_count_byte[2:0];
            load_data  = ({32'd0, dcache_vpu_out_i} << data_offset);
        end
    end

    always_comb begin
        load_addr_offset = 32'd0;
    
        unique case (mode_i.stride)
            VLSU_UNITSTRIDE : load_addr_offset = 32'd4;                    // keep reading 4 byte
            VLSU_STRIDED    : load_addr_offset = (stride_i << mode_i.eew); // i * stride_i * eew(byte)
            VLSU_INDEXED    : ;
            default : ; // nothing to do
        endcase
    end

    // --------------------------------------------
    //             Generate write data             
    // --------------------------------------------
    always_comb begin
        store_mask = 4'b1111;
        store_bweb = 4'd0;
        store_data = 32'd0;
        align_data = 32'd0;

        // we can handle 4 bytes at one time for UNITSTRIDE
        if (mode_i.stride == VLSU_UNITSTRIDE) begin
            unique case (vl_byte_left)
                32'd1   : store_mask = 4'b0001;
                32'd2   : store_mask = 4'b0011;
                32'd3   : store_mask = 4'b0111;
                default : ; // nothing to do
            endcase
        end else if (mode_i.stride == VLSU_STRIDED) begin
            // in STRIDE mode, we can only handle one element one time
            // when eew = 8  --> store_mask = 4'b1
            // when eew = 16 --> store_mask = 4'b11
            // when eew = 32 --> store_mask = 4'b1111
            // when eew = 64 --> store_mask = 4'b1111 (only can sotre half)
            unique case (mode_i.eew)
                VSEW_8  : store_mask = 4'b0001;
                VSEW_16 : store_mask = 4'b0011;
                VSEW_32 : store_mask = 4'b1111;
                VSEW_64 : store_mask = 4'b1111;
                default : ; // nothing to do
            endcase
        end

        // the data for first write
        if (lsu_state_q == IDLE && valid_i) begin
            store_bweb = store_mask << base_address_i[1:0];
            store_data = store_data_i[31:0];
            align_data = store_data << ( {30'd0, base_address_i[1:0]} << 32'd3 );
        end

        if (lsu_state_q == WRITE) begin
            store_bweb = store_mask << request_buffer_q.addr[1:0];
            store_data = (request_buffer_q.vl_count_byte[2]) ? (store_data_i[63:32]) : (store_data_i[31:0]);
            align_data = store_data << ( {30'd0, request_buffer_q.addr[1:0]} << 32'd3 );
        end
    end

    always_comb begin
        store_bytes       = 32'd0;
        store_addr_offset = 32'd0;

        // calculate how many bytes we store in this request
        unique case (store_bweb)
            4'b1111 : store_bytes = 32'd4;
            4'b0111 : store_bytes = 32'd3;
            4'b0011 : store_bytes = 32'd2;
            4'b0001 : store_bytes = 32'd1;
            default : store_bytes = 32'd0;
        endcase

        unique case (mode_i.stride)
            VLSU_UNITSTRIDE : store_addr_offset = store_bytes;
            VLSU_STRIDED    : store_addr_offset = (stride_i << mode_i.eew); // i * stride_i * eew(byte)
            VLSU_INDEXED    : ;
            default : ; // nothing to do
        endcase
    end

endmodule