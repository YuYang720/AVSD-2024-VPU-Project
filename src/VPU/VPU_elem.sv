module VPU_elem (
    input logic clk_i,
    input logic rst_i,

    // execute control
    input  logic               valid_i,
    input  VSLD_OP_t           velem_ctrl_i,
    input  logic [VL_BITS-1:0] vl_i,
    input  logic [VL_BITS-1:0] vl_count_i,
    output logic [VL_BITS-1:0] vl_update_o,
    input  VSEW_e              vsew_i,
    input  VLMUL_e             lmul_i,
    input  logic [4:0]         rs2_addr_i,
    input  logic [4:0]         rd_addr_i,
    output logic               done_o,

    // input operand source
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
    typedef union packed {
        logic [7:0][ 7:0] w8;
        logic [3:0][15:0] w16;
        logic [1:0][31:0] w32;
        logic      [63:0] w64;
    } elem_operand_t;

    logic [VL_BITS-1:0] left_vl_count;
    logic [VL_BITS-1:0] max_elements;
    logic [VL_BITS-1:0] handled_elements;

    elem_operand_t operand1, operand2, operand_mask;
    elem_operand_t sum_q, sum_n;
    logic          done_q, done_n;

    // --------------------------------------------
    //      Find the element count avaliable       
    // --------------------------------------------
    always_comb begin
        max_elements    = VL_BITS'(0);
        rs2_read_addr_o = 5'd0;
        left_vl_count   = vl_i - vl_count_i;


        // calculate max elements in one register based on vsew
        case (vsew_i)
            VSEW_8  : max_elements = (VL_BITS)'(VLEN / 8 );
            VSEW_16 : max_elements = (VL_BITS)'(VLEN / 16);
            VSEW_32 : max_elements = (VL_BITS)'(VLEN / 32);
            VSEW_64 : max_elements = (VL_BITS)'(VLEN / 64);
            default : ;
        endcase

        // we default can handle max element in a reg
        handled_elements = max_elements;

        if (left_vl_count < max_elements) begin
            handled_elements = left_vl_count;
        end

        vl_update_o = handled_elements;

        // send out rs2 read addr
        unique case (vsew_i)
            VSEW_8  : rs2_read_addr_o = rs2_addr_i + ((vl_count_i + handled_elements) >> 5'd3);
            VSEW_16 : rs2_read_addr_o = rs2_addr_i + ((vl_count_i + handled_elements) >> 5'd2);
            VSEW_32 : rs2_read_addr_o = rs2_addr_i + ((vl_count_i + handled_elements) >> 5'd1);
            VSEW_64 : rs2_read_addr_o = rs2_addr_i + vl_count_i + handled_elements;
            default : ;
        endcase
    end

    // --------------------------------------------
    //               Perform Adder                 
    // --------------------------------------------
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            sum_q  <= 64'd0;
            done_q <= 1'b0;
        end else begin
            sum_q  <= sum_n;
            done_q <= done_n;
        end
    end

    always_comb begin
        operand1     = rs1_val_i;
        operand_mask = 64'd0;
        sum_n        = 64'd0;

        unique case (vsew_i)
            VSEW_8 : begin
                for (int i = 0; i < 8; i++) begin
                    if (i < ({(32-VL_BITS)'(0), handled_elements})) begin
                        operand_mask.w8[i] = 8'hff;
                    end
                end
            end

            VSEW_16 : begin
                for (int i = 0; i < 4; i++) begin
                    if (i < ({(32-VL_BITS)'(0), handled_elements})) begin
                        operand_mask.w16[i] = 16'hffff;
                    end
                end
            end

            VSEW_32 : begin
                for (int i = 0; i < 2; i++) begin
                    if (i < ({(32-VL_BITS)'(0), handled_elements})) begin
                        operand_mask.w32[i] = 32'hffffffff;
                    end
                end
            end

            VSEW_64 : begin
                operand_mask.w64 = 64'hffffffffffffffff;
                /*for (int i = 0; i < 1; i++) begin
                    if (i < handled_elements) begin
                        operand_mask.w64[i] = 64'hffffffffffffffff;
                    end
                end*/
            end

            default : ;
        endcase

        operand2 = rs2_val_i & operand_mask;

        unique case (vsew_i)
            VSEW_8 : begin
                sum_n.w8[0] = operand2.w8[0] + operand2.w8[1] + operand2.w8[2] + operand2.w8[3] +
                              operand2.w8[4] + operand2.w8[5] + operand2.w8[6] + operand2.w8[7] + sum_q.w8[0];
            end

            VSEW_16 : begin
                sum_n.w16[0] = operand2.w16[0] + operand2.w16[1] + operand2.w16[2] + operand2.w16[3] + sum_q.w16[0];
            end

            VSEW_32 : begin
                sum_n.w32[0] = operand2.w32[0] + operand2.w32[1] + sum_q.w32[0];
            end

            VSEW_64 : begin
                sum_n.w64[0] = operand2.w64 + sum_q.w64;
            end

            default : ;
        endcase
    end

    always_comb begin
        result_valid_o = 1'd0;
        result_addr_o  = 5'd0;
        result_bweb_o  = (VLEN/8)'(0);
        result_data_o  = (VLEN)'(0);
        done_n         = 1'b0;
        done_o         = done_q && valid_i;

        if (valid_i && vl_count_i == vl_i) begin
            done_n = 1'b1;

            // send out wirte request
            result_valid_o = 1'b1;
            result_addr_o  = rd_addr_i;
            result_data_o  = sum_q + rs1_val_i;

            unique case (vsew_i)
                VSEW_8  : result_bweb_o = 8'b00000001;
                VSEW_16 : result_bweb_o = 8'b00000011;
                VSEW_32 : result_bweb_o = 8'b00001111;
                VSEW_64 : result_bweb_o = 8'b11111111;
                default : ;
            endcase
        end
    end

endmodule