module VPU_id_stage (
    input  logic               clk_i,
    input  logic               rst_i,

    // from CPU
    input  logic               vector_inst_valid_i,
    input  logic [31:0]        vector_inst_i,
    input  logic [31:0]        vector_xrs1_val_i,
    input  logic [31:0]        vector_xrs2_val_i,
    output logic               vector_ack_o,
    output logic               vector_writeback_o,
    output logic               vector_pend_lsu_o,

    // from VCFG (current vector CSRs)
    input  VSEW_e              vsew_i,    // current SEW (single element width)
    input  VLMUL_e             vlmul_i,   // current register size multiplier
    input  VXRM_e              vxrm_i,    // current rounding mode
    input  logic [VL_BITS-1:0] vl_i,      // current vector length

    // decode buffer --> to CFG or instruction queue
    output logic               decode_entry_valid_o,
    output VPU_uOP_t           decode_entry_o,
    input  logic               decode_ack_i,
    input  logic               VCFG_commit_i
);

    // --------------------------------------------
    //              Signal Declaration             
    // --------------------------------------------
    // signal for decoder
    logic     decode_instr_valid;
    VPU_uOP_t decode_instr;

    // decoder buffer
    logic     decode_buffer_ready;
    logic     decode_buffer_valid_q, decode_buffer_valid_n;
    VPU_uOP_t decode_buffer_q, decode_buffer_n;

    // --------------------------------------------
    //                Vector Decoder               
    // --------------------------------------------
    assign vector_ack_o       = decode_instr_valid && decode_buffer_ready;
    assign vector_writeback_o = decode_instr_valid && ~decode_instr.rd.vreg;
    assign vector_pend_lsu_o  = decode_instr_valid && (decode_instr.fu == VLSU);

    VPU_decoder i_VPU_decoder (
        .vector_inst_valid_i,
        .vector_inst_i,
        .vector_xrs1_val_i,
        .vector_xrs2_val_i,

        .vsew_i,
        .vlmul_i,
        .vxrm_i,
        .vl_i,

        .decode_instr_valid_o ( decode_instr_valid ),
        .decode_instr_o       ( decode_instr       )
    );

    // --------------------------------------------
    //                Decode Buffer                
    // --------------------------------------------
    assign decode_buffer_ready  = ~decode_buffer_valid_q || decode_ack_i;
    assign decode_entry_valid_o = decode_buffer_valid_q;
    assign decode_entry_o       = decode_buffer_q;

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            decode_buffer_valid_q <= 1'b0;
            decode_buffer_q       <= VPU_uOP_t'(0);
        end else begin
            decode_buffer_valid_q <= decode_buffer_valid_n;
            decode_buffer_q       <= decode_buffer_n;
        end
    end

    always_comb begin
        decode_buffer_valid_n = decode_buffer_valid_q;
        decode_buffer_n       = decode_buffer_q;

        if (decode_buffer_ready) begin
            decode_buffer_valid_n = decode_instr_valid;
            decode_buffer_n       = decode_instr;
        end

        if (VCFG_commit_i) begin
            decode_buffer_valid_n = 1'b0;
        end
    end

endmodule