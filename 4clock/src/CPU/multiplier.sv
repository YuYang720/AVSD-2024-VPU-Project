module multiplier (
    input  logic        clk_i,
    input  logic        rst_i,

    input  OPERATOR_t   op_i,
    input  logic [31:0] operand1_i,
    input  logic [31:0] operand2_i,
    output logic [31:0] mul_result_o
);

    // --------------------------------------------
    //              Signal Declaration             
    // --------------------------------------------
    logic [32:0] operand1_q, operand1_n;
    logic [32:0] operand2_q, operand2_n;
    logic        sign_operand1, sign_operand2;
    OPERATOR_t   op_q;
    logic [65:0] mul_result;

    // --------------------------------------------
    //                   Stage 1                   
    // --------------------------------------------
    assign sign_operand1 = (op_i inside {_MULH, _MULHSU});
    assign sign_operand2 = (op_i == _MULH);
    assign operand1_n    = {operand1_i[31] & sign_operand1 , operand1_i};
    assign operand2_n    = {operand2_i[31] & sign_operand2 , operand2_i};

    // --------------------------------------------
    //              Pipeline Register              
    // --------------------------------------------
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            op_q       <= _ADD;
            operand1_q <= 33'd0;
            operand2_q <= 33'd0;
        end else begin
            op_q       <= op_i;
            operand1_q <= operand1_n;
            operand2_q <= operand2_n;
        end
    end

    // --------------------------------------------
    //                   Stage 2                   
    // --------------------------------------------
    always_comb begin
        mul_result = $signed( {{33{operand1_q[32]}}, operand1_q} ) *
                     $signed( {{33{operand2_q[32]}}, operand2_q} );

        unique case(op_q)
            _MUL    : mul_result_o = mul_result[31: 0];
            _MULH   : mul_result_o = mul_result[63:32];
            _MULHSU : mul_result_o = mul_result[63:32];
            _MULHU  : mul_result_o = mul_result[63:32];
            default : mul_result_o = mul_result[31: 0];
        endcase
    end

endmodule