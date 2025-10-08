module VPU_issue_stage (
    input  logic     clk_i,
    input  logic     rst_i,

    // from VPU decoder
    input  logic     decode_entry_valid_i,
    input  VPU_uOP_t decode_entry_i,
    output logic     decode_ack_o,

    // to VCFG unit
    output logic     VCFG_valid_o,
    output VPU_uOP_t VCFG_entry_o,

    // to EXE
    output logic     dispatch_valid_o,
    output VPU_uOP_t dispatch_entry_o,
    input  logic     dispatch_ready_i
);

    // --------------------------------------------
    //              Signal Declaration             
    // --------------------------------------------
    // instruction queue
    logic     decode_accept;
    
    // to Vector DISP
    logic     dispatch_entry_valid;
    VPU_uOP_t dispatch_entry;
    logic     dispatch_ack;

    // --------------------------------------------
    //     Vector CSRs instructions issue logic    
    // --------------------------------------------
    // CSR Instruction Issue Mechanism:
    // ---------------------------------
    // Control and Status Register (CSR) instructions are designed to bypass
    // the instruction queue entirely. After being decoded, these instructions
    // are directly issued to the execution unit (VCFG) without entering the queue.
    // CSR Instruction include : zicsr and vset[i]vl[i]
    always_comb begin
        VCFG_valid_o = 1'b0;
        VCFG_entry_o = VPU_uOP_t'(0);

        if (decode_entry_valid_i && decode_entry_i.fu == VCFG) begin
            VCFG_valid_o = 1'b1;
            VCFG_entry_o = decode_entry_i;
        end
    end

    // --------------------------------------------
    //            VPU instruction queue            
    // --------------------------------------------
    assign decode_ack_o = decode_accept;

    VPU_instruction_queue i_VPU_instruction_queue (
        .clk_i,
        .rst_i,

        .decode_entry_valid_i,
        .decode_entry_i,
        .decode_accept_o        ( decode_accept        ),

        .dispatch_entry_valid_o ( dispatch_entry_valid ),
        .dispatch_entry_o       ( dispatch_entry       ),
        .dispatch_ack_i         ( dispatch_ack         )
    );

    // --------------------------------------------
    //               VPU issue logic               
    // --------------------------------------------
    always_comb begin
        dispatch_ack     = 1'b0;
        dispatch_valid_o = 1'b0;
        dispatch_entry_o = dispatch_entry;

        // dispatch entry and execute stage handshake
        if (dispatch_entry_valid && dispatch_ready_i) begin
            dispatch_ack     = 1'b1;
            dispatch_valid_o = 1'b1;
        end
    end

endmodule