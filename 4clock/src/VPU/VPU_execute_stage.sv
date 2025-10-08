module VPU_execute_stage (
    input  logic                 clk_i,
    input  logic                 rst_i,

    // from ISSUE
    input  logic                 dispatch_valid_i,
    input  VPU_uOP_t             dispatch_entry_i,
    output logic                 dispatch_ready_o,

    // to regfile (8 read port, 1 write port)
    output logic [2:0][4:0]      vreg_read_addr_o,
    input  logic [2:0][VLEN-1:0] vreg_read_data_i,
    input  logic [VLEN-1:0]      vreg_v0_i,

    output logic                 vreg_write_en_o,
    output logic [4:0]           vreg_write_addr_o,
    output logic [VLEN/8-1:0]    vreg_write_bweb_o,
    output logic [VLEN-1:0]      vreg_write_data_o,

    // request to D$
    output logic                 dcache_vpu_request_o,
    output logic [ 3:0]          dcache_vpu_write_o,
    output logic [31:0]          dcache_vpu_addr_o,
    output logic [31:0]          dcache_vpu_in_o,

    // response from D$
    input  logic                 dcache_vpu_wait_i,
    input  logic [31:0]          dcache_vpu_out_i,

    // lsu commit
    output logic                 lsu_commit_o
);

    // --------------------------------------------
    //              Signal Declaration             
    // --------------------------------------------
    typedef struct packed {
        logic               valid; // if the current instr is valid and can be repalced
        VPU_FU_t            fu;
        VPU_MODE_t          mode;
        logic [2:0]         vreg;
        logic [4:0]         rs1_index;
        logic [4:0]         rs2_index;
        logic [4:0]         rd_index;
        OP_WIDENARROW_e     widenarrow;
        VSEW_e              eew;
        VLMUL_e             emul;
        VXRM_e              vxrm;
        logic [VL_BITS-1:0] vl;
    } state_t;

    state_t             exe_state_q, exe_state_n;
    logic [VL_BITS-1:0] vl_count_q, vl_count_n;

    // operand collection
    logic [4:0]         vreg_addr_offset;
    logic [63:0]        rs1_val_q, rs2_val_q, rs3_val_q;
    logic [63:0]        rs1_val_n, rs2_val_n, rs3_val_n;

    // lane installation
    logic               lane_valid;
    logic               lane_done;
    logic [VL_BITS-1:0] lane_vl_update;
    logic               lane_result_valid;
    logic [4:0]         lane_result_addr;
    logic [VLEN/8-1:0]  lane_result_bweb;
    logic [VLEN-1:0]    lane_result_data;

    // lsu signal
    logic               lsu_valid;
    logic               lsu_done;
    logic [VL_BITS-1:0] lsu_vl_update;
    logic               lsu_result_valid;
    logic [4:0]         lsu_result_addr;
    logic [VLEN/8-1:0]  lsu_result_bweb;
    logic [VLEN-1:0]    lsu_result_data;

    // sld signal
    logic               sld_valid;
    logic               sld_done;
    logic [VL_BITS-1:0] sld_vl_update;
    logic [4:0]         sld_rs2_read_addr;
    logic               sld_result_valid;
    logic [4:0]         sld_result_addr;
    logic [VLEN/8-1:0]  sld_result_bweb;
    logic [VLEN-1:0]    sld_result_data;

    // elem signal
    logic               elem_valid;
    logic               elem_done;
    logic [VL_BITS-1:0] elem_vl_update;
    logic [4:0]         elem_rs2_read_addr;
    logic               elem_result_valid;
    logic [4:0]         elem_result_addr;
    logic [VLEN/8-1:0]  elem_result_bweb;
    logic [VLEN-1:0]    elem_result_data;

    // mask unit signal
    logic               mask_valid;
    logic               mask_done;
    logic [VL_BITS-1:0] mask_vl_update;
    logic               mask_result_valid;
    logic [4:0]         mask_result_addr;
    logic [VLEN/8-1:0]  mask_result_bweb;
    logic [VLEN-1:0]    mask_result_data;

    // --------------------------------------------
    //            Execute state control            
    // --------------------------------------------
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            exe_state_q <= state_t'(0);
            vl_count_q  <= VL_BITS'(0);
            rs1_val_q   <= 64'd0;
            rs2_val_q   <= 64'd0;
            rs3_val_q   <= 64'd0;
        end else begin
            exe_state_q <= exe_state_n;
            vl_count_q  <= vl_count_n;
            rs1_val_q   <= rs1_val_n;
            rs2_val_q   <= rs2_val_n;
            rs3_val_q   <= rs3_val_n;
        end
    end

    always_comb begin
        exe_state_n      = exe_state_q;
        vl_count_n       = vl_count_q;
        
        // default assignment
        dispatch_ready_o = ~exe_state_q.valid;
        lsu_commit_o     = 1'b0;

        // execute unit installation
        lane_valid = exe_state_q.valid && exe_state_q.fu inside {VALU, VMUL};
        mask_valid = exe_state_q.valid && exe_state_q.fu inside {VMASK};
        lsu_valid  = exe_state_q.valid && exe_state_q.fu inside {VLSU};
        sld_valid  = exe_state_q.valid && exe_state_q.fu inside {VSLD};
        elem_valid = exe_state_q.valid && exe_state_q.fu inside {VELEM};

        // execute progess track
        if (exe_state_q.valid) begin
            // update VL according to execution unit
            unique case (exe_state_q.fu)
                VALU    : vl_count_n = vl_count_q + ((lane_valid) ? (lane_vl_update) : (VL_BITS'(0)));
                VMUL    : vl_count_n = vl_count_q + ((lane_valid) ? (lane_vl_update) : (VL_BITS'(0)));
                VSLD    : vl_count_n = vl_count_q + sld_vl_update;
                VELEM   : vl_count_n = vl_count_q + elem_vl_update;
                VMASK   : vl_count_n = vl_count_q + mask_vl_update;
                VLSU    : vl_count_n = lsu_vl_update;
                default : ; // nothing to do
            endcase

            // ensure we don't exceed the actual VL
            if (vl_count_n >= exe_state_q.vl) vl_count_n = exe_state_q.vl;

            // check if done (execute unit handshake)
            if (lane_done || lsu_done || mask_done || sld_done || elem_done) begin
                dispatch_ready_o  = 1'b1;
                lsu_commit_o      = lsu_done;
                exe_state_n       = state_t'(0);
            end
        end

        if (dispatch_valid_i) begin
            exe_state_n.valid      = 1'b1;
            exe_state_n.fu         = dispatch_entry_i.fu;
            exe_state_n.mode       = dispatch_entry_i.mode;
            exe_state_n.vreg[0]    = dispatch_entry_i.rs1.vreg;
            exe_state_n.vreg[1]    = dispatch_entry_i.rs2.vreg;
            exe_state_n.vreg[2]    = dispatch_entry_i.rd.vreg;
            exe_state_n.rs1_index  = dispatch_entry_i.rs1.index;
            exe_state_n.rs2_index  = dispatch_entry_i.rs2.index;
            exe_state_n.rd_index   = dispatch_entry_i.rd.index;
            exe_state_n.widenarrow = dispatch_entry_i.widenarrow;
            exe_state_n.eew        = dispatch_entry_i.eew;
            exe_state_n.emul       = dispatch_entry_i.emul;
            exe_state_n.vxrm       = dispatch_entry_i.vxrm;
            exe_state_n.vl         = dispatch_entry_i.vl;
            vl_count_n             = VL_BITS'(0);
        end
    end

    // --------------------------------------------
    //      Operand Collection / Result write      
    // --------------------------------------------
    // set up register read address
    always_comb begin
        vreg_addr_offset = 5'd0;

        unique case (exe_state_q.eew)
            VSEW_8  : vreg_addr_offset = vl_count_n >> 5'd3;
            VSEW_16 : vreg_addr_offset = vl_count_n >> 5'd2;
            VSEW_32 : vreg_addr_offset = vl_count_n >> 5'd1;
            VSEW_64 : vreg_addr_offset = vl_count_n[4:0];
            default : ;
        endcase

        // default read address
        vreg_read_addr_o[0] = exe_state_q.rs1_index + vreg_addr_offset;
        vreg_read_addr_o[1] = exe_state_q.rs2_index + vreg_addr_offset;
        vreg_read_addr_o[2] = exe_state_q.rd_index  + vreg_addr_offset;

        // set up read when new entry comes
        if (dispatch_valid_i) begin
            vreg_read_addr_o[0] = dispatch_entry_i.rs1.index;
            vreg_read_addr_o[1] = dispatch_entry_i.rs2.index;
            vreg_read_addr_o[2] = dispatch_entry_i.rd.index;
        end

        if (sld_valid) begin
            vreg_read_addr_o[1] = sld_rs2_read_addr;
        end

        if (elem_valid) begin
            vreg_read_addr_o[0] = exe_state_q.rs1_index;
            vreg_read_addr_o[1] = elem_rs2_read_addr;
        end
    end

    // handle read in data
    always_comb begin
        // default rs value : keep store newest value from register
        rs1_val_n = (exe_state_n.vreg[0]) ? (vreg_read_data_i[0]) : (rs1_val_q);
        rs2_val_n = (exe_state_n.vreg[1]) ? (vreg_read_data_i[1]) : (rs2_val_q);
        rs3_val_n = (exe_state_n.vreg[2]) ? (vreg_read_data_i[2]) : (rs3_val_q);

        // save read data when new entry comes
        if (dispatch_valid_i) begin
            rs1_val_n = (exe_state_n.vreg[0]) ? (vreg_read_data_i[0]) : ({{32{dispatch_entry_i.rs1.xval[31]}}, dispatch_entry_i.rs1.xval});
            rs2_val_n = (exe_state_n.vreg[1]) ? (vreg_read_data_i[1]) : ({{32{dispatch_entry_i.rs2.xval[31]}}, dispatch_entry_i.rs2.xval});
            rs3_val_n = (exe_state_n.vreg[2]) ? (vreg_read_data_i[2]) : (64'd0);
        end
    end

    // set up register write back
    always_comb begin
        vreg_write_en_o   = 1'b0;
        vreg_write_addr_o = 5'd0;
        vreg_write_bweb_o = (VLEN/8)'(0);
        vreg_write_data_o = VLEN'(0);

        if (lane_result_valid && ~lane_done) begin
            vreg_write_en_o   = 1'b1;
            vreg_write_addr_o = lane_result_addr;
            vreg_write_bweb_o = lane_result_bweb;
            vreg_write_data_o = lane_result_data;
        end

        if (lsu_result_valid && ~lsu_done) begin
            vreg_write_en_o   = 1'b1;
            vreg_write_addr_o = lsu_result_addr;
            vreg_write_bweb_o = lsu_result_bweb;
            vreg_write_data_o = lsu_result_data;
        end

        if (sld_result_valid && ~sld_done) begin
            vreg_write_en_o   = 1'b1;
            vreg_write_addr_o = sld_result_addr;
            vreg_write_bweb_o = sld_result_bweb;
            vreg_write_data_o = sld_result_data;
        end

        if (elem_result_valid && ~elem_done) begin
            vreg_write_en_o   = 1'b1;
            vreg_write_addr_o = elem_result_addr;
            vreg_write_bweb_o = elem_result_bweb;
            vreg_write_data_o = elem_result_data;
        end

        if (mask_result_valid && ~mask_done) begin
            vreg_write_en_o   = 1'b1;
            vreg_write_addr_o = mask_result_addr;
            vreg_write_bweb_o = mask_result_bweb;
            vreg_write_data_o = mask_result_data;
        end
    end

    // --------------------------------------------
    //                     Lane                    
    // --------------------------------------------
    VPU_lane_wrapper i_VPU_lane_wrapper (
        .clk_i,
        .rst_i,

        // execute handshake
        .valid_i        ( lane_valid           ),
        .fu_i           ( exe_state_q.fu       ),
        .mode_i         ( exe_state_q.mode     ),
        .vl_i           ( exe_state_q.vl       ),
        .vl_count_i     ( vl_count_q           ),
        .vl_update_o    ( lane_vl_update       ),
        .vsew_i         ( exe_state_q.eew      ),
        .vxrm_i         ( exe_state_q.vxrm     ),
        .rd_addr_i      ( exe_state_q.rd_index ),
        .done_o         ( lane_done            ),

        // input operand source
        .use_vreg_i     ( exe_state_q.vreg     ),
        .rs1_val_i      ( rs1_val_q            ),
        .rs2_val_i      ( rs2_val_q            ),
        .rs3_val_i      ( rs3_val_q            ),
        .vreg_v0_i      ( vreg_v0_i            ),

        // output result
        .result_valid_o ( lane_result_valid    ),
        .result_addr_o  ( lane_result_addr     ),
        .result_data_o  ( lane_result_data     ),
        .result_bweb_o  ( lane_result_bweb     )
    );

    // --------------------------------------------
    //                     VLSD                    
    // --------------------------------------------
    // generate whole mask
    VPU_sld i_VPU_sld (
        .clk_i,
        .rst_i,

        .valid_i         ( sld_valid              ),
        .vsld_ctrl_i     ( exe_state_q.mode.sld   ),
        .vl_i            ( exe_state_q.vl         ),
        .vl_count_i      ( vl_count_q             ),
        .vl_update_o     ( sld_vl_update          ),
        .vsew_i          ( exe_state_q.eew        ),
        .lmul_i          ( exe_state_q.emul       ),
        .rs2_addr_i      ( exe_state_q.rs2_index  ),
        .rd_addr_i       ( exe_state_q.rd_index   ),
        .done_o          ( sld_done               ),

        // input operand source
        .offset_i        ( rs1_val_q[VL_BITS-1:0] ),
        .rs1_val_i       ( rs1_val_q              ),
        .rs2_val_i       ( rs2_val_q              ),
        .rs2_read_addr_o ( sld_rs2_read_addr      ),

        // output result
        .result_valid_o  ( sld_result_valid       ),
        .result_addr_o   ( sld_result_addr        ),
        .result_data_o   ( sld_result_data        ),
        .result_bweb_o   ( sld_result_bweb        )
    );

    // --------------------------------------------
    //                    VELME                    
    // --------------------------------------------
    VPU_elem i_VPU_elem (
        .clk_i,
        .rst_i,

        .valid_i         ( elem_valid             ),
        .velem_ctrl_i    ( exe_state_q.mode.elem  ),
        .vl_i            ( exe_state_q.vl         ),
        .vl_count_i      ( vl_count_q             ),
        .vl_update_o     ( elem_vl_update         ),
        .vsew_i          ( exe_state_q.eew        ),
        .lmul_i          ( exe_state_q.emul       ),
        .rs2_addr_i      ( exe_state_q.rs2_index  ),
        .rd_addr_i       ( exe_state_q.rd_index   ),
        .done_o          ( elem_done              ),

        // input operand source
        .rs1_val_i       ( rs1_val_q              ),
        .rs2_val_i       ( rs2_val_q              ),
        .rs2_read_addr_o ( elem_rs2_read_addr     ),

        // output result
        .result_valid_o  ( elem_result_valid      ),
        .result_addr_o   ( elem_result_addr       ),
        .result_data_o   ( elem_result_data       ),
        .result_bweb_o   ( elem_result_bweb       )
    );

    // --------------------------------------------
    //          VMASK (finish in one cycle)        
    // --------------------------------------------
    // generate whole mask
    VPU_mask i_VPU_mask (
        .valid_i        ( mask_valid            ),
        .vmask_ctrl_i   ( exe_state_q.mode.mask ),
        .vl_i           ( exe_state_q.vl        ),
        .vl_count_i     ( vl_count_q            ),
        .vl_update_o    ( mask_vl_update        ),
        .rd_addr_i      ( exe_state_q.rd_index  ),
        .done_o         ( mask_done             ),

        // input operand source
        .rs1_val_i      ( rs1_val_q             ),
        .rs2_val_i      ( rs2_val_q             ),

        // output result
        .result_valid_o ( mask_result_valid     ),
        .result_addr_o  ( mask_result_addr      ),
        .result_data_o  ( mask_result_data      ),
        .result_bweb_o  ( mask_result_bweb      )
    );

    // --------------------------------------------
    //                    VLSU                     
    // --------------------------------------------
    VPU_lsu i_VPU_lsu (
        .clk_i,
        .rst_i,

        .valid_i          ( lsu_valid            ),
        .mode_i           ( exe_state_q.mode.lsu ),
        .vl_i             ( exe_state_q.vl       ),
        .vl_count_i       ( vl_count_q           ),
        .vl_update_o      ( lsu_vl_update        ),
        .done_o           ( lsu_done             ),

        .base_address_i   ( rs1_val_q[31:0]      ),
        .address_offset_i ( rs2_val_q            ),
        .stride_i         ( rs2_val_q[31:0]      ),
        .mask_i           ( vreg_v0_i            ),
        .store_data_i     ( rs3_val_q            ),

        // output result
        .rd_addr_i        ( exe_state_q.rd_index ),
        .result_valid_o   ( lsu_result_valid     ),
        .result_addr_o    ( lsu_result_addr      ),
        .result_data_o    ( lsu_result_data      ),
        .result_bweb_o    ( lsu_result_bweb      ),

        // request to D$
        .dcache_vpu_request_o,
        .dcache_vpu_write_o,
        .dcache_vpu_addr_o,
        .dcache_vpu_in_o,

        // response from D$
        .dcache_vpu_wait_i,
        .dcache_vpu_out_i
    );


endmodule