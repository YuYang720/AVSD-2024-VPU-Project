module VPU_instruction_queue (
    input  logic     clk_i,
    input  logic     rst_i,

    // from VPU decoder
    input  logic     decode_entry_valid_i,
    input  VPU_uOP_t decode_entry_i,
    output logic     decode_accept_o,

    // to VPU DISP
    output logic     dispatch_entry_valid_o,
    output VPU_uOP_t dispatch_entry_o,
    input  logic     dispatch_ack_i
);

    // --------------------------------------------
    //              Signal Declaration             
    // --------------------------------------------
    // vector instruction queue
    VIQ_ENTRY_t              VIQ[VIQ_DEPTH];
    logic                    viq_full, viq_push, viq_pop;
    logic [VIQ_TAG_BITS  :0] viq_size_q, viq_size_n;
    logic [VIQ_TAG_BITS-1:0] top_ptr_q, top_ptr_n;
    logic [VIQ_TAG_BITS-1:0] dispatch_ptr_q, dispatch_ptr_n;

    // --------------------------------------------
    //    Vector Instruction Queue (FIFO pointer)  
    // --------------------------------------------
    assign viq_full               = (viq_size_q == (VIQ_TAG_BITS+1)'(VIQ_DEPTH));
    assign decode_accept_o        = viq_push;
    assign dispatch_entry_valid_o = VIQ[dispatch_ptr_q].valid;
    assign dispatch_entry_o       = VIQ[dispatch_ptr_q].uOP;

    always_comb begin
        viq_size_n     = viq_size_q;
        top_ptr_n      = top_ptr_q;
        dispatch_ptr_n = dispatch_ptr_q;
        viq_push       = 1'b0;
        viq_pop        = 1'b0;

        // top pointer update
        // we do not push config instruction into queue
        // we execute it after decode
        if (decode_entry_valid_i && decode_entry_i.fu != VCFG && ~viq_full) begin
            viq_push  = 1'b1;
            top_ptr_n = top_ptr_q + VIQ_TAG_BITS'(1);
        end

        // dispatch pointer update
        if (dispatch_ack_i) begin
            viq_pop        = 1'b1;
            dispatch_ptr_n = dispatch_ptr_q + VIQ_TAG_BITS'(1);
        end

        // instruction queue size update
        unique case ({viq_push, viq_pop})
            2'b01   : viq_size_n = viq_size_q - (VIQ_TAG_BITS+1)'(1);
            2'b10   : viq_size_n = viq_size_q + (VIQ_TAG_BITS+1)'(1);
            default : ; // nothing to do
        endcase
    end

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            viq_size_q     <= (VIQ_TAG_BITS+1)'(0);
            top_ptr_q      <= VIQ_TAG_BITS'(0);
            dispatch_ptr_q <= VIQ_TAG_BITS'(0);
        end else begin
            viq_size_q     <= viq_size_n;
            top_ptr_q      <= top_ptr_n;
            dispatch_ptr_q <= dispatch_ptr_n;
        end
    end

    // --------------------------------------------
    //          Instruction Queue (Memory)         
    // --------------------------------------------
    always_ff @(posedge clk_i) begin
        if (rst_i) begin

            foreach (VIQ[i]) begin
                VIQ[i].valid <= 1'b0;
                VIQ[i].uOP   <= VPU_uOP_t'(0);
            end

        end else begin
            // insert new instruction into IQ when valid and IQ is not full
            if (viq_push) begin
                VIQ[top_ptr_q].valid <= 1'b1;
                VIQ[top_ptr_q].uOP   <= decode_entry_i;
            end

            // if the decode entry is ack, then the instruction is now in decode stage
            // so the entry is no longer valid and can be replaced
            if (viq_pop) begin
                VIQ[dispatch_ptr_q].valid <= 1'b0;
                VIQ[dispatch_ptr_q].uOP   <= VPU_uOP_t'(0); // may delete this line
            end
        end
    end

endmodule