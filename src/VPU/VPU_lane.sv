module VPU_lane (
    input  logic clk_i,
    input  logic rst_i,

    // unit to execute
    input  logic            valid_i,
    input  VPU_FU_t         fu_i,
    input  VPU_MODE_t       mode_i,
    input  VSEW_e           vsew_i,
    input  VXRM_e           vxrm_i,

    // input operands
    input  logic [63:0]     operand1_i,
    input  logic [63:0]     operand2_i,
    input  logic [63:0]     operand3_i,
    input  logic            mask_i,

    // result
    output logic            result_valid_o,
    output logic            result_en_o,
    output logic [63:0]     result_o
);

    // --------------------------------------------
    //              Signal Declaration             
    // --------------------------------------------
    logic        valu_valid, valu_result_valid, valu_result_en;
    logic        vmul_valid, vmul_result_valid, vmul_result_en;
    logic [63:0] valu_result, vmul_result;

    // --------------------------------------------
    //                  Result Mux                 
    // --------------------------------------------
    always_comb begin
        result_valid_o = 1'b0;
        result_en_o    = 1'b0;
        result_o       = 64'd0;

        unique case (fu_i)
            VALU : begin
                result_valid_o = valu_result_valid;
                result_en_o    = valu_result_en;
                result_o       = valu_result;
            end

            VMUL : begin
                result_valid_o = vmul_result_valid;
                result_en_o    = vmul_result_en;
                result_o       = vmul_result;
            end

            default : ; // nothing to do
        endcase
    end

    // --------------------------------------------
    //          VALU (finish in one cycle)         
    // --------------------------------------------
    assign valu_valid = (valid_i && fu_i == VALU);
    
    VPU_alu i_VPU_alu (
        .valid_i        ( valu_valid        ),
        .valu_ctrl_i    ( mode_i.alu        ),
        .vsew_i,
        .vxrm_i,
        .operand1_i,
        .operand2_i,
        .mask_i,
        .result_valid_o ( valu_result_valid ),
        .result_en_o    ( valu_result_en    ),
        .result_o       ( valu_result       )
    );

    // --------------------------------------------
    //          VMUL (finish in two cycle)         
    // --------------------------------------------
    assign mul_valid = (valid_i && fu_i == VMUL);
    
    VPU_mul i_VPU_mul (
        .clk_i,
        .rst_i,
        .valid_i        ( mul_valid         ),
        .vmul_ctrl_i    ( mode_i.mul        ),
        .vsew_i,
        .vxrm_i,
        .operand1_i,
        .operand2_i,
        .operand3_i,
        .mask_i,
        .result_valid_o ( vmul_result_valid ),
        .result_en_o    ( vmul_result_en    ),
        .result_o       ( vmul_result       )
    );


endmodule