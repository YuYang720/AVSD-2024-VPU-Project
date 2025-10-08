module mem_stage (
    input  logic        clk_i,
    input  logic        rst_i,

    // control signal
    output logic        stall_o,
    input  logic        flush_i,

    // from EXE
    input  uOP_t        mem_uOP_i,
    input  logic [31:0] mem_mul_result_i,
    input  logic [31:0] mem_csr_operand_i,
    
    // response from D$
    input  logic        dcache_core_wait_i,
    input  logic [31:0] dcache_core_out_i,
    
    // to WB
    output uOP_t        wb_uOP_o,
    output logic [31:0] wb_csr_operand_o,

    // VPU writeback xreg
    input  logic        vector_lsu_valid_i,
    input  logic        vector_result_valid_i,
    input  logic [31:0] vector_result_i
);

    // --------------------------------------------
    //              Signal Declaration             
    // --------------------------------------------
    // load data alignment
    logic [31:0] ld_align;

    // pipeline register
    uOP_t        uOP_q, uOP_n;
    logic [31:0] csr_operand_q;

    // --------------------------------------------
    //           MEM/WB Pipeline Registers         
    // --------------------------------------------
    assign stall_o          = (~uOP_n.valid & uOP_n.fu != NONE);
    assign wb_uOP_o         = uOP_q;
    assign wb_csr_operand_o = csr_operand_q;
    
    always_comb begin
        uOP_n    = mem_uOP_i;
        ld_align = dcache_core_out_i >> mem_uOP_i.result;

        unique case (mem_uOP_i.fu)
            GLSU    : {uOP_n.valid, uOP_n.result} = {~dcache_core_wait_i, ld_align};
            GMUL    : {uOP_n.valid, uOP_n.result} = {1'b1, mem_mul_result_i       };
            default : ; // nothing to do
        endcase

        // VPU writeback :
        // If a write-back or mem request is required (~mem_uOP_i.valid)
        // the value of uOP_n.valid will depend on vector_result_valid_i.
        if (mem_uOP_i.fu == VPU && ~mem_uOP_i.valid) begin
            uOP_n.valid  = vector_result_valid_i | vector_lsu_valid_i;
            uOP_n.result = vector_result_i;
        end
    end

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            uOP_q         <= uOP_t'(0);
            csr_operand_q <= 32'd0;
        end else if (flush_i) begin
            uOP_q         <= uOP_t'(0);
            csr_operand_q <= 32'd0;
        end else if (!stall_o) begin
            uOP_q         <= uOP_n;
            csr_operand_q <= mem_csr_operand_i;
        end else begin 
            uOP_q         <= uOP_q; // keep wb_uOP the same
            uOP_q.valid   <= 1'b0;  // but invalidate the result
            csr_operand_q <= csr_operand_q;
        end
    end

endmodule