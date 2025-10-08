module VPU_mask (
    // execute control
    input  logic               valid_i,
    input  VMASK_OP_t          vmask_ctrl_i,
    input  logic [VL_BITS-1:0] vl_i,
    input  logic [VL_BITS-1:0] vl_count_i,
    output logic [VL_BITS-1:0] vl_update_o,
    input  logic [4:0]         rd_addr_i,
    output logic               done_o,

    // input operand source
    input  logic [VLEN-1:0]    rs1_val_i,
    input  logic [VLEN-1:0]    rs2_val_i,

    // output result
    output logic               result_valid_o,
    output logic [4:0]         result_addr_o,
    output logic [VLEN/8-1:0]  result_bweb_o,
    output logic [VLEN-1:0]    result_data_o
);

    // --------------------------------------------
    //              Signal Declaration             
    // --------------------------------------------
    logic [63:0] result;

    // --------------------------------------------
    //                   Calculate                 
    // --------------------------------------------
    always_comb begin
        result = 64'b0;

        // ------------------------------------------------
        // Note that the spec states:
        // > Mask elements past vl, the tail elements,
        // > are always updated with a tail-agnostic policy
        // ------------------------------------------------
        unique case (vmask_ctrl_i.op)
            VMAND    : result =   rs2_val_i & rs1_val_i;
            VMOR     : result =   rs2_val_i | rs1_val_i;
            VMXOR    : result =   rs2_val_i ^ rs1_val_i;
            VMNAND   : result = ~(rs2_val_i & rs1_val_i);
            VMNOR    : result = ~(rs2_val_i | rs1_val_i);
            VMXNOR   : result = ~(rs2_val_i ^ rs1_val_i);
            VMORNOT  : result =   rs2_val_i & ~rs1_val_i;
            VMANDNOT : result =   rs2_val_i | ~rs1_val_i;
            default  : ; // nothing to do
        endcase
    end

    // --------------------------------------------
    //                Result WriteBack             
    // --------------------------------------------
    assign done_o = valid_i && (vl_count_i == vl_i);

    always_comb begin
        result_valid_o = valid_i; // VMASK can alway finish in one cycle
        result_addr_o  = rd_addr_i;
        result_bweb_o  = 8'b11111111;
        result_data_o  = result;
        vl_update_o    = vl_i;
    end

endmodule