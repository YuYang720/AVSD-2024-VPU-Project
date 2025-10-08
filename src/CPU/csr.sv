module csr (
    input  logic        clk_i,
    input  logic        rst_i,

    // control siganl
    input  logic        waiting_i,
    output logic        trap_valid_o,
    output logic        interrupt_taken_o,
    input  logic        wfi_i,
    input  logic        mret_i,
    
    // external interrupt
    input  logic        mei_i,
    input  logic        mti_i,

    // control flow
    output logic [31:0] mtvec_o,
    output logic [31:0] mepc_o,

    // from WB
    input  logic        valid_i,
    input  OPERATOR_t   op_i,
    input  logic [31:0] pc_i,
    input  logic [31:0] csr_operand_i,
    input  logic [11:0] csr_addr_i,
    output logic [31:0] csr_data_o
);

    // --------------------------------------------
    //              Signal Declaration             
    // --------------------------------------------
    logic [63:0] mcycle, minstret;
    logic [31:0] mstatus, mtvec, mip, mie, mepc;
    logic [31:0] read_data, write_data;
    logic        trap_valid, interrupt_taken;
    logic        wfi, mret;

    // --------------------------------------------
    //                CSRs operation               
    // --------------------------------------------
    assign interrupt_taken = |(mip & mie);
    assign trap_valid      = mstatus[`MIE] & interrupt_taken;
    
    always_comb begin
        unique case (op_i)
            _CSRRW  : write_data = csr_operand_i;
            _CSRRS  : write_data = read_data | csr_operand_i;
            _CSRRC  : write_data = read_data & (~csr_operand_i);
            default : write_data = read_data;
        endcase
    end

    // --------------------------------------------
    //                Machine Status               
    // --------------------------------------------

    always_ff @(posedge clk_i) begin
        if (rst_i) mstatus <= 32'd0;
        else begin

            priority if (trap_valid) begin
                // Trap occurs
                mstatus[`MIE ] <= 1'b0;
                mstatus[`MPIE] <= mstatus[`MIE];
                mstatus[`MPP ] <= 2'b11; // machine mode

            end else if (mret_i) begin
                // return from trap
                mstatus[`MIE ] <= mstatus[`MPIE];
                mstatus[`MPIE] <= 1'b1;
                mstatus[`MPP ] <= 2'b11; // machine mode

            end else if (valid_i & csr_addr_i[11:0] == CSR_MSTATUS) begin
                // Write mstatus
                mstatus[`MIE ] <= write_data[`MIE ];
                mstatus[`MPIE] <= write_data[`MPIE];
                mstatus[`MPP ] <= write_data[`MPP ];

            end else begin
                // keep the result
                mstatus[`MIE ] <= mstatus[`MIE ];
                mstatus[`MPIE] <= mstatus[`MPIE];
                mstatus[`MPP ] <= mstatus[`MPP ];
            end

            // not implemented: hardwire to zero
            mstatus[31:13] <= 19'd0;
            mstatus[10: 8] <= 3'd0;
            mstatus[ 6: 4] <= 3'd0;
            mstatus[ 2: 0] <= 3'd0;
        end
    end

    // --------------------------------------------
    //       Machine trap-vector base-address      
    // --------------------------------------------
    assign mtvec = 32'h0001_0000; // hardwire
    
    // --------------------------------------------
    // Machine interrupt-pending & interrupt-enable
    // --------------------------------------------
    always_ff @(posedge clk_i) begin
        if (rst_i) mie <= 32'd0;
        else begin

            if(valid_i && csr_addr_i == CSR_MIE) begin
                mie[`MEIE] <= write_data[`MEIP];
                mie[`MTIE] <= write_data[`MTIP];
            end

            // not implemented: hardwired to zero
            mie[31:12] <= 20'd0;
            mie[10: 8] <= 3'd0;
            mie[ 6: 0] <= 7'd0;
        end
    end

    // Connect to external/timer interrupt signal
    // --> Need to check MEIE/MTIE value
    assign mip[`MEIP] = mie[`MEIE] & mei_i;
    assign mip[`MTIP] = mie[`MTIE] & mti_i;
    // not implemented: hardwired to zero
    assign mip[31:12] = 20'd0;
    assign mip[10: 8] = 3'd0;
    assign mip[ 6: 0] = 7'd0;

    // --------------------------------------------
    //      Machine exception program counter      
    // --------------------------------------------
    always_ff @(posedge clk_i) begin
        if (rst_i) mepc <= 32'd0;
        else begin

            priority if (trap_valid) begin
                mepc <= (waiting_i) ? (pc_i + 32'd4) : (pc_i);
            end else if (valid_i & csr_addr_i == CSR_MEPC) begin
                mepc <= write_data;
            end else begin
                mepc <= mepc;
            end

        end
    end

    // --------------------------------------------
    //             Performance Counters            
    // --------------------------------------------
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            mcycle   <= 64'd0;
            minstret <= 64'd0;
        end else begin
            mcycle   <= mcycle   + 64'd1;
            minstret <= minstret + {63'd0, valid_i};
        end
    end

    final begin
        real ipc = 0.0;
        if (mcycle != 0) begin
            ipc = (real'(minstret) * 1.0 / real'(mcycle));
        end
        $display("Total Instruction Count = %0d", minstret);
        $display("Total Cycle       Count = %0d", mcycle);
        $display("IPC                     = %0.2f", ipc);
    end

    // --------------------------------------------
    //                   CSR Read                  
    // --------------------------------------------
    always_comb begin
        unique case (csr_addr_i)
            CSR_MSTATUS   : read_data = mstatus;
            CSR_MIE       : read_data = mie;
            CSR_MTVEC     : read_data = mtvec;
            CSR_MEPC      : read_data = mepc;
            CSR_MIP       : read_data = mip;
            CSR_MCYCLE    : read_data = mcycle  [31: 0];
            CSR_MCYCLEH   : read_data = mcycle  [63:32];
            CSR_MINSTRET  : read_data = minstret[31: 0];
            CSR_MINSTRETH : read_data = minstret[63:32];
            default       : read_data = 32'd0;
        endcase
    end

    // --------------------------------------------
    //               Output Assignment             
    // --------------------------------------------
    assign trap_valid_o      = trap_valid;
    assign interrupt_taken_o = interrupt_taken;
    assign csr_data_o        = read_data;
    assign mtvec_o           = mtvec;
    assign mepc_o            = mepc;

endmodule