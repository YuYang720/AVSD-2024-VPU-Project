module VPU_sld (
    input  logic clk_i,
    input  logic rst_i,

    // execute control
    input  logic               valid_i,
    input  VSLD_OP_t           vsld_ctrl_i,
    input  logic [VL_BITS-1:0] vl_i,
    input  logic [VL_BITS-1:0] vl_count_i,
    output logic [VL_BITS-1:0] vl_update_o,
    input  VSEW_e              vsew_i,
    input  VLMUL_e             lmul_i,
    input  logic [4:0]         rs2_addr_i,
    input  logic [4:0]         rd_addr_i,
    output logic               done_o,

    // input operand source
    input  logic [VL_BITS-1:0] offset_i,
    input  logic [VLEN-1:0]    rs1_val_i,
    input  logic [VLEN-1:0]    rs2_val_i,
    output logic [4:0]         rs2_read_addr_o,

    // output result
    output logic               result_valid_o,
    output logic [4:0]         result_addr_o,
    output logic [VLEN/8-1:0]  result_bweb_o,
    output logic [VLEN-1:0]    result_data_o
);

    // --------------------------------------------
    //              Signal Declaration             
    // --------------------------------------------
    logic [VL_BITS-1:0] offset;
    logic [VL_BITS-1:0] max_elements;
    logic [VL_BITS-1:0] handled_elements;
    logic [VL_BITS-1:0] total_left_elements;

    logic [VL_BITS-1:0] vl_max;
    logic [63:0]        data_offset;
    logic [63:0]        rd_align;

    logic [VL_BITS-1:0] source_index;
    logic [63:0]        source_data;

    logic               rs2_data_valid;
    logic               rs2_data_read;
    logic [VL_BITS-1:0] rs2_element_index;
    logic [VL_BITS-1:0] rs2_left_elements;

    logic [4:0]         rd_write_addr;
    logic [VL_BITS-1:0] rd_element_index;
    logic [VL_BITS-1:0] rd_left_elements;

    // Pipeline register
    logic [VL_BITS-1:0] vl_count_q;
    logic [VL_BITS-1:0] rs2_element_index_q;
    logic [VL_BITS-1:0] rd_element_index_q;
    logic [VL_BITS-1:0] source_index_q;
    logic [VL_BITS-1:0] handled_elements_q;

    // --------------------------------------------
    //       Read rs data base on i + offset       
    // --------------------------------------------
    always_ff @(posedge clk_i) begin
        if      (rst_i)  rs2_data_valid <= 1'b0;
        else if (done_o) rs2_data_valid <= 1'b0;
        else             rs2_data_valid <= rs2_data_read;
    end

    // calculate source index based on direction
    // and set up register read
    always_comb begin
        source_index    = VL_BITS'(0);
        rs2_read_addr_o = 5'd0;
        rs2_data_read   = 1'b0;
        offset          = VL_BITS'(0);

        if (valid_i) begin
            offset = (vsld_ctrl_i.slide1) ? (VL_BITS'(1)) : (offset_i);

            if (vsld_ctrl_i.dir == VSLD_DOWN) begin
                source_index = vl_count_i + offset;
            end else begin
                source_index = vl_count_i - offset;
            end

            // set up reg read (for later use)
            rs2_data_read = 1'b1;

            // slide up
            if (vsld_ctrl_i.dir == VSLD_UP && vl_count_i < offset) begin
                rs2_data_read = 1'b0;
            end
        end

        unique case (vsew_i)
            VSEW_8  : rs2_read_addr_o = rs2_addr_i + (source_index >> 5'd3);
            VSEW_16 : rs2_read_addr_o = rs2_addr_i + (source_index >> 5'd2);
            VSEW_32 : rs2_read_addr_o = rs2_addr_i + (source_index >> 5'd1);
            VSEW_64 : rs2_read_addr_o = rs2_addr_i + source_index;
            default : ;
        endcase
    end

    // --------------------------------------------
    //             Write Data Generate             
    // --------------------------------------------
    always_comb begin
        // processed_elements  = VL_BITS'(0);
        vl_update_o       = VL_BITS'(0);
        max_elements      = VL_BITS'(0);
        handled_elements  = VL_BITS'(0);
        rs2_element_index = VL_BITS'(0);
        rd_element_index  = VL_BITS'(0);

        // calculate max elements in one register based on vsew
        case (vsew_i)
            VSEW_8  : max_elements = (VL_BITS)'(VLEN / 8 );
            VSEW_16 : max_elements = (VL_BITS)'(VLEN / 16);
            VSEW_32 : max_elements = (VL_BITS)'(VLEN / 32);
            VSEW_64 : max_elements = (VL_BITS)'(VLEN / 64);
            default : ;
        endcase

        vl_max = max_elements << (lmul_i);

        // get the element count in the register
        // i.e. source_index = 5 is element 1 in rs+1 when eew = 16
        case (vsew_i)
            VSEW_8  : rs2_element_index = {(VL_BITS-3)'(0), source_index[2:0]};
            VSEW_16 : rs2_element_index = {(VL_BITS-2)'(0), source_index[1:0]};
            VSEW_32 : rs2_element_index = {(VL_BITS-1)'(0), source_index[0]  };
            VSEW_64 : rs2_element_index = VL_BITS'(0);
            default : ;
        endcase

        case (vsew_i)
            VSEW_8  : rd_element_index = {(VL_BITS-3)'(0), vl_count_i[2:0]};
            VSEW_16 : rd_element_index = {(VL_BITS-2)'(0), vl_count_i[1:0]};
            VSEW_32 : rd_element_index = {(VL_BITS-1)'(0), vl_count_i[0]  };
            VSEW_64 : rd_element_index = VL_BITS'(0);
            default : ;
        endcase

        // calculate number of elements that can be processed
        rs2_left_elements   = max_elements - rs2_element_index;
        rd_left_elements    = max_elements - rd_element_index;
        total_left_elements = vl_i - vl_count_i;

        // the element count to run is min (rs2, rd, total left)
        if (rs2_left_elements   <= rd_left_elements ) handled_elements = rs2_left_elements;
        if (rd_left_elements    <= rs2_left_elements) handled_elements = rd_left_elements;
        if (total_left_elements <= handled_elements ) handled_elements = total_left_elements;

        vl_update_o = handled_elements;

        // slide up
        if (vsld_ctrl_i.dir == VSLD_UP && vl_count_i < offset) begin
            vl_update_o = offset;
        end
    end

    // --------------------------------------------
    //        Stage 2 : Write Data Generate        
    // --------------------------------------------
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            vl_count_q          <= VL_BITS'(0);
            rs2_element_index_q <= VL_BITS'(0);
            rd_element_index_q  <= VL_BITS'(0);
            source_index_q      <= VL_BITS'(0);
            handled_elements_q  <= VL_BITS'(0);
        end else begin
            vl_count_q          <= vl_count_i;
            rs2_element_index_q <= rs2_element_index;
            rd_element_index_q  <= rd_element_index;
            source_index_q      <= source_index;
            handled_elements_q  <= handled_elements;
        end
    end

    always_comb begin
        done_o        = valid_i && rs2_data_valid && (vl_count_q >= vl_i);
        rd_write_addr = 5'd0;
        source_data   = 64'd0;
        data_offset   = 64'd0;
        rd_align      = 64'd0;

        unique case (vsew_i)
            VSEW_8  : rd_write_addr = rd_addr_i + (vl_count_q >> 5'd3);
            VSEW_16 : rd_write_addr = rd_addr_i + (vl_count_q >> 5'd2);
            VSEW_32 : rd_write_addr = rd_addr_i + (vl_count_q >> 5'd1);
            VSEW_64 : rd_write_addr = rd_addr_i + (vl_count_q);
            default : ;
        endcase

        unique case (vsew_i)
            VSEW_8  : data_offset = ({(64-VL_BITS)'(0), rs2_element_index_q}) << 5'd3;
            VSEW_16 : data_offset = ({(64-VL_BITS)'(0), rs2_element_index_q}) << 5'd4;
            VSEW_32 : data_offset = ({(64-VL_BITS)'(0), rs2_element_index_q}) << 5'd5;
            VSEW_64 : data_offset = ({(64-VL_BITS)'(0), rs2_element_index_q}) << 5'd6;
            default : ;
        endcase

        unique case (vsew_i)
            VSEW_8  : rd_align = ({(64-VL_BITS)'(0), rd_element_index_q}) << 5'd3;
            VSEW_16 : rd_align = ({(64-VL_BITS)'(0), rd_element_index_q}) << 5'd4;
            VSEW_32 : rd_align = ({(64-VL_BITS)'(0), rd_element_index_q}) << 5'd5;
            VSEW_64 : rd_align = ({(64-VL_BITS)'(0), rd_element_index_q}) << 5'd6;
            default : ;
        endcase

        if (source_index_q >= vl_max) source_data = 64'd0;
        else                          source_data = (rs2_val_i >> data_offset) << (rd_align);

        result_valid_o = rs2_data_valid && !done_o;
        result_addr_o  = rd_write_addr;
        result_bweb_o  = (VLEN/8)'(0);
        result_data_o  = source_data;

        unique case (vsew_i)
            VSEW_8 : begin
                for (int i = 0; i < 8; i++) begin
                    if (({(32-VL_BITS)'(0), rd_element_index_q}) <= i && i < ({(32-VL_BITS)'(0), rd_element_index_q}) + ({(32-VL_BITS)'(0), handled_elements_q})) begin
                        result_bweb_o[i] = 1'b1;

                        if (vsld_ctrl_i.slide1 && vsld_ctrl_i.dir == VSLD_DOWN && ({(32-VL_BITS)'(0), vl_count_q} + i == {(32-VL_BITS)'(0), vl_i})) begin
                            result_data_o[i*8 +: 8] = rs1_val_i[7:0];
                        end
                    end
                end

                if (vsld_ctrl_i.slide1 && vsld_ctrl_i.dir == VSLD_UP && vl_count_i == VL_BITS'(1)) begin
                    result_valid_o     = 1'b1;
                    result_addr_o      = rd_addr_i;
                    result_bweb_o[0]   = 1'b1;
                    result_data_o[7:0] = rs1_val_i[7:0];
                end
            end

            VSEW_16 : begin
                for (int i = 0; i < 4; i++) begin
                    if (({(32-VL_BITS)'(0), rd_element_index_q}) <= i && i < ({(32-VL_BITS)'(0), rd_element_index_q}) + ({(32-VL_BITS)'(0), handled_elements_q})) begin
                        result_bweb_o[i*2 +:2]  = 2'b11;

                        if (vsld_ctrl_i.slide1 && vsld_ctrl_i.dir == VSLD_DOWN && ({(32-VL_BITS)'(0), vl_count_q} + i == {(32-VL_BITS)'(0), vl_i})) begin
                            result_data_o[i*16 +: 16] = rs1_val_i[15:0];
                        end
                    end
                end

                if (vsld_ctrl_i.slide1 && vsld_ctrl_i.dir == VSLD_UP && vl_count_i == VL_BITS'(1)) begin
                    result_valid_o      = 1'b1;
                    result_addr_o       = rd_addr_i;
                    result_bweb_o[ 1:0] = 2'b11;
                    result_data_o[15:0] = rs1_val_i[15:0];
                end
            end

            VSEW_32 : begin
                for (int i = 0; i < 2; i++) begin
                    if (({(32-VL_BITS)'(0), rd_element_index_q}) <= i && i < ({(32-VL_BITS)'(0), rd_element_index_q}) + ({(32-VL_BITS)'(0), handled_elements_q})) begin
                        result_bweb_o[i*4 +:4]  = 4'b1111;

                        if (vsld_ctrl_i.slide1 && vsld_ctrl_i.dir == VSLD_DOWN && ({(32-VL_BITS)'(0), vl_count_q} + i == {(32-VL_BITS)'(0), vl_i})) begin
                            result_data_o[i*32 +: 32] = rs1_val_i[31:0];
                        end
                    end
                end

                if (vsld_ctrl_i.slide1 && vsld_ctrl_i.dir == VSLD_UP && vl_count_i == VL_BITS'(1)) begin
                    result_valid_o      = 1'b1;
                    result_addr_o       = rd_addr_i;
                    result_bweb_o[ 3:0] = 4'b1111;
                    result_data_o[31:0] = rs1_val_i[31:0];
                end
            end

            VSEW_64 : begin
                for (int i = 0; i < 1; i++) begin
                    if (({(32-VL_BITS)'(0), rd_element_index_q}) <= i && i < ({(32-VL_BITS)'(0), rd_element_index_q}) + ({(32-VL_BITS)'(0), handled_elements_q})) begin
                        result_bweb_o[i*8 +:8] = 8'b11111111;

                        if (vsld_ctrl_i.slide1 && vsld_ctrl_i.dir == VSLD_DOWN && ({(32-VL_BITS)'(0), vl_count_q} + i == {(32-VL_BITS)'(0), vl_i})) begin
                            result_data_o[i*64 +: 64] = rs1_val_i[63:0];
                        end
                    end
                end

                if (vsld_ctrl_i.slide1 && vsld_ctrl_i.dir == VSLD_UP && vl_count_q == VL_BITS'(1)) begin
                    result_valid_o      = 1'b1;
                    result_addr_o       = rd_addr_i;
                    result_bweb_o[ 7:0] = 8'b11111111;
                    result_data_o[63:0] = rs1_val_i[63:0];
                end
            end

            default : ; // nothing to do
        endcase
    end

endmodule