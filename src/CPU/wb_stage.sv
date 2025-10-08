module wb_stage (
    input  logic        clk_i,
    input  logic        rst_i,

    // control signal
    input  logic        waiting_i,
    output logic        trap_valid_o,
    output logic        interrupt_taken_o,
    input  logic        wfi_i,
    input  logic        mret_i,
    input  logic [31:0] exe_pc_i,

    // external interrupt
    input  logic        mei_i,
    input  logic        mti_i,

    // control flow
    output logic [31:0] mepc_o,
    output logic [31:0] mtvec_o,

    // from MEM
    input  uOP_t        wb_uOP_i,
    input  logic [31:0] wb_csr_operand_i,

    // register writeback
    output logic        wb_rd_web_o,
    output logic        wb_frd_web_o,
    output REG_t        wb_rd_o,
    output logic [31:0] wb_data_o
);

    // --------------------------------------------
    //              Signal Declaration             
    // --------------------------------------------
    logic [31:0] csr_data, csr_data_reg, ld_data;

    // --------------------------------------------
    //                     CSRs                    
    // --------------------------------------------
    csr i_csr(
        .clk_i,
        .rst_i,

        // control signal
        .waiting_i,
        .trap_valid_o,
        .interrupt_taken_o,
        .wfi_i,
        .mret_i,

        // external interrupt
        .mei_i,
        .mti_i,

        // control flow
        .mtvec_o,
        .mepc_o,

        // from WB
        .valid_i       ( wb_uOP_i.valid        ),
        .pc_i          ( exe_pc_i              ),
        .op_i          ( wb_uOP_i.op           ),
        .csr_operand_i ( wb_csr_operand_i      ),
        .csr_addr_i    ( wb_uOP_i.result[11:0] ),
        .csr_data_o    ( csr_data              )
    );

    always_ff @(posedge clk_i) begin
        if      (rst_i)           csr_data_reg <= 32'd0;
        else if (!wb_uOP_i.valid) csr_data_reg <= csr_data_reg;
        else                      csr_data_reg <= csr_data;
    end

    // --------------------------------------------
    //               Load Data Filter              
    // --------------------------------------------
    always_comb begin
        unique case (wb_uOP_i.op)
            _LB     : ld_data = { {24{wb_uOP_i.result[ 7]}} , wb_uOP_i.result[ 7:0]};
            _LH     : ld_data = { {16{wb_uOP_i.result[15]}} , wb_uOP_i.result[15:0]};
            _LW     : ld_data = wb_uOP_i.result;
            _LBU    : ld_data = { 24'b0 , wb_uOP_i.result[ 7:0] };
            _LHU    : ld_data = { 16'b0 , wb_uOP_i.result[15:0] };
            default : ld_data = 32'd0;
        endcase
    end

    // --------------------------------------------
    //               Output Assignment             
    // --------------------------------------------
    always_comb begin
        wb_rd_web_o  = wb_uOP_i.valid & (|wb_uOP_i.rd) & (~wb_uOP_i.use_fpr[0]);
        wb_frd_web_o = wb_uOP_i.valid & wb_uOP_i.use_fpr[0];
        wb_rd_o      = wb_uOP_i.rd;

        if      ( !wb_uOP_i.valid && wb_uOP_i.fu == CSR ) wb_data_o = csr_data_reg;
        else if ( wb_uOP_i.fu == CSR                    ) wb_data_o = csr_data;
        else if ( wb_uOP_i.fu == GLSU                   ) wb_data_o = ld_data;
        else                                              wb_data_o = wb_uOP_i.result;
    end

endmodule