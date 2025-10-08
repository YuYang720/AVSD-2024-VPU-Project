module exe_stage (
    input  logic        clk_i,
    input  logic        rst_i,

    // control signal
    input  logic        flush_i,
    input  logic        stall_i,
    input  logic        waiting_i,
    output logic        wfi_o,
    output logic        mret_o,
    output logic [31:0] exe_pc_o,

    // vector control signal (if VPU accept the inst)
    output logic        vector_unaccept_o,

    // fpu control signal
    output logic        fpu_wait_o,

    // from ID
    input  uOP_t        exe_uOP_i,
    input  logic [31:0] rs1_data_i,
    input  logic [31:0] rs2_data_i,
    input  logic [31:0] rs3_data_i,
    
    // resolved branch
    output logic        btkn_o,
    output logic [31:0] bta_o,

    // request to D$
    output logic        dcache_core_request_o,
    output logic [ 3:0] dcache_core_write_o,
    output logic [31:0] dcache_core_addr_o,
    output logic [31:0] dcache_core_in_o,

    // WB/MEM data forwarding
    input  logic        wb_rs1_forward_i,
    input  logic        wb_rs2_forward_i,
    input  logic        wb_rs3_forward_i,
    input  logic        mem_rs1_forward_i,
    input  logic        mem_rs2_forward_i,
    input  logic        mem_rs3_forward_i,
    input  logic [31:0] wb_data_i,

    // to MEM
    output uOP_t        mem_uOP_o,
    output logic [31:0] mem_mul_result_o,
    output logic [31:0] mem_csr_operand_o,

    // to VPU
    output logic        vector_inst_valid_o,
    output logic [31:0] vector_inst_o,
    output logic [31:0] vector_xrs1_val_o,
    output logic [31:0] vector_xrs2_val_o,
    input  logic        vector_ack_i,
    input  logic        vector_writeback_i,
    input  logic        vector_pend_lsu_i,

    // Branch Prediction
    input predict_info  BP_info_ID_to_EX,
    output BHT_data     bht_update,
    output BTB_data     btb_update,
    output logic        BU_flush_o
);

    // --------------------------------------------
    //              Signal Declaration             
    // --------------------------------------------
    // operand selection
    logic [31:0] rs1_data, rs2_data, rs3_data;
    logic [31:0] operand1, operand2, operand3;
    logic [31:0] base_pc, offest;
    logic [31:0] store_data, align;
    logic [ 3:0] mask;
    logic        use_jtype;

    // function unit result
    logic [31:0] alu_result, fpu_result;
    logic [31:0] mul_result, csr_operand;
    logic [31:0] exe_pc_q;

    // pipeline register
    uOP_t        uOP_q, uOP_n;
    logic [31:0] mem_csr_operand_q;

    // Branch Prediction
    logic BP_taken, RET, use_btype, RET_inst;
    logic [31:0] BP_addr, RAS_addr, BU_pc;

    // --------------------------------------------
    //      Operand Select and Data Forwarding     
    // --------------------------------------------
    always_comb begin : rs_data_forwarding
        priority if (mem_rs1_forward_i) rs1_data = uOP_q.result;
        else if     (wb_rs1_forward_i ) rs1_data = wb_data_i;
        else                            rs1_data = rs1_data_i;

        priority if (mem_rs2_forward_i) rs2_data = uOP_q.result;
        else if     (wb_rs2_forward_i ) rs2_data = wb_data_i;
        else                            rs2_data = rs2_data_i;

        priority if (mem_rs3_forward_i) rs3_data = uOP_q.result;
        else if     (wb_rs3_forward_i ) rs3_data = wb_data_i;
        else                            rs3_data = rs3_data_i;
    end
    
    always_comb begin : operand_select
        use_jtype = (exe_uOP_i.op inside {_JAL, _JALR});

        if (exe_uOP_i.use_pc) operand1 = exe_uOP_i.pc;
        else                  operand1 = rs1_data;

        if      (exe_uOP_i.use_imme) operand2 = exe_uOP_i.result;
        else if (use_jtype         ) operand2 = 32'd4;
        else                         operand2 = rs2_data;

        operand3 = rs3_data;
    end
    
    // --------------------------------------------
    //                Function Units               
    // --------------------------------------------
    alu i_alu (
        .op_i         ( exe_uOP_i.op ),
        .operand1_i   ( operand1     ),
        .operand2_i   ( operand2     ),
        .alu_result_o ( alu_result   )
    );

    FPU i_fpu(
        .clk_i,
        .rst_i,
        .op_i         ( exe_uOP_i.op ),
        .operand1_i   ( operand1     ),
        .operand2_i   ( operand2     ),
        .operand3_i   ( operand3     ),
        .fpu_result_o ( fpu_result   ),
        .fpu_wait_o
    );

    multiplier i_mul (
        .clk_i,
        .rst_i,
        .op_i         ( exe_uOP_i.op ),
        .operand1_i   ( operand1     ),
        .operand2_i   ( operand2     ),
        .mul_result_o ( mul_result   )
    );

    // branch unit
    // always_comb begin
    //     base_pc = (exe_uOP_i.op == _JALR) ? (rs1_data) : (exe_uOP_i.pc);
    //     offest  = exe_uOP_i.result;
    //     bta_o   = (base_pc + offest) & (~32'd1);
    //     btkn_o  = (exe_uOP_i.fu == BRU & alu_result[0]) | use_jtype;
    // end

    ///// Branch Unit (calculate branch address) /////
    ///// and check whether the pc is mispredict /////
    assign BP_taken = BP_info_ID_to_EX.ready;
    assign BP_addr  = BP_info_ID_to_EX.target_addr;
    assign RET      = BP_info_ID_to_EX.RET;
    assign RAS_addr = BP_info_ID_to_EX.ras_addr;

    assign RET_inst  = (exe_uOP_i.op == _JALR) && (exe_uOP_i.result == 32'd0) &&
                       (exe_uOP_i.rd == x0   ) && (exe_uOP_i.rs1    == ra);
    assign BU_pc     = exe_uOP_i.pc;
    assign use_btype = (exe_uOP_i.op inside {_EQ, _NE, _LT, _GE, _LTU, _GEU});

    always_comb begin : Branch_Unit
        base_pc = (exe_uOP_i.op == _JALR) ? (rs1_data) : (exe_uOP_i.pc);
        offest  = exe_uOP_i.result;
        bta_o   = (base_pc + offest) & (~32'd1);
        btkn_o  = (exe_uOP_i.fu == BRU & alu_result[0]) | use_jtype;

        if (use_jtype) begin
            if (RET_inst) begin // ret = JALR x0, ra, 0
                    BU_flush_o = (RAS_addr != bta_o);
                end else if (BP_taken) begin
                    // Case 1: Predicted taken; check if target matches
                    BU_flush_o = (BP_addr != bta_o) ? 1'd1 : 1'd0;
                end else begin
                    // Case 3: Predicted not taken; should have been taken
                    BU_flush_o = 1'd1; // Misprediction
                end
        end else if (use_btype) begin
            if (BP_taken) begin
                    if (btkn_o) begin
                        // Case 1: Predicted taken and branch is taken
                        BU_flush_o = (BP_addr != bta_o) ? 1'd1 : 1'd0;
                    end else begin
                        // Case 2: Predicted taken but branch is not taken
                        BU_flush_o = 1'd1; // Misprediction
                        bta_o = BU_pc+32'd4;
                    end
                end else begin
                    if (btkn_o) begin
                        // Case 3: Predicted not taken but branch is taken
                        BU_flush_o = 1'd1; // Misprediction
                    end else begin
                        // Case 4: Predicted not taken and branch is not taken
                        BU_flush_o = 1'd0; // No BU_flush_o
                    end
                end
        end else BU_flush_o = 1'd0; // Non-branch instructions
    end

    // update BHT, BTB
    always_ff @(posedge clk_i) begin : update_branch_predict
        if (rst_i) begin
            bht_update <= BHT_data'(0);
            btb_update <= BTB_data'(0);
        end else begin
            // Update for B-Type instructions
            if (use_btype) begin
                // Update BHT
                bht_update.valid <= 1'd1;
                bht_update.taken <= btkn_o; // Whether the branch was taken
                bht_update.pc    <= BU_pc;

                // BTB is updated only if the branch is taken
                if (btkn_o) begin
                    btb_update.valid       <= 1'd1;
                    btb_update.pc          <= BU_pc;
                    btb_update.target_addr <= bta_o; // Target address for taken branches
                end else begin
                    btb_update.valid       <= 1'd0; // No BTB update for untaken branches
                end
            end 

            // Update for JAL and JALR instructions
            else if (use_jtype) begin
                // Update BHT
                bht_update.valid <= 1'd1;
                bht_update.taken <= 1'd1; // Whether the branch was taken
                bht_update.pc    <= BU_pc;

                // Update BTB for JAL/JALR
                btb_update.valid       <= 1'd1;
                btb_update.pc          <= BU_pc;
                btb_update.target_addr <= bta_o; // Always update target address
            end 

            // No branch instruction, invalidate updates
            else begin
                bht_update.valid <= 1'd0;
                btb_update.valid <= 1'd0;
            end
        end
    end

    // load store unit
    always_comb begin
        // choose bit mask for store
        unique case (exe_uOP_i.op)
            _SB    : mask = 4'b0001;
            _SH    : mask = 4'b0011;
            _SW    : mask = 4'b1111;
            default: mask = 4'b0000;
        endcase

        // data and mask alignment
        align      = ( {30'd0, alu_result[1:0]} << 32'd3 );
        store_data = rs2_data << align;

        // send out dcache request
        dcache_core_request_o = (exe_uOP_i.fu == GLSU) && ~stall_i;
        dcache_core_write_o   = mask << alu_result[1:0];
        dcache_core_addr_o    = alu_result;
        dcache_core_in_o      = store_data;
    end

    // csr buffer unit
    assign csr_operand = (exe_uOP_i.use_imme) ? ({27'd0, exe_uOP_i.rs1}) : (rs1_data);
    assign wfi_o       = (exe_uOP_i.op == _WFI);
    assign mret_o      = (exe_uOP_i.op == _MRET);
    assign exe_pc_o    = exe_pc_q;

    always_ff @(posedge clk_i) begin
        if      (rst_i)     exe_pc_q <= 32'd0;
        else if (waiting_i) exe_pc_q <= exe_pc_q;
        else                exe_pc_q <= exe_uOP_i.pc;
    end

    // VPU frontend (just send out instruction)
    always_comb begin
        vector_inst_valid_o = (exe_uOP_i.fu == VPU) && ~(stall_i);
        vector_inst_o       = exe_uOP_i.result;
        vector_xrs1_val_o   = (exe_uOP_i.rs1 != x0) ? (operand1) : (32'd0);
        vector_xrs2_val_o   = (exe_uOP_i.rs2 != x0) ? (operand2) : (32'd0);

        // CPU control signal
        vector_unaccept_o   = vector_inst_valid_o && ~vector_ack_i;
    end

    // --------------------------------------------
    //          EXE/MEM Pipeline Registers         
    // --------------------------------------------
    assign mem_uOP_o         = uOP_q;
    assign mem_mul_result_o  = mul_result;
    assign mem_csr_operand_o = mem_csr_operand_q;

    always_comb begin
        uOP_n = exe_uOP_i;

        unique case(exe_uOP_i.fu)
            GALU, BRU  : {uOP_n.valid, uOP_n.result} = {1'b1, alu_result      };
            CSR        : {uOP_n.valid, uOP_n.result} = {1'b1, exe_uOP_i.result};
            FPU        : {uOP_n.valid, uOP_n.result} = {1'b1, fpu_result      };
            GLSU, GMUL : {uOP_n.valid, uOP_n.result} = {1'b0, align           };
            default    : {uOP_n.valid, uOP_n.result} = {1'b0, alu_result      };
        endcase

        // VPU writeback check
        if (exe_uOP_i.fu == VPU) begin
            uOP_n.valid  = ~(vector_writeback_i | vector_pend_lsu_i);
            uOP_n.result = 32'd0;
        end
    end

    always_ff @(posedge clk_i) begin
        priority if (rst_i            ) {uOP_q, mem_csr_operand_q} <= {uOP_t'(0), 32'd0            };
        else if     (flush_i          ) {uOP_q, mem_csr_operand_q} <= {uOP_t'(0), 32'd0            };
        else if     (fpu_wait_o       ) {uOP_q, mem_csr_operand_q} <= {uOP_t'(0), 32'd0            };
        else if     (stall_i          ) {uOP_q, mem_csr_operand_q} <= {uOP_q    , mem_csr_operand_q};
        else if     (vector_unaccept_o) {uOP_q, mem_csr_operand_q} <= {uOP_t'(0), 32'd0            };
        else                            {uOP_q, mem_csr_operand_q} <= {uOP_n    , csr_operand      };
    end

endmodule