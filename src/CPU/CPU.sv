// ----------------------------------
// Module TODO:
//     1.  CPU.sv         --> ok
//     2.  if_stage.sv    --> ok
//     3.  id_stage.sv    --> ok
//     4.  exe_stage.sv   --> ok
//     5.  mem_stage.sv   --> ok
//     6.  wb_stage.sv    --> ok
//     7.  alu.sv         --> ok
//     8.  falu.sv        --> ok
//     9.  multiplier.sv  --> ok
//     10. csr.sv         --> ok
//     11. regfiles.sv    --> ok
//     12. fp_regfiles.sv --> ok
//     13. controller.sv  --> ok
//     14. rv_decoder.sv  --> ok
// ----------------------------------

module CPU (
    input  logic        clk_i,
    input  logic        rst_i,

    // external and timer interrupt
    input  logic        DMA_interrupt_i,
    input  logic        WDT_interrupt_i,

    // if stage request to I$
    output logic        icache_core_request_o,
    output logic [31:0] icache_core_pc_o,
    input  logic        icache_core_wait_i,
    input  logic [31:0] icache_core_addr_i,
    input  logic [31:0] icache_core_out_i,

    // exe stage request to D$
    output logic        dcache_core_request_o,
    output logic [ 3:0] dcache_core_write_o,
    output logic [31:0] dcache_core_addr_o,
    output logic [31:0] dcache_core_in_o,
    input  logic        dcache_core_wait_i,
    input  logic [31:0] dcache_core_out_i,

    // to VPU (issue insterface)
    output logic        vector_inst_valid_o,
    output logic [31:0] vector_inst_o,
    output logic [31:0] vector_xrs1_val_o,
    output logic [31:0] vector_xrs2_val_o,
    input  logic        vector_ack_i,
    input  logic        vector_writeback_i,
    input  logic        vector_pend_lsu_i,

    // from VPU (writeback interface)
    input  logic        vector_lsu_valid_i,
    input  logic        vector_result_valid_i,
    input  logic [31:0] vector_result_i
);

    // --------------------------------------------
    //              Signal Declaration             
    // --------------------------------------------
    // IF <-> ID
    FETCH_ENTRY_t fetch_entry;
    logic         fetch_ack;

    // ID <-> EXE
    uOP_t         id_uOP;
    uOP_t         exe_uOP;
    logic [31:0]  rs1_data, rs2_data, rs3_data;

    // EXE <-> MEM
    uOP_t         mem_uOP;
    logic [31:0]  mem_mul_result;
    logic [31:0]  mem_csr_operand;

    // MEM <-> WB
    uOP_t         wb_uOP;
    logic [31:0]  wb_csr_operand;

    // WB <-> ID (register writeback)
    logic         wb_rd_web;
    logic         wb_frd_web;
    REG_t         wb_rd;
    logic [31:0]  wb_data;

    // CTRL <-> *
    logic         booting, stall, waiting, btkn;
    logic         flush_if, flush_id, flush_exe, flush_mem;
    logic         trap_valid, interrupt_taken;
    logic         wfi, mret;
    logic [31:0]  bta, mtvec, mepc, exe_pc;

    // data forwarding
    logic         id_rs1_forward;
    logic         id_rs2_forward;
    logic         id_rs3_forward;
    
    logic         mem_rs1_forward;
    logic         mem_rs2_forward;
    logic         mem_rs3_forward;
    
    logic         wb_rs1_forward;
    logic         wb_rs2_forward;
    logic         wb_rs3_forward;

    // vector ctrl
    logic         vector_unaccept;

    // fpu ctrl
    logic         fpu_wait;

    // Branch Prediction
    BHT_data      bht_update;
    BTB_data      btb_update;
    predict_info  BP_info_IF_to_ID;
    predict_info  BP_info_ID_to_EX;
    logic         BU_flush;

    // --------------------------------------------
    //                  CPU Stages                 
    // --------------------------------------------
    if_stage i_if_stage (
        .clk_i,
        .rst_i,

        // control signal
        .booting_i         ( booting          ),
        .flush_i           ( flush_if         ),
        .BU_flush_i        ( BU_flush         ),

        // request to I$
        .icache_core_request_o,
        .icache_core_pc_o,
        .icache_core_wait_i,
        .icache_core_addr_i,
        .icache_core_out_i,

        // control flow signals
        .btkn_i            ( btkn             ),
        .trap_valid_i      ( trap_valid       ),
        .mret_i            ( mret             ),
        .bta_i             ( bta              ),
        .mtvec_i           ( mtvec            ),
        .mepc_i            ( mepc             ),

        // to ID
        .fetch_entry_o     ( fetch_entry      ),
        .fetch_ack_i       ( fetch_ack        ),
        .bht_update        ( bht_update       ),
        .btb_update        ( btb_update       ),
        .BP_info_IF_to_ID  ( BP_info_IF_to_ID )
    );

    id_stage i_id_stage (
        .clk_i,
        .rst_i,

        // control signal
        .flush_i           ( flush_id         ),
        .stall_i           ( stall            ),

        // vector control signal
        .vector_unaccept_i ( vector_unaccept  ),

        // fpu control signal
        .fpu_wait_i        ( fpu_wait         ),

        // from IF
        .fetch_entry_i     ( fetch_entry      ),
        .fetch_ack_o       ( fetch_ack        ),

        // register writeback
        .wb_rd_web_i       ( wb_rd_web        ),
        .wb_frd_web_i      ( wb_frd_web       ),
        .wb_rd_i           ( wb_rd            ),
        .wb_data_i         ( wb_data          ),

        // data forwarding
        .id_uOP_o          ( id_uOP           ),
        .id_rs1_forward_i  ( id_rs1_forward   ),
        .id_rs2_forward_i  ( id_rs2_forward   ),
        .id_rs3_forward_i  ( id_rs3_forward   ),

        // to EXE
        .exe_uOP_o         ( exe_uOP          ),
        .rs1_data_o        ( rs1_data         ),
        .rs2_data_o        ( rs2_data         ),
        .rs3_data_o        ( rs3_data         ),
        .BP_info_IF_to_ID  ( BP_info_IF_to_ID ),
        .BP_info_ID_to_EX  ( BP_info_ID_to_EX )
    );

    exe_stage i_exe_stage (
        .clk_i,
        .rst_i,

        // control signal
        .flush_i           ( flush_exe        ),
        .stall_i           ( stall            ),
        .waiting_i         ( waiting          ),
        .wfi_o             ( wfi              ),
        .mret_o            ( mret             ),
        .exe_pc_o          ( exe_pc           ),

        // vector control signal
        .vector_unaccept_o ( vector_unaccept  ),

        // fpu control signal
        .fpu_wait_o        ( fpu_wait         ),

        // from ID
        .exe_uOP_i         ( exe_uOP          ),
        .rs1_data_i        ( rs1_data         ),
        .rs2_data_i        ( rs2_data         ),
        .rs3_data_i        ( rs3_data         ),

        // resolved branch
        .btkn_o            ( btkn             ),
        .bta_o             ( bta              ),

        .bht_update        ( bht_update       ),
        .btb_update        ( btb_update       ),
        .BP_info_ID_to_EX  ( BP_info_ID_to_EX ),
        .BU_flush_o        ( BU_flush         ),

        // request to D$
        .dcache_core_request_o,
        .dcache_core_write_o,
        .dcache_core_addr_o,
        .dcache_core_in_o,

        // WB/MEM data forwarding
        .mem_rs1_forward_i ( mem_rs1_forward  ),
        .mem_rs2_forward_i ( mem_rs2_forward  ),
        .mem_rs3_forward_i ( mem_rs3_forward  ),
        .wb_rs1_forward_i  ( wb_rs1_forward   ),
        .wb_rs2_forward_i  ( wb_rs2_forward   ),
        .wb_rs3_forward_i  ( wb_rs3_forward   ),
        .wb_data_i         ( wb_data          ),

        // to MEM
        .mem_uOP_o         ( mem_uOP          ),
        .mem_mul_result_o  ( mem_mul_result   ),
        .mem_csr_operand_o ( mem_csr_operand  ),

        // to VPU
        .vector_inst_valid_o,
        .vector_inst_o,
        .vector_xrs1_val_o,
        .vector_xrs2_val_o,
        .vector_ack_i,
        .vector_writeback_i,
        .vector_pend_lsu_i
    );

    mem_stage i_mem_stage (
        .clk_i,
        .rst_i,

        // control signal
        .stall_o           ( stall            ),
        .flush_i           ( flush_mem        ),

        // from EXE
        .mem_uOP_i         ( mem_uOP          ),
        .mem_mul_result_i  ( mem_mul_result   ),
        .mem_csr_operand_i ( mem_csr_operand  ),

        // response from D$
        .dcache_core_wait_i,
        .dcache_core_out_i,

        // to WB
        .wb_uOP_o          ( wb_uOP           ),
        .wb_csr_operand_o  ( wb_csr_operand   ),

        // vector wirteback xreg
        .vector_lsu_valid_i,
        .vector_result_valid_i,
        .vector_result_i
    );

    wb_stage i_wb_stage (
        .clk_i,
        .rst_i,

        // control signal
        .waiting_i         ( waiting          ),
        .trap_valid_o      ( trap_valid       ),
        .interrupt_taken_o ( interrupt_taken  ),
        .wfi_i             ( wfi              ),
        .mret_i            ( mret             ),
        .exe_pc_i          ( exe_pc           ),

        // external interrupt
        .mei_i             ( DMA_interrupt_i  ),
        .mti_i             ( WDT_interrupt_i  ),

        // control flow
        .mepc_o            ( mepc             ),
        .mtvec_o           ( mtvec            ),

        // from MEM
        .wb_uOP_i          ( wb_uOP           ),
        .wb_csr_operand_i  ( wb_csr_operand   ),

        // register writeback
        .wb_rd_web_o       ( wb_rd_web        ),
        .wb_frd_web_o      ( wb_frd_web       ),
        .wb_rd_o           ( wb_rd            ),
        .wb_data_o         ( wb_data          )
    );

    controller i_controller (
        .clk_i,
        .rst_i,

        // control signal
        .booting_o         ( booting          ),
        .flush_if_o        ( flush_if         ),
        .flush_id_o        ( flush_id         ),
        .flush_exe_o       ( flush_exe        ),
        .flush_mem_o       ( flush_mem        ),
        .waiting_o         ( waiting          ),

        // from CSR
        .wfi_i             ( wfi              ),
        .mret_i            ( mret             ),
        .trap_valid_i      ( trap_valid       ),
        .interrupt_taken_i ( interrupt_taken  ),

        // resolve branch
        .btkn_i            ( btkn             ),
        .BU_flush_i        ( BU_flush         ),

        // data hazard
        .id_uOP_i          ( id_uOP           ),
        .exe_uOP_i         ( exe_uOP          ),
        .mem_uOP_i         ( mem_uOP          ),
        .wb_uOP_i          ( wb_uOP           ),
        .id_rs1_forward_o  ( id_rs1_forward   ),
        .id_rs2_forward_o  ( id_rs2_forward   ),
        .id_rs3_forward_o  ( id_rs3_forward   ),
        .mem_rs1_forward_o ( mem_rs1_forward  ),
        .mem_rs2_forward_o ( mem_rs2_forward  ),
        .mem_rs3_forward_o ( mem_rs3_forward  ),
        .wb_rs1_forward_o  ( wb_rs1_forward   ),
        .wb_rs2_forward_o  ( wb_rs2_forward   ),
        .wb_rs3_forward_o  ( wb_rs3_forward   )
    );

endmodule