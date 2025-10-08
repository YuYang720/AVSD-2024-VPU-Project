module fpu_mul_alu (
    input  logic        clk_i,
    input  logic        rst_i,

    input  OPERATOR_t   op_i,
    input  logic [31:0] operand1_i,
    input  logic [31:0] operand2_i,
    input  logic [31:0] operand3_i,
    output logic        fpu_mul_overflow,
    output logic        fpu_alu_overflow,
    output logic [31:0] fpu_mul_result_o,
    output logic [31:0] fpu_alu_result_o
);

    // --------------------------------------------
    //              Signal Declaration             
    // --------------------------------------------
    // signals for step 0
    logic        use_sub, use_mul_alu, use_negate;

    // MUL
    // signals for step 1
    logic        sign_1, sign_2;
    logic [ 8:0] exp_1 , exp_2;
    logic [23:0] mant_1, mant_2;

    // signals for step 2
    logic        mul_sign_res;
    logic [ 8:0] mul_exp_res;
    logic [47:0] mul_mant_res;

    // signals for step 3
    logic [ 8:0] mul_exp_norm;
    logic [31:0] mul_mant_norm;

    // signals for step 4
    logic        mul_guard_bit, mul_round_bit, mul_sticky_bit;
    logic        mul_round_up;
    logic        mul_sign_out;
    logic [ 8:0] mul_exp_out;
    logic [22:0] mul_mant_out;
    
    // ADD/SUB
    // signals for step 1
    logic        sign_a, sign_b;
    logic [ 7:0] exp_a , exp_b;
    logic [31:0] mant_a, mant_b;

    // signals for step 2
    logic [ 7:0] exp_diff, exp_res;
    logic [31:0] mant_a_align, mant_b_align;

    // signals for step 3
    logic [31:0] alu_mant_res, mant_sub, mant_add;
    logic        alu_sign_res;

    // pipeline register
    logic        mul_overflow_2nd_stage;
    logic        alu_sign_res_2nd_stage;
    logic [31:0] alu_mant_res_2nd_stage;
    logic [ 7:0] alu_exp_res_2nd_stage;

    // signals for step 4
    logic [ 4:0] leading_zeros;
    logic [31:0] alu_mant_norm;
    logic [ 8:0] alu_exp_norm;

    // signals for step 5
    logic        alu_sign_out;
    logic [22:0] alu_mant_out;
    logic [ 8:0] alu_exp_out;
    logic        alu_guard_bit, alu_round_bit, alu_sticky_bit;
    logic        alu_round_up;

    // --------------------------------------------
    // Step 0. Analyze operations
    // --------------------------------------------
    always_comb begin : Analyze_FMA_operations
        use_sub     = op_i inside {_FSUBS, _FMSUB, _FNMSUB};
        use_mul_alu = op_i inside {_FMADD, _FMSUB, _FNMADD, _FNMSUB};
        use_negate  = op_i inside {_FNMADD, _FNMSUB};
    end

    always_comb begin : FMA_overflow
        fpu_mul_overflow = mul_exp_res[8] | mul_exp_norm[8] | mul_exp_out[8];
        fpu_alu_overflow = mul_overflow_2nd_stage | alu_exp_norm[8] | alu_exp_out[8];
    end

    // ----------------------------------------------------------------
    // MUL              
    // ----------------------------------------------------------------
    // --------------------------------------------
    // Step 1. Break down Sign, Exponent, Mantissa
    // --------------------------------------------
    always_comb begin : breakdown_fmul
        sign_1  = operand1_i[31];
        sign_2  = operand2_i[31];
        exp_1   = {1'b0,operand1_i[30:23]};
        exp_2   = {1'b0,operand2_i[30:23]};
        mant_1  = {1'b1,operand1_i[22:0]};
        mant_2  = {1'b1,operand2_i[22:0]};
    end


    // --------------------------------------------
    //      Step 2. MUL for sign / exp / mant      
    // --------------------------------------------
    always_comb begin : calculating_fmul
        mul_sign_res    = sign_1 ^ sign_2 ^ use_negate;
        mul_exp_res     = exp_1 + exp_2 - 9'd127;
        mul_mant_res    = mant_1 * mant_2;
    end

    // --------------------------------------------
    //          Step 3. Normalized Result          
    // --------------------------------------------
    always_comb begin : normalized_fmul
        if (mul_mant_res[47]) begin
            mul_mant_norm = {1'd0, mul_mant_res[47:17]};
            mul_exp_norm  = mul_exp_res + 8'd1;
        end else begin
            mul_mant_norm = {1'd0, mul_mant_res[46:16]};
            mul_exp_norm  = mul_exp_res;
        end
    end

    // --------------------------------------------
    //              Step 4. Rounding               
    // --------------------------------------------
    always_comb begin : rounding_fmul
        mul_guard_bit       = mul_mant_norm[6];
        mul_round_bit       = mul_mant_norm[5];
        mul_sticky_bit      = |mul_mant_norm[4:0];
        mul_round_up        = mul_guard_bit & (mul_round_bit | mul_sticky_bit);
        mul_mant_out        = (mul_round_up) ? (mul_mant_norm[29:7] + 23'd1) : (mul_mant_norm[29:7]);
        mul_exp_out         = (mul_round_up & (mul_mant_norm[29:7] == ~23'b0)) ? mul_exp_norm + 8'd1 : mul_exp_norm;
        mul_sign_out        = mul_sign_res;
        fpu_mul_result_o    = {mul_sign_out, mul_exp_out[7:0], mul_mant_out};
    end

    // ----------------------------------------------------------------
    // ADD/SUB              
    // ----------------------------------------------------------------
    // --------------------------------------------
    // Step 1. Break down Sign, Exponent, Mantissa
    // --------------------------------------------
    always_comb begin : breakdown_falu
        if (use_mul_alu) begin // from fmul/operand3
            sign_a  = mul_sign_res;
            exp_a   = mul_exp_norm[7:0];
            mant_a  = mul_mant_norm;
            sign_b  = (use_sub ^ operand3_i[31]); // flip sign bits for sub
            exp_b   = operand3_i[30:23];
            mant_b  = {2'b01, operand3_i[22:0], 7'd0};
        end else begin  // from operand1/2
            sign_a  = operand1_i[31];
            exp_a   = operand1_i[30:23];
            mant_a  = {2'b01, operand1_i[22:0], 7'd0};
            exp_b   = operand2_i[30:23];
            sign_b  = (use_sub ^ operand2_i[31]); // flip sign bits for sub
            mant_b  = {2'b01, operand2_i[22:0], 7'd0};
        end
    end

    // --------------------------------------------
    //           Step 2. Aliagn Exponent           
    // --------------------------------------------
    always_comb begin : aliagn_falu
        if (exp_a > exp_b) begin
            exp_res      = exp_a;
            exp_diff     = exp_a - exp_b;
            mant_a_align = mant_a;
            mant_b_align = mant_b >> exp_diff;
        end else begin
            exp_res      = exp_b;
            exp_diff     = exp_b - exp_a;
            mant_a_align = mant_a >> exp_diff;
            mant_b_align = mant_b;
        end
    end

    // --------------------------------------------
    //         Step 3. ADD / SUB for mant          
    // --------------------------------------------
    always_comb begin : calculating_falu
        mant_add = mant_a_align + mant_b_align;
        mant_sub = mant_a_align - mant_b_align;

        if (sign_a == sign_b) begin
            alu_sign_res = sign_a;
            alu_mant_res = mant_add;
        end else begin
            alu_sign_res = (mant_sub[31]) ? (sign_b   ) : (sign_a  );
            alu_mant_res = (mant_sub[31]) ? (-mant_sub) : (mant_sub);
        end
    end

    // --------------------------------------------
    //             Pipeline Registers              
    // --------------------------------------------
    always_ff @(posedge clk_i) begin : pipe_reg_falu
        if (rst_i) begin
            mul_overflow_2nd_stage <= 1'b0;
            alu_sign_res_2nd_stage <= 1'b0;
            alu_mant_res_2nd_stage <= 32'd0;
            alu_exp_res_2nd_stage  <= 8'd0;
        end else begin
            mul_overflow_2nd_stage <= (use_mul_alu) ? fpu_mul_overflow : 1'b0;
            alu_sign_res_2nd_stage <= alu_sign_res;
            alu_mant_res_2nd_stage <= alu_mant_res;
            alu_exp_res_2nd_stage  <= exp_res;
        end
    end

    // --------------------------------------------
    //          Step 4. Normalized Result          
    // --------------------------------------------
    always_comb begin : normalized_falu
        priority if (alu_mant_res_2nd_stage[30]) leading_zeros  = 5'd0;
        else if     (alu_mant_res_2nd_stage[29]) leading_zeros  = 5'd1;
        else if     (alu_mant_res_2nd_stage[28]) leading_zeros  = 5'd2;
        else if     (alu_mant_res_2nd_stage[27]) leading_zeros  = 5'd3;
        else if     (alu_mant_res_2nd_stage[26]) leading_zeros  = 5'd4;
        else if     (alu_mant_res_2nd_stage[25]) leading_zeros  = 5'd5;
        else if     (alu_mant_res_2nd_stage[24]) leading_zeros  = 5'd6;
        else if     (alu_mant_res_2nd_stage[23]) leading_zeros  = 5'd7;
        else if     (alu_mant_res_2nd_stage[22]) leading_zeros  = 5'd8;
        else if     (alu_mant_res_2nd_stage[21]) leading_zeros  = 5'd9;
        else if     (alu_mant_res_2nd_stage[20]) leading_zeros  = 5'd10;
        else if     (alu_mant_res_2nd_stage[19]) leading_zeros  = 5'd11;
        else if     (alu_mant_res_2nd_stage[18]) leading_zeros  = 5'd12;
        else if     (alu_mant_res_2nd_stage[17]) leading_zeros  = 5'd13;
        else if     (alu_mant_res_2nd_stage[16]) leading_zeros  = 5'd14;
        else if     (alu_mant_res_2nd_stage[15]) leading_zeros  = 5'd15;
        else if     (alu_mant_res_2nd_stage[14]) leading_zeros  = 5'd16;
        else if     (alu_mant_res_2nd_stage[13]) leading_zeros  = 5'd17;
        else if     (alu_mant_res_2nd_stage[12]) leading_zeros  = 5'd18;
        else if     (alu_mant_res_2nd_stage[11]) leading_zeros  = 5'd19;
        else if     (alu_mant_res_2nd_stage[10]) leading_zeros  = 5'd20;
        else if     (alu_mant_res_2nd_stage[ 9]) leading_zeros  = 5'd21;
        else if     (alu_mant_res_2nd_stage[ 8]) leading_zeros  = 5'd22;
        else if     (alu_mant_res_2nd_stage[ 7]) leading_zeros  = 5'd23;
        else if     (alu_mant_res_2nd_stage[ 6]) leading_zeros  = 5'd24;
        else if     (alu_mant_res_2nd_stage[ 5]) leading_zeros  = 5'd25;
        else if     (alu_mant_res_2nd_stage[ 4]) leading_zeros  = 5'd26;
        else if     (alu_mant_res_2nd_stage[ 3]) leading_zeros  = 5'd27;
        else if     (alu_mant_res_2nd_stage[ 2]) leading_zeros  = 5'd28;
        else if     (alu_mant_res_2nd_stage[ 1]) leading_zeros  = 5'd29;
        else if     (alu_mant_res_2nd_stage[ 0]) leading_zeros  = 5'd30;
        else                                     leading_zeros  = 5'd31;

        if (alu_mant_res_2nd_stage[31]) begin
            alu_mant_norm   = {1'd0, alu_mant_res_2nd_stage[31:1]};
            alu_exp_norm    = {1'b0,alu_exp_res_2nd_stage} + 9'd1;
        end else begin
            alu_mant_norm   = alu_mant_res_2nd_stage << leading_zeros;
            alu_exp_norm    = {1'b0,alu_exp_res_2nd_stage} - {4'b0,leading_zeros};
        end
    end

    // --------------------------------------------
    //              Step 5. Rounding               
    // --------------------------------------------
    always_comb begin : rounding_falu
        alu_guard_bit       = alu_mant_norm[6];
        alu_round_bit       = alu_mant_norm[5];
        alu_sticky_bit      = |alu_mant_norm[4:0];
        alu_round_up        = alu_guard_bit & (alu_round_bit | alu_sticky_bit);
        alu_mant_out        = (alu_round_up) ? (alu_mant_norm[29:7] + 23'd1) : (alu_mant_norm[29:7]);
        alu_exp_out         = (alu_round_up & (alu_mant_norm[29:7] == ~23'b0)) ? alu_exp_norm + 9'd1 : alu_exp_norm;
        alu_sign_out        = alu_sign_res_2nd_stage;
        fpu_alu_result_o    = {alu_sign_out, alu_exp_out[7:0], alu_mant_out};
    end

endmodule