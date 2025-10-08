module id_stage (
    input  logic         clk_i,
    input  logic         rst_i,

    // control signal
    input  logic         flush_i,
    input  logic         stall_i,

    // vector control signal
    input  logic         vector_unaccept_i,

    // fpt control signal
    input  logic         fpu_wait_i,

    // from IF
    input  FETCH_ENTRY_t fetch_entry_i,
    output logic         fetch_ack_o,

    // register writeback
    input  logic         wb_rd_web_i,
    input  logic         wb_frd_web_i,
    input  REG_t         wb_rd_i,
    input  logic [31:0]  wb_data_i,

    // data forwarding
    output uOP_t         id_uOP_o,
    input  logic         id_rs1_forward_i,
    input  logic         id_rs2_forward_i,
    input  logic         id_rs3_forward_i,

    // to EXE
    output uOP_t         exe_uOP_o,
    output logic [31:0]  rs1_data_o,
    output logic [31:0]  rs2_data_o,
    output logic [31:0]  rs3_data_o,

    // Branch Prediction
    input  predict_info  BP_info_IF_to_ID,
    output predict_info  BP_info_ID_to_EX
);

    // --------------------------------------------
    //              Signal Declaration             
    // --------------------------------------------
    // decode instructuon
    uOP_t        decode_instr;

    // regfile data read
    logic [31:0] rs1_gpr_data;
    logic [31:0] rs2_gpr_data;
    logic [31:0] rs1_fpr_data;
    logic [31:0] rs2_fpr_data;
    logic [31:0] rs3_fpr_data;

    // pipeline register
    logic [31:0] rs1_data_q, rs1_data_n;
    logic [31:0] rs2_data_q, rs2_data_n;
    logic [31:0] rs3_data_q, rs3_data_n;
    uOP_t        exe_uOP_q;

    // --------------------------------------------
    //        Decoder / Immediate Generation       
    // --------------------------------------------
    assign id_uOP_o = decode_instr;
    
    rv_decoder i_rv_deocder (
        .fetch_entry_i  ( fetch_entry_i ),
        .decode_instr_o ( decode_instr  )
    );

    // --------------------------------------------
    //            Registers Read / Update          
    // --------------------------------------------
    regfiles i_general_regfiles (
        .clk_i,
        .rst_i,
        // writeback port
        .wb_en_i     ( wb_rd_web_i      ),
        .rd_index_i  ( wb_rd_i          ),
        .rd_data_i   ( wb_data_i        ),
        // read port
        .rs1_index_i ( decode_instr.rs1 ),
        .rs2_index_i ( decode_instr.rs2 ),
        .rs1_data_o  ( rs1_gpr_data     ),
        .rs2_data_o  ( rs2_gpr_data     )
    );

    fp_regfiles i_floating_regfiles (
        .clk_i,
        .rst_i,
        // writeback port
        .wb_en_i     ( wb_frd_web_i     ),
        .rd_index_i  ( wb_rd_i          ),
        .rd_data_i   ( wb_data_i        ),
        // read port
        .rs1_index_i ( decode_instr.rs1 ),
        .rs2_index_i ( decode_instr.rs2 ),
        .rs3_index_i ( decode_instr.rs3 ),
        .rs1_data_o  ( rs1_fpr_data     ),
        .rs2_data_o  ( rs2_fpr_data     ),
        .rs3_data_o  ( rs3_fpr_data     )
    );

    // data forwarding selection
    always_comb begin
        priority if (id_rs1_forward_i       ) rs1_data_n = wb_data_i;
        else if     (decode_instr.use_fpr[2]) rs1_data_n = rs1_fpr_data;
        else                                  rs1_data_n = rs1_gpr_data;

        priority if (id_rs2_forward_i       ) rs2_data_n = wb_data_i;
        else if     (decode_instr.use_fpr[1]) rs2_data_n = rs2_fpr_data;
        else                                  rs2_data_n = rs2_gpr_data;

        priority if (id_rs3_forward_i       ) rs3_data_n = wb_data_i;
        else                                  rs3_data_n = rs3_fpr_data;
    end

    // --------------------------------------------
    //           ID/EXE Pipeline Registers         
    // --------------------------------------------
    assign fetch_ack_o = fetch_entry_i.valid & ~(flush_i | stall_i | fpu_wait_i | vector_unaccept_i);
    assign exe_uOP_o   = exe_uOP_q;
    assign rs1_data_o  = rs1_data_q;
    assign rs2_data_o  = rs2_data_q;
    assign rs3_data_o  = rs3_data_q;

    always_ff @(posedge clk_i) begin
        priority if (rst_i) begin
            exe_uOP_q        <= uOP_t'(0);
            rs1_data_q       <= 32'd0;
            rs2_data_q       <= 32'd0;
            rs3_data_q       <= 32'd0;
            BP_info_ID_to_EX <= predict_info'(0);
        end else if (stall_i || fpu_wait_i || vector_unaccept_i) begin
            exe_uOP_q        <= exe_uOP_q;
            rs1_data_q       <= rs1_data_q;
            rs2_data_q       <= rs2_data_q;
            rs3_data_q       <= rs3_data_q;
            BP_info_ID_to_EX <= BP_info_ID_to_EX;
        end else if (flush_i) begin
            exe_uOP_q        <= uOP_t'(0);
            rs1_data_q       <= 32'd0;
            rs2_data_q       <= 32'd0;
            rs3_data_q       <= 32'd0;
            BP_info_ID_to_EX <= predict_info'(0);
        end else begin
            exe_uOP_q        <= decode_instr;
            rs1_data_q       <= rs1_data_n;
            rs2_data_q       <= rs2_data_n;
            rs3_data_q       <= rs3_data_n;
            BP_info_ID_to_EX <= BP_info_IF_to_ID;
        end
    end

endmodule