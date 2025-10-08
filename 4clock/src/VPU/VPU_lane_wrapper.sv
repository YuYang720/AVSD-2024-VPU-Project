module VPU_lane_wrapper (
    input  logic               clk_i,
    input  logic               rst_i,

    // execute control
    input  logic               valid_i,
    input  VPU_FU_t            fu_i,
    input  VPU_MODE_t          mode_i,
    input  logic [VL_BITS-1:0] vl_i,
    input  logic [VL_BITS-1:0] vl_count_i,
    output logic [VL_BITS-1:0] vl_update_o,
    input  VSEW_e              vsew_i,
    input  VXRM_e              vxrm_i,
    input  logic [4:0]         rd_addr_i,
    output logic               done_o,

    // input operand source
    input  logic [2:0]         use_vreg_i,
    input  logic [VLEN-1:0]    rs1_val_i,
    input  logic [VLEN-1:0]    rs2_val_i,
    input  logic [VLEN-1:0]    rs3_val_i,
    input  logic [VLEN-1:0]    vreg_v0_i,

    // output result
    output logic               result_valid_o,
    output logic [4:0]         result_addr_o,
    output logic [VLEN/8-1:0]  result_bweb_o,
    output logic [VLEN-1:0]    result_data_o
);

    // --------------------------------------------
    //              Signal Declaration             
    // --------------------------------------------
    typedef struct packed {
        logic        valid;        // lane valid signal
        logic [63:0] operand1;     // operand from source register 1 (max 64-bit)
        logic [63:0] operand2;     // operand from source register 2 (max 64-bit)
        logic [63:0] operand3;     // operand from dest   register   (max 64-bit)
        logic        mask;         // mask value for this lane
        logic        result_valid; // the result is valid right now
        logic        result_en;    // if we need to writeback the result
        logic [63:0] result;       // execution result of each lane
    } lane_info_t;

    // lane installation
    lane_info_t lane_info[8];      // the infomation of each lane
    logic       vd_mask  [8];      // the mask of vd
    logic       result_mask;       // if the result is a mask
    logic [4:0] rd_offset, rd_offset_q;

    // --------------------------------------------
    //              Lane operand select            
    // --------------------------------------------
    assign done_o = valid_i && (vl_count_i == vl_i) && ~(lane_info[0].result_valid);

    always_comb begin
        // default values: all lanes are disabled and operands are zeroed
        for (int i = 0; i < 8; i++) begin
            lane_info[i].valid    = 1'b0;   // disable all lanes by default
            lane_info[i].operand1 = 64'd0;  // default value for rs1
            lane_info[i].operand2 = 64'd0;  // default value for rs2
            lane_info[i].operand3 = 64'd0;  // default value for rs3 (rd)
            lane_info[i].mask     = 1'b0;   // default value for mask
            vd_mask  [i]          = 1'b0;
        end

        if (valid_i) begin
            // assign values based on sew and vl
            case (vsew_i)
                // for sew = 8, enable all lanes and assign 8-bit operands
                VSEW_8 : begin
                    for (int i = 0; i < 8; i++) begin
                        lane_info[i].valid    = (i + {(32-VL_BITS)'(0), vl_count_i} < {(32-VL_BITS)'(0), vl_i});   // enable lanes within vl
                        lane_info[i].operand1 = {56'd0, rs1_val_i[i*8 +: 8]};       // extract 8-bit rs1
                        lane_info[i].operand2 = {56'd0, rs2_val_i[i*8 +: 8]};       // extract 8-bit rs2
                        lane_info[i].operand3 = {56'd0, rs3_val_i[i*8 +: 8]};       // extract 8-bit rs3
                        lane_info[i].mask     = vreg_v0_i[i + {(32-VL_BITS)'(0), vl_count_i}]; // extract mask v0[7:0]
                        vd_mask  [i]          = rs3_val_i[i + {(32-VL_BITS)'(0), vl_count_i}]; // the mask value in rd
                    end
                end

                // for sew = 16, enable up to 4 lanes and assign 16-bit operands
                VSEW_16 : begin
                    for (int i = 0; i < 4; i++) begin
                        lane_info[i].valid    = (i + {(32-VL_BITS)'(0), vl_count_i} < {(32-VL_BITS)'(0), vl_i});   // enable lanes within vl
                        lane_info[i].operand1 = {48'd0, rs1_val_i[i*16 +: 16]};     // extract 16-bit rs1
                        lane_info[i].operand2 = {48'd0, rs2_val_i[i*16 +: 16]};     // extract 16-bit rs2
                        lane_info[i].operand3 = {48'd0, rs3_val_i[i*16 +: 16]};     // extract 16-bit rs3
                        lane_info[i].mask     = vreg_v0_i[i + {(32-VL_BITS)'(0), vl_count_i}]; // extract mask v0[3:0]
                        vd_mask  [i]          = rs3_val_i[i + {(32-VL_BITS)'(0), vl_count_i}]; // the mask value in rd
                    end
                end

                // for sew = 32, enable up to 2 lanes and assign 32-bit operands
                VSEW_32 : begin
                    for (int i = 0; i < 2; i++) begin
                        lane_info[i].valid    = (i + {(32-VL_BITS)'(0), vl_count_i} < {(32-VL_BITS)'(0), vl_i});   // enable lanes within vl
                        lane_info[i].operand1 = {32'd0, rs1_val_i[i*32 +: 32]};     // extract 32-bit rs1
                        lane_info[i].operand2 = {32'd0, rs2_val_i[i*32 +: 32]};     // extract 32-bit rs2
                        lane_info[i].operand3 = {32'd0, rs3_val_i[i*32 +: 32]};     // extract 32-bit rs3
                        lane_info[i].mask     = vreg_v0_i[i + {(32-VL_BITS)'(0), vl_count_i}]; // extract mask v0[1:0]
                        vd_mask  [i]          = rs3_val_i[i + {(32-VL_BITS)'(0), vl_count_i}]; // the mask value in rd
                    end
                end

                // for sew = 64, only the first lane is enabled and assigned 64-bit operands
                VSEW_64 : begin
                    for (int i = 0; i < 1; i++) begin
                        lane_info[i].valid    = (i + {(32-VL_BITS)'(0), vl_count_i} < {(32-VL_BITS)'(0), vl_i});   // enable the first lane if vl > 0
                        lane_info[i].operand1 = rs1_val_i[i*64 +: 64];     // extract 64-bit rs1
                        lane_info[i].operand2 = rs2_val_i[i*64 +: 64];     // extract 64-bit rs2
                        lane_info[i].operand3 = rs3_val_i[i*64 +: 64];     // extract 64-bit rs2
                        lane_info[i].mask     = vreg_v0_i[i + {(32-VL_BITS)'(0), vl_count_i}]; // extract mask v0[0]
                        vd_mask  [i]          = rs3_val_i[i + {(32-VL_BITS)'(0), vl_count_i}]; // the mask value in rd
                    end
                end

                default : ; // nothing to do
            endcase

            // id opernad use imme or xval as operand
            // --> all lane should be same value
            for (int i = 0; i < 8; i++) begin
                if (lane_info[i].valid && use_vreg_i[0] != 1'b1) begin
                    lane_info[i].operand1 = rs1_val_i;
                end

                if (lane_info[i].valid && use_vreg_i[1] != 1'b1) begin
                    lane_info[i].operand2 = rs2_val_i;
                end
            end
        end
    end

    // --------------------------------------------
    //                     Lane                    
    // --------------------------------------------
    generate
        for (genvar i = 0; i < 8; i++) begin : VPU_lane
            VPU_lane i_VPU_lane (
                .clk_i,
                .rst_i,
                .fu_i,
                .mode_i,
                .vsew_i,
                .vxrm_i,

                .valid_i        ( lane_info[i].valid        ),
                .operand1_i     ( lane_info[i].operand1     ),
                .operand2_i     ( lane_info[i].operand2     ),
                .operand3_i     ( lane_info[i].operand3     ),
                .mask_i         ( lane_info[i].mask         ),

                .result_valid_o ( lane_info[i].result_valid ),
                .result_en_o    ( lane_info[i].result_en    ),
                .result_o       ( lane_info[i].result       )
            );
        end
    endgenerate

    // --------------------------------------------
    //             Lane Result WriteBack           
    // --------------------------------------------
    always_ff @(posedge clk_i) begin
        if (rst_i) rd_offset_q <= 5'd0;
        else       rd_offset_q <= rd_offset;
    end

    always_comb begin
        rd_offset = 5'd0;
    
        unique case (vsew_i)
            VSEW_8  : rd_offset = vl_count_i >> 5'd3;
            VSEW_16 : rd_offset = vl_count_i >> 5'd2;
            VSEW_32 : rd_offset = vl_count_i >> 5'd1;
            VSEW_64 : rd_offset = vl_count_i[4:0];
            default : ;
        endcase

        result_valid_o = lane_info[0].result_valid;
        result_addr_o  = rd_addr_i + rd_offset;
        result_bweb_o  = (VLEN/8)'(0);
        result_data_o  = VLEN'(0);
        vl_update_o    = VL_BITS'(8) >> vsew_i;
        result_mask    = fu_i == VALU && mode_i.alu.mask_res;

        if (fu_i == VMUL) begin
            result_addr_o = rd_addr_i + rd_offset_q;
        end

        unique case (vsew_i)
            VSEW_8 : begin
                for (int i = 0; i < 8; i++) begin
                    if (result_mask) begin
                        result_data_o[i + {(32-VL_BITS)'(0), vl_count_i}] = (lane_info[i].result_valid) ? (vd_mask[i + {(32-VL_BITS)'(0), vl_count_i}]) : (lane_info[i].result[0]);
                        result_bweb_o = 8'd1 << (vl_count_i >> 3); // move to left when 
                    end else if (lane_info[i].result_valid && lane_info[i].result_en) begin
                        result_data_o[i*8 +: 8] = lane_info[i].result[7:0];
                        result_bweb_o[i]        = 1'b1;
                    end
                end
            end

            VSEW_16 : begin
                for (int i = 0; i < 4; i++) begin
                    if (result_mask) begin
                        result_data_o[i + {(32-VL_BITS)'(0), vl_count_i}] = (lane_info[i].result_valid) ? (vd_mask[i + {(32-VL_BITS)'(0), vl_count_i}]) : (lane_info[i].result[0]);
                        result_bweb_o = 8'd1 << (vl_count_i >> 3);
                    end else if (lane_info[i].result_valid && lane_info[i].result_en) begin
                        result_data_o[i*16 +: 16] = lane_info[i].result[15:0];
                        result_bweb_o[i*2  +:  2] = 2'b11;
                    end
                end
            end

            VSEW_32 : begin
                for (int i = 0; i < 2; i++) begin
                    if (result_mask) begin
                        result_data_o[i + {(32-VL_BITS)'(0), vl_count_i}] = (lane_info[i].result_valid) ? (vd_mask[i + {(32-VL_BITS)'(0), vl_count_i}]) : (lane_info[i].result[0]);
                        result_bweb_o = 8'd1 << (vl_count_i >> 3);
                    end else if (lane_info[i].result_valid && lane_info[i].result_en) begin
                        result_data_o[i*32 +: 32] = lane_info[i].result[31:0];
                        result_bweb_o[i*4  +:  4] = 4'b1111;
                    end
                end
            end

            VSEW_64 : begin
                for (int i = 0; i < 1; i++) begin
                    if (result_mask) begin
                        result_data_o[i + {(32-VL_BITS)'(0), vl_count_i}] = (lane_info[i].result_valid) ? (vd_mask[i + {(32-VL_BITS)'(0), vl_count_i}]) : (lane_info[i].result[0]);
                        result_bweb_o = 8'd1 << (vl_count_i >> 3);
                    end else if (lane_info[i].result_valid && lane_info[i].result_en) begin
                        result_data_o[i*64 +: 64] = lane_info[i].result[63:0];
                        result_bweb_o[i*8  +:  8] = 8'b11111111;
                    end
                end
            end

            default : ; // nothing to do
        endcase
    end

endmodule