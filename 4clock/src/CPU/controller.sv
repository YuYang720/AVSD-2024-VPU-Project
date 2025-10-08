module controller (
    input  logic clk_i,
    input  logic rst_i,

    // control signal
    output logic booting_o,
    output logic waiting_o,
    output logic flush_if_o,
    output logic flush_id_o,
    output logic flush_exe_o,
    output logic flush_mem_o,

    // from CSR
    input  logic wfi_i,
    input  logic mret_i,
    input  logic trap_valid_i,
    input  logic interrupt_taken_i,

    // resolve branch
    input  logic btkn_i,
    input  logic BU_flush_i,

    // data hazard
    input  uOP_t id_uOP_i,
    input  uOP_t exe_uOP_i,
    input  uOP_t mem_uOP_i,
    input  uOP_t wb_uOP_i,
    output logic id_rs1_forward_o,
    output logic id_rs2_forward_o,
    output logic mem_rs1_forward_o,
    output logic mem_rs2_forward_o,
    output logic wb_rs1_forward_o,
    output logic wb_rs2_forward_o,
    output logic id_rs3_forward_o,
    output logic mem_rs3_forward_o,
    output logic wb_rs3_forward_o
);
    // --------------------------------------------
    //              Signal Declaration             
    // --------------------------------------------
    typedef enum logic [2:0] {
        BOOTING, OPERATING, WFI
    } CPU_STATE_t;

    CPU_STATE_t CPU_STATE_q, CPU_STATE_n;
    logic       bubble;
    REG_t       id_rs1 , id_rs2, id_rs3;
    REG_t       exe_rs1, exe_rs2, exe_rs3, exe_rd;
    REG_t       mem_rd , wb_rd;
    logic [3:0] id_use_fpr  , exe_use_fpr;
    logic       mem_use_frd , wb_use_frd;
    logic       id_use_rs1  , id_use_rs2, id_use_rs3;
    logic       exe_use_rs1 , exe_use_rs2, exe_use_rs3;
    logic       wb_use_rd   , mem_use_rd;
    logic       exe_use_load, exe_use_falu, exe_use_mul, exe_use_csr, exe_use_fpu, exe_use_vpu;
    
    logic       rs1_id_wb_same_type  , rs2_id_wb_same_type, rs3_id_wb_same_type;
    logic       rs1_id_wb_same_idx   , rs2_id_wb_same_idx , rs3_id_wb_same_idx ;
    
    logic       rs1_exe_wb_same_type , rs2_exe_wb_same_type, rs3_exe_wb_same_type;
    logic       rs1_exe_wb_same_idx  , rs2_exe_wb_same_idx , rs3_exe_wb_same_idx ;
    
    logic       rs1_exe_mem_same_type, rs2_exe_mem_same_type, rs3_exe_mem_same_type;
    logic       rs1_exe_mem_same_idx , rs2_exe_mem_same_idx , rs3_exe_mem_same_idx ;
    
    logic       rs1_id_exe_same_type , rs1_id_exe_same_idx, is_de_rs1_overlap;
    logic       rs2_id_exe_same_type , rs2_id_exe_same_idx, is_de_rs2_overlap;
    logic       rs3_id_exe_same_type , rs3_id_exe_same_idx, is_de_rs3_overlap;

    // --------------------------------------------
    //              CPU State Machine              
    // --------------------------------------------
    
    always_ff @(posedge clk_i) begin
        if  (rst_i) CPU_STATE_q <= BOOTING;
        else        CPU_STATE_q <= CPU_STATE_n;
    end

    always_comb begin
        CPU_STATE_n = CPU_STATE_q;

        case(CPU_STATE_q)
            BOOTING   : CPU_STATE_n = OPERATING;
            OPERATING : CPU_STATE_n = (wfi_i) ? (WFI) : (OPERATING);
            WFI       : CPU_STATE_n = (interrupt_taken_i) ? (OPERATING) : (WFI);
            default   : CPU_STATE_n = BOOTING;
        endcase
    end

    assign booting_o   = (CPU_STATE_q == BOOTING);
    assign waiting_o   = (CPU_STATE_q == WFI);
    assign flush_if_o  = trap_valid_i | mret_i | BU_flush_i;
    assign flush_id_o  = trap_valid_i | mret_i | BU_flush_i | bubble | waiting_o | wfi_i;
    assign flush_exe_o = trap_valid_i;
    assign flush_mem_o = trap_valid_i;

    // --------------------------------------------
    //              Data Hazard Detect             
    // --------------------------------------------

    /*
        Two types of Data Hazard : ID <-> WB and EXE <-> MEM, WB

        ** USE_FP = { RS1 (2), RS2 (1), RD (0) } **

        check 1. Is using RS : (|RS1 & ~USE_FP) & USE_FP -> also check x0
        check 2. Is using RD : (|RD  & ~USE_FP) & USE_FP -> may not need to check
        check 2. Is using same type of RS/RD (FP or INT)
        check 3. Is RS equals to RD
    */

    assign id_rs1      = id_uOP_i.rs1;
    assign id_rs2      = id_uOP_i.rs2;
    assign id_rs3      = id_uOP_i.rs3;
    assign id_use_fpr  = id_uOP_i.use_fpr;

    assign exe_rs1     = exe_uOP_i.rs1;
    assign exe_rs2     = exe_uOP_i.rs2;
    assign exe_rs3     = exe_uOP_i.rs3;
    assign exe_rd      = exe_uOP_i.rd;
    assign exe_use_fpr = exe_uOP_i.use_fpr;

    assign mem_rd      = mem_uOP_i.rd;
    assign mem_use_frd = mem_uOP_i.use_fpr[0];
    assign wb_rd       = wb_uOP_i.rd;
    assign wb_use_frd  = wb_uOP_i.use_fpr[0];
    
    assign id_use_rs1  = (|id_rs1 & ~id_use_fpr[2]) | id_use_fpr[2];
    assign id_use_rs2  = (|id_rs2 & ~id_use_fpr[1]) | id_use_fpr[1];
    assign id_use_rs3  = id_use_fpr[3];

    assign wb_use_rd   = (|wb_rd  & ~wb_use_frd   ) | wb_use_frd;
    assign mem_use_rd  = (|mem_rd & ~mem_use_frd  ) | mem_use_frd;

    always_comb begin : RAW_ID_WB
        rs1_id_wb_same_type = ~( id_use_fpr[2] ^ wb_use_frd);
        rs1_id_wb_same_idx  = (id_rs1 == wb_rd);
        id_rs1_forward_o    = (id_use_rs1) & (wb_use_rd) & (rs1_id_wb_same_type) & (rs1_id_wb_same_idx);

        rs2_id_wb_same_type = ~( id_use_fpr[1] ^ wb_use_frd);
        rs2_id_wb_same_idx  = (id_rs2 == wb_rd);
        id_rs2_forward_o    = (id_use_rs2) & (wb_use_rd) & (rs2_id_wb_same_type) & (rs2_id_wb_same_idx);

        rs3_id_wb_same_type = ~( id_use_fpr[3] ^ wb_use_frd);
        rs3_id_wb_same_idx  = (id_rs3 == wb_rd);
        id_rs3_forward_o    = (id_use_rs3) & (wb_use_rd) & (rs3_id_wb_same_type) & (rs3_id_wb_same_idx);
    end

    always_comb begin : RAW_RS1_EXE_MEM_WB
        exe_use_rs1           = ( |exe_rs1 & ~exe_use_fpr[2] ) | exe_use_fpr[2];
        rs1_exe_wb_same_type  = ~( exe_use_fpr[2] ^ wb_use_frd );
        rs1_exe_wb_same_idx   = (exe_rs1 == wb_rd );
        rs1_exe_mem_same_type = ~( exe_use_fpr[2] ^ mem_use_frd);
        rs1_exe_mem_same_idx  = (exe_rs1 == mem_rd);

        wb_rs1_forward_o  = (exe_use_rs1) & (wb_use_rd ) & (rs1_exe_wb_same_type ) & (rs1_exe_wb_same_idx );
        mem_rs1_forward_o = (exe_use_rs1) & (mem_use_rd) & (rs1_exe_mem_same_type) & (rs1_exe_mem_same_idx);
    end

    always_comb begin : RAW_RS2_EXE_MEM_WB
        exe_use_rs2           = ( |exe_rs2 & ~exe_use_fpr[1] ) | exe_use_fpr[1];
        rs2_exe_wb_same_type  = ~( exe_use_fpr[1] ^ wb_use_frd );
        rs2_exe_wb_same_idx   = (exe_rs2 == wb_rd );
        rs2_exe_mem_same_type = ~( exe_use_fpr[1] ^ mem_use_frd);
        rs2_exe_mem_same_idx  = (exe_rs2 == mem_rd);
        
        wb_rs2_forward_o  = (exe_use_rs2) & (wb_use_rd ) & (rs2_exe_wb_same_type ) & (rs2_exe_wb_same_idx );
        mem_rs2_forward_o = (exe_use_rs2) & (mem_use_rd) & (rs2_exe_mem_same_type) & (rs2_exe_mem_same_idx);
    end

    always_comb begin : RAW_RS3_EXE_MEM_WB
        exe_use_rs3           = exe_use_fpr[3];
        rs3_exe_wb_same_type  = ~( exe_use_fpr[3] ^ wb_use_frd );
        rs3_exe_wb_same_idx   = (exe_rs3 == wb_rd );
        rs3_exe_mem_same_type = ~( exe_use_fpr[3] ^ mem_use_frd);
        rs3_exe_mem_same_idx  = (exe_rs3 == mem_rd);

        wb_rs3_forward_o  = (exe_use_rs3) & (wb_use_rd ) & (rs3_exe_wb_same_type ) & (rs3_exe_wb_same_idx );
        mem_rs3_forward_o = (exe_use_rs3) & (mem_use_rd) & (rs3_exe_mem_same_type) & (rs3_exe_mem_same_idx);
    end

    // --------------------------------------------
    //                   Bubble                    
    // --------------------------------------------

    /*
        Insert bubble when EXE Stage is a Load and FADDS, FSUBS and MUL inst.
        Docode's rs1/rs2 overlap with EXE's RD

        ** USE_FP = { RS3 (3), RS1 (2), RS2 (1), RD (0) } **

        chech 1. Is using RS : (|RS1 & ~USE_FP) & USE_FP --> calculated at data hazard
        check 2. Is using same type of RS (FP ot INT)
        check 3. Is RS equals to RD
        check 4. Is EXE a load, FADD, FSUBS, MUL
    */

    assign exe_use_load = (exe_uOP_i.op inside {_LB, _LH, _LW, _LBU, _LHU});
    assign exe_use_csr  = (exe_uOP_i.fu == CSR);
    assign exe_use_falu = (exe_uOP_i.fu == FPU);
    assign exe_use_mul  = (exe_uOP_i.fu == GMUL);
    assign exe_use_vpu  = (exe_uOP_i.fu == VPU);

    always_comb begin
        rs1_id_exe_same_type = ~(id_use_fpr[2] ^ exe_use_fpr[0]);
        rs1_id_exe_same_idx  = (id_rs1 == exe_rd);
        is_de_rs1_overlap    = (id_use_rs1) & (rs1_id_exe_same_type) & (rs1_id_exe_same_idx);

        rs2_id_exe_same_type = ~(id_use_fpr[1] ^ exe_use_fpr[0]);
        rs2_id_exe_same_idx  = (id_rs2 == exe_rd);
        is_de_rs2_overlap    = (id_use_rs2) & (rs2_id_exe_same_type) & (rs2_id_exe_same_idx);

        rs3_id_exe_same_type = ~(id_use_fpr[3] ^ exe_use_fpr[0]);
        rs3_id_exe_same_idx  = (id_rs3 == exe_rd);
        is_de_rs3_overlap    = (id_use_rs3) & (rs3_id_exe_same_type) & (rs3_id_exe_same_idx);

        bubble = (exe_use_csr | exe_use_load | exe_use_falu | exe_use_mul | exe_use_vpu) &
                 (is_de_rs1_overlap | is_de_rs2_overlap | is_de_rs3_overlap);
    end

endmodule