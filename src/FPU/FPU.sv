module FPU (
    input  logic        clk_i,
    input  logic        rst_i,

    input  OPERATOR_t   op_i,
    input  logic [31:0] operand1_i,
    input  logic [31:0] operand2_i,
    input  logic [31:0] operand3_i,
    output logic [31:0] fpu_result_o,
    output logic        fpu_wait_o        // new
);

    logic        unsign;
    assign       unsign = op_i inside {_FCVTWUS, _FCVTSWU};

    // --------------------------------------------
    //             FPU: MUL/ADD/SUB               
    // --------------------------------------------
    logic [31:0] fpu_mul_result;
    logic [31:0] fpu_alu_result;
    logic        fpu_mul_overflow;
    logic        fpu_alu_overflow;

    fpu_mul_alu i_fpu_mul_alu (
        .clk_i,
        .rst_i,
        .op_i                   ( op_i                  ),
        .operand1_i             ( operand1_i            ),
        .operand2_i             ( operand2_i            ),
        .operand3_i             ( operand3_i            ),
        .fpu_mul_overflow       ( fpu_mul_overflow      ),
        .fpu_alu_overflow       ( fpu_alu_overflow      ),
        .fpu_mul_result_o       ( fpu_mul_result        ),
        .fpu_alu_result_o       ( fpu_alu_result        )
    );

    // --------------------------------------------
    //                  FPU: CONV                  
    // --------------------------------------------
    // FCVTWS/FCVTWUS : FCVT S to W
    logic [31:0] fpu_cvts2w_result;
    logic [ 7:0] cvts2w_shift;
    logic [54:0] cvts2w_mant;

    always_comb begin
        cvts2w_shift = 8'd0;
        cvts2w_mant  = 55'd0;

        if      (operand1_i[30:23] < 8'd127)    fpu_cvts2w_result = 32'd0;
        else if (operand1_i[30:23] > 8'd158)    fpu_cvts2w_result = 32'hffffffff;
        else begin
            cvts2w_shift = operand1_i[30:23] - 8'd127;
            cvts2w_mant  = {32'd1, operand1_i[22: 0]} << cvts2w_shift;
            fpu_cvts2w_result = (unsign) ? cvts2w_mant[54:23] : (({32{operand1_i[31]}} ^ cvts2w_mant[54:23]) + operand1_i[31]);
        end
    end

    // FCVTSW/FCVTSWU : CVT W to S
    logic [31:0] fpu_cvtw2s_result;
    logic [ 4:0] first_one;
    logic        cvtw2s_sign_out;
    logic [ 7:0] cvtw2s_exp_norm, cvtw2s_exp_out;
    logic [31:0] cvtw2s_mant_norm, operand_1_abs;
    logic [22:0] cvtw2s_mant_out;
    logic        cvtw2s_guard_bit, cvtw2s_round_bit, cvtw2s_sticky_bit;
    logic        cvtw2s_round_up;

    always_comb begin
        operand_1_abs = (unsign)? operand1_i: (({32{operand1_i[31]}}^operand1_i)+operand1_i[31]);
        first_one     = operand_1_abs[31] ? 5'd31 : operand_1_abs[30] ? 5'd30 :
                        operand_1_abs[29] ? 5'd29 : operand_1_abs[28] ? 5'd28 :
                        operand_1_abs[27] ? 5'd27 : operand_1_abs[26] ? 5'd26 :
                        operand_1_abs[25] ? 5'd25 : operand_1_abs[24] ? 5'd24 :
                        operand_1_abs[23] ? 5'd23 : operand_1_abs[22] ? 5'd22 :
                        operand_1_abs[21] ? 5'd21 : operand_1_abs[20] ? 5'd20 :
                        operand_1_abs[19] ? 5'd19 : operand_1_abs[18] ? 5'd18 :
                        operand_1_abs[17] ? 5'd17 : operand_1_abs[16] ? 5'd16 :
                        operand_1_abs[15] ? 5'd15 : operand_1_abs[14] ? 5'd14 :
                        operand_1_abs[13] ? 5'd13 : operand_1_abs[12] ? 5'd12 :
                        operand_1_abs[11] ? 5'd11 : operand_1_abs[10] ? 5'd10 :
                        operand_1_abs[9]  ? 5'd9  : operand_1_abs[8]  ? 5'd8  : 
                        operand_1_abs[7]  ? 5'd7  : operand_1_abs[6]  ? 5'd6  : 
                        operand_1_abs[5]  ? 5'd5  : operand_1_abs[4]  ? 5'd4  : 
                        operand_1_abs[3]  ? 5'd3  : operand_1_abs[2]  ? 5'd2  : 
                        operand_1_abs[1]  ? 5'd1  : 5'd0;

        cvtw2s_mant_norm    = operand_1_abs << (6'd32 - {1'b0,first_one});
        cvtw2s_exp_norm     = (operand_1_abs == 32'b0) ? 8'b0 : 8'd127 + {3'b0,first_one};
        cvtw2s_sign_out     = (unsign) ? 1'b0 : operand1_i[31];
        // rounding
        cvtw2s_guard_bit    = cvtw2s_mant_norm[8];
        cvtw2s_round_bit    = cvtw2s_mant_norm[7];
        cvtw2s_sticky_bit   = |cvtw2s_mant_norm[6:0];
        cvtw2s_round_up     = cvtw2s_guard_bit & (cvtw2s_round_bit | cvtw2s_sticky_bit);
        cvtw2s_mant_out     = (cvtw2s_round_up) ? (cvtw2s_mant_norm[31:9] + 23'd1) : (cvtw2s_mant_norm[31:9]);
        cvtw2s_exp_out      = (cvtw2s_round_up & (cvtw2s_mant_norm[31:9] == ~23'b0)) ? cvtw2s_exp_norm + 8'd1 : cvtw2s_exp_norm;
        fpu_cvtw2s_result   = {cvtw2s_sign_out, cvtw2s_exp_out[7:0], cvtw2s_mant_out};
    end

    // --------------------------------------------
    //               FPU: Classifier               
    // --------------------------------------------
    logic [31:0] fpu_class_result;
    logic operand1_is_infinite;
    logic operand1_is_normal;
    logic operand1_is_subnormal;
    logic operand1_is_zero, operand2_is_zero;
    logic operand1_is_nan, operand1_is_signalling, operand1_is_quiet, operand2_is_nan, operand2_is_signalling;

    always_comb begin : FPU_classify_operand
        operand1_is_infinite   = (operand1_i[30:23] == 8'hff) && (operand1_i[22: 0] == 23'd0);
        operand1_is_normal     = (operand1_i[30:23] != 8'd0 ) && (operand1_i[30:23] != 8'hff);
        operand1_is_subnormal  = (operand1_i[30:23] == 8'd0 ) && (operand1_i[22: 0] != 23'd0);
        operand1_is_zero       = (operand1_i[30:23] == 8'd0 ) && (operand1_i[22: 0] == 23'd0);
        operand1_is_nan        = (operand1_i[30:23] == 8'hff) && (operand1_i[21: 0] != 22'd0);
        operand1_is_signalling = operand1_is_nan           && (operand1_i[22] ==  1'b0);
        operand1_is_quiet      = operand1_is_nan           && (operand1_i[22] ==  1'b1);

        operand2_is_zero       = (operand2_i[30:23] == 8'd0) && (operand2_i[22: 0] == 23'd0);
        operand2_is_nan        = (operand2_i[30:23] == 8'd1) && (operand2_i[21: 0] != 22'd0);
        operand2_is_signalling = operand2_is_nan           && (operand2_i[22] ==  1'b0);
    end

    always_comb begin : FPU_classify_result
        if (operand1_is_infinite)
            fpu_class_result = operand1_i[31] ? 32'd0 : 32'd7;
        else if (operand1_is_normal)
            fpu_class_result = operand1_i[31] ? 32'd1 : 32'd6;
        else if (operand1_is_subnormal)
            fpu_class_result = operand1_i[31] ? 32'd2 : 32'd5;
        else if (operand1_is_zero)
            fpu_class_result = operand1_i[31] ? 32'd3 : 32'd4;
        else if (operand1_is_signalling)
            fpu_class_result =                  32'd8;
        else
            fpu_class_result =                  32'd9;   // default value
    end

    // --------------------------------------------
    //                  FPU: COMP                  
    // --------------------------------------------
    logic [31:0] fpu_comp_result;  
    logic operands_equal, operand_a_smaller;

    assign operands_equal    = (operand1_i == operand2_i) | (operand1_is_zero & operand2_is_zero);
    assign operand_a_smaller = (operand1_i  < operand2_i) ^ (operand1_i[31]   | operand2_i[31]  );

    always_comb begin
        fpu_comp_result = 32'b0;

        unique case (op_i)
            _FLES   : fpu_comp_result = {31'd0,(operand_a_smaller |  operands_equal)};
            _FLTS   : fpu_comp_result = {31'd0,(operand_a_smaller & ~operands_equal)};
            _FEQS   : fpu_comp_result = {31'd0,operands_equal};
            default : fpu_comp_result = 32'b0;
        endcase
    end

    // --------------------------------------------
    //               FPU: MAX/MIN               
    // --------------------------------------------
    logic [31:0] fpu_max_mix_result;  

    always_comb begin : FPU_min_max_result
        fpu_max_mix_result = 32'b0;

        if      (operand1_is_nan && operand2_is_nan) fpu_max_mix_result = {1'b0, 8'hff, 1'b1, 22'b0}; // canonical qNaN
        else if (operand1_is_nan)                    fpu_max_mix_result = operand2_i;
        else if (operand2_is_nan)                    fpu_max_mix_result = operand1_i;
        else begin
            unique case (op_i)
                _FMAXS  : fpu_max_mix_result = operand_a_smaller ? operand2_i : operand1_i; // MAX
                _FMINS  : fpu_max_mix_result = operand_a_smaller ? operand1_i : operand2_i; // MIN
                default : fpu_max_mix_result = 32'b0;
            endcase
        end
    end

    // --------------------------------------------
    //                     Wait                    
    // --------------------------------------------
    typedef enum logic [1:0] {
        ONE_CYCLE,
        TWO_CYCLE
    } FPU_STATE_t;

    FPU_STATE_t fpu_state_q, fpu_state_n;

    always_ff @(posedge clk_i) begin : FPU_wait_q
        if (rst_i) fpu_state_q <= ONE_CYCLE;
        else       fpu_state_q <= fpu_state_n;
    end

    logic need_two_cycyle;

    always_comb begin : FPU_wait_n
        need_two_cycyle = op_i inside{_FADDS, _FSUBS, _FMADD, _FMSUB, _FNMADD, _FNMSUB};

        unique case (fpu_state_q)
            ONE_CYCLE : fpu_state_n = (need_two_cycyle) ? TWO_CYCLE : ONE_CYCLE;
            TWO_CYCLE : fpu_state_n = ONE_CYCLE;
            default   : fpu_state_n = ONE_CYCLE;
        endcase
    end

    logic  fpu_finish;

    assign fpu_finish = fpu_state_n == ONE_CYCLE;
    assign fpu_wait_o = ~fpu_finish;

    // --------------------------------------------
    //                Output Result                
    // --------------------------------------------
    logic overflow_o;

    always_comb begin
        if (fpu_finish) begin
            unique case (op_i)
                _FADDS, _FSUBS, _FMADD, _FMSUB, _FNMADD, _FNMSUB : begin
                    fpu_result_o = fpu_alu_result;
                    overflow_o   = fpu_alu_overflow;
                end

                _FMULS : begin
                    fpu_result_o = fpu_mul_result;
                    overflow_o   = fpu_mul_overflow;
                end

                _FCVTWS, _FCVTWUS : begin
                    fpu_result_o = fpu_cvts2w_result;
                    overflow_o   = 1'b0;
                end 

                _FCVTSW, _FCVTSWU : begin
                    fpu_result_o = fpu_cvtw2s_result;
                    overflow_o   = 1'b0;
                end

                _FCLASSS : begin
                    fpu_result_o = fpu_class_result;
                    overflow_o   = 1'b0;
                end

                _FEQS, _FLTS, _FLES : begin
                    fpu_result_o = fpu_comp_result;
                    overflow_o   = 1'b0;
                end

                _FMINS, _FMAXS : begin
                    fpu_result_o = fpu_max_mix_result;
                    overflow_o   = 1'b0;
                end

                _FSGNJS : begin
                    fpu_result_o = { operand2_i[31],operand1_i[30:0]};
                    overflow_o   = 1'b0;
                end

                _FSGNJNS : begin
                    fpu_result_o = {~operand2_i[31],operand1_i[30:0]};
                    overflow_o   = 1'b0;
                end

                _FSGNJXS : begin
                    fpu_result_o = { operand2_i[31]^operand1_i[31],operand1_i[30:0]};
                    overflow_o   = 1'b0;
                end

                _FMVXW, _FMVWX : begin
                    fpu_result_o = operand1_i;
                    overflow_o   = 1'b0;
                end

                default : begin
                    fpu_result_o = 32'b0;
                    overflow_o   = 1'b0;
                end
            endcase

        end else begin
            fpu_result_o = 32'b0;
            overflow_o   = 1'b0;
        end
    end

endmodule