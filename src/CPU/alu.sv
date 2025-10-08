module alu (
    input  OPERATOR_t   op_i,
    input  logic [31:0] operand1_i,
    input  logic [31:0] operand2_i,
    output logic [31:0] alu_result_o
);

    // --------------------------------------------
    //              Signal Declaration             
    // --------------------------------------------
    logic [31:0] add_result, sub_result;
    logic [31:0] and_result, or_result, xor_result;
    logic [31:0] srl_result, sll_result, sra_result;
    logic        eq_result, ne_result, lt_result;
    logic        ge_result, ltu_result, geu_result;

    // --------------------------------------------
    //             Calculate All Result            
    // --------------------------------------------
    assign add_result = operand1_i + operand2_i;
    assign sub_result = operand1_i - operand2_i;
    assign and_result = operand1_i & operand2_i;
    assign or_result  = operand1_i | operand2_i;
    assign xor_result = operand1_i ^ operand2_i;
    assign srl_result = operand1_i >> operand2_i[4:0];
    assign sll_result = operand1_i << operand2_i[4:0];
    assign sra_result = $signed(operand1_i) >>> operand2_i[4:0];
    assign eq_result  = (operand1_i == operand2_i);
    assign lt_result  = ($signed(operand1_i) < $signed(operand2_i));
    assign ltu_result = (operand1_i < operand2_i);
    assign ne_result  = ~eq_result;
    assign ge_result  = ~lt_result;
    assign geu_result = ~ltu_result;

    // --------------------------------------------
    //                  Result Mux                 
    // --------------------------------------------
    always_comb begin
        unique case(op_i)
            _ADD    : alu_result_o = add_result;
            _SUB    : alu_result_o = sub_result;
            _JAL    : alu_result_o = add_result;
            _JALR   : alu_result_o = add_result;
            _LB     : alu_result_o = add_result;
            _LH     : alu_result_o = add_result;
            _LW     : alu_result_o = add_result;
            _LBU    : alu_result_o = add_result;
            _LHU    : alu_result_o = add_result;
            _SB     : alu_result_o = add_result;
            _SH     : alu_result_o = add_result;
            _SW     : alu_result_o = add_result;
            _AND    : alu_result_o = and_result;
            _OR     : alu_result_o = or_result;
            _XOR    : alu_result_o = xor_result;
            _SLL    : alu_result_o = sll_result;
            _SRA    : alu_result_o = sra_result;
            _SRL    : alu_result_o = srl_result;
            _LUI    : alu_result_o = operand2_i;
            _EQ     : alu_result_o = {31'd0, eq_result };
            _NE     : alu_result_o = {31'd0, ne_result };
            _LT     : alu_result_o = {31'd0, lt_result };
            _GE     : alu_result_o = {31'd0, ge_result };
            _LTU    : alu_result_o = {31'd0, ltu_result};
            _GEU    : alu_result_o = {31'd0, geu_result};
            default : alu_result_o = 32'd0;
        endcase
    end

endmodule