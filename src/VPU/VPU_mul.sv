module VPU_mul (
    input  logic        clk_i,
    input  logic        rst_i,

    // mul control
    input  logic        valid_i,
    input  VMUL_OP_t    vmul_ctrl_i,
    input  VSEW_e       vsew_i,
    input  VXRM_e       vxrm_i,

    // mul operand
    input  logic [63:0] operand1_i,
    input  logic [63:0] operand2_i,
    input  logic [63:0] operand3_i,
    input  logic        mask_i,

    // mul result
    output logic        result_valid_o,
    output logic        result_en_o,
    output logic [63:0] result_o
);

    // --------------------------------------------
    //              Signal Declaration             
    // --------------------------------------------
    typedef union packed {
        logic [7:0][ 7:0] w8;
        logic [3:0][15:0] w16;
        logic [1:0][31:0] w32;
        logic      [63:0] w64;
    } mul_operand_t;

    logic [129:0] mul_130; // 65 * 65 -> 130 bit
    logic [ 65:0] mul_66;  // 33 * 33 -> 66  bit
    logic [ 33:0] mul_34;  // 17 * 17 -> 34  bit
    logic [ 17:0] mul_18;  //  9 *  9 -> 18  bit

    mul_operand_t operand1, operand2, operand3;
    logic         r8, r16, r32, r64; // rounding increment
    mul_operand_t result;            // for stage 1
    
    // pipeline register
    logic         valid_q;
    VMUL_OP_t     vmul_ctrl_q;
    VSEW_e        vsew_q;
    VXRM_e        vxrm_q;
    mul_operand_t operand3_q;
    logic         mask_q;
    logic [129:0] mul_result_q, mul_result_n;

    // --------------------------------------------
    //                Operand assign               
    // --------------------------------------------
    assign operand1 = operand1_i;
    assign operand2 = (vmul_ctrl_i.op2_is_vd) ? (operand3_i) : (operand2_i);
    assign operand3 = (vmul_ctrl_i.op2_is_vd) ? (operand2_i) : (operand3_i);

    // mul finish in two cycle (output use result in stage1)
    // if mask is write enable (masked), then the result will be invalid when mask = 0
    assign result_valid_o = valid_q;
    assign result_en_o    = ~(vmul_ctrl_q.masked && mask_q == 1'b0);
    assign result_o       = result;

    // --------------------------------------------
    //             Stage 0 : Multiplier            
    // --------------------------------------------
    always_comb begin
        mul_130 = $signed( {{vmul_ctrl_i.op2_signed & operand2[63]}, operand2.w64   } ) *
                  $signed( {{vmul_ctrl_i.op1_signed & operand1[63]}, operand1.w64   } );
        mul_66  = $signed( {{vmul_ctrl_i.op2_signed & operand2[31]}, operand2.w32[0]} ) *
                  $signed( {{vmul_ctrl_i.op1_signed & operand1[31]}, operand1.w32[0]} );
        mul_34  = $signed( {{vmul_ctrl_i.op2_signed & operand2[15]}, operand2.w16[0]} ) *
                  $signed( {{vmul_ctrl_i.op1_signed & operand1[15]}, operand1.w16[0]} );
        mul_18  = $signed( {{vmul_ctrl_i.op2_signed & operand2[ 7]}, operand2.w8 [0]} ) *
                  $signed( {{vmul_ctrl_i.op1_signed & operand1[ 7]}, operand1.w8 [0]} );

        // result mux (base on vsew)
        mul_result_n = 130'd0;

        unique case (vsew_i)
            VSEW_8  : mul_result_n = {112'd0, mul_18};
            VSEW_16 : mul_result_n = { 96'd0, mul_34};
            VSEW_32 : mul_result_n = { 64'd0, mul_66};
            VSEW_64 : mul_result_n = mul_130;
            default : ;
        endcase
    end

    // --------------------------------------------
    //    Stage 0 <-> Stage 1 Pipeline Register    
    // --------------------------------------------
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            valid_q      <= 1'b0;
            vmul_ctrl_q  <= VMUL_OP_t'(0);
            vsew_q       <= VSEW_e'(0);
            vxrm_q       <= VXRM_e'(0);
            operand3_q   <= 64'd0;
            mask_q       <= 1'b0;
            mul_result_q <= 130'd0;
        end else begin
            valid_q      <= valid_i;
            vmul_ctrl_q  <= vmul_ctrl_i;
            vsew_q       <= vsew_i;
            vxrm_q       <= vxrm_i;
            operand3_q   <= operand3;
            mask_q       <= mask_i;
            mul_result_q <= mul_result_n;
        end
    end

    // --------------------------------------------
    //        Stage 1 : Result Mux and Adder       
    // --------------------------------------------
    // find out rounding increment
    always_comb begin
        r8  = 1'b0;
        r16 = 1'b0;
        r32 = 1'b0;
        r64 = 1'b0;

        unique case (vxrm_q)
            VXRM_RNU : begin
                r8  = mul_result_q[ 6];
                r16 = mul_result_q[14];
                r32 = mul_result_q[30];
                r64 = mul_result_q[62];
            end

            VXRM_RNE : begin
                r8  = mul_result_q[ 6] & (mul_result_q[ 5:0] !=  6'd0 | mul_result_q[ 7]);
                r16 = mul_result_q[14] & (mul_result_q[13:0] != 14'd0 | mul_result_q[15]);
                r32 = mul_result_q[30] & (mul_result_q[29:0] != 30'd0 | mul_result_q[31]);
                r64 = mul_result_q[62] & (mul_result_q[61:0] != 62'd0 | mul_result_q[63]);
            end

            VXRM_RDN : begin
                r8  = 1'b0;
                r16 = 1'b0;
                r32 = 1'b0;
                r64 = 1'b0;
            end

            VXRM_ROD : begin
                r8  = mul_result_q[ 7] & (mul_result_q[ 6:0] !=  7'd0);
                r16 = mul_result_q[15] & (mul_result_q[14:0] != 15'd0);
                r32 = mul_result_q[31] & (mul_result_q[30:0] != 31'd0);
                r64 = mul_result_q[63] & (mul_result_q[62:0] != 63'd0);
            end

            default : ;
        endcase
    end


    always_comb begin
        result = 64'd0;

        unique case (vmul_ctrl_q.op)
            VMUL_VMUL : begin
                unique case (vsew_i)
                    VSEW_8  : result.w8 [0] = mul_result_q[ 7:0];
                    VSEW_16 : result.w16[0] = mul_result_q[15:0];
                    VSEW_32 : result.w32[0] = mul_result_q[31:0];
                    VSEW_64 : result.w64    = mul_result_q[63:0];
                    default : ;
                endcase
            end

            VMUL_VMULH : begin
                unique case (vsew_i)
                    VSEW_8  : result.w8 [0] = mul_result_q[ 15: 8];
                    VSEW_16 : result.w16[0] = mul_result_q[ 31:16];
                    VSEW_32 : result.w32[0] = mul_result_q[ 63:32];
                    VSEW_64 : result.w64    = mul_result_q[127:64];
                    default : ;
                endcase
            end

            VMUL_VMACC : begin
                unique case (vsew_i)
                    VSEW_8  : result.w8 [0] = (mul_result_q[ 7:0]) + operand3_q.w8 [0];
                    VSEW_16 : result.w16[0] = (mul_result_q[15:0]) + operand3_q.w16[0];
                    VSEW_32 : result.w32[0] = (mul_result_q[31:0]) + operand3_q.w32[0];
                    VSEW_64 : result.w64    = (mul_result_q[63:0]) + operand3_q.w64;
                    default : ;
                endcase
            end

            VMUL_VNMSUB : begin
                unique case (vsew_i)
                    VSEW_8  : result.w8 [0] = (-mul_result_q[ 7:0]) + operand3_q.w8 [0];
                    VSEW_16 : result.w16[0] = (-mul_result_q[15:0]) + operand3_q.w16[0];
                    VSEW_32 : result.w32[0] = (-mul_result_q[31:0]) + operand3_q.w32[0];
                    VSEW_64 : result.w64    = (-mul_result_q[63:0]) + operand3_q.w64;
                    default : ;
                endcase
            end

            VMUL_VSMUL : begin
                unique case (vsew_i)
                    VSEW_8  : result.w8 [0] = (mul_result_q[ 7:0] >>  7) + r8;
                    VSEW_16 : result.w16[0] = (mul_result_q[15:0] >> 15) + r16;
                    VSEW_32 : result.w32[0] = (mul_result_q[31:0] >> 31) + r32;
                    VSEW_64 : result.w64    = (mul_result_q[63:0] >> 63) + r64;
                    default : ;
                endcase
            end

            default : ; // nothing to do
        endcase
    end

endmodule