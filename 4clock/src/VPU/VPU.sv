// --------------------------------------------
//             Support instruction             
// --------------------------------------------
// * IMPORTANT : we not yet support widening or narrowing instruction
// Total Support Instructions : 
//
// --------------------------------------------
//    Vector Integer Arithmetic Instructions   
// --------------------------------------------
// 1. Vector Single-Width Integer Add and Subtract
//    * vadd      (VV, VI, VX) --> support (test ok)
//    * vsub      (VV, VX)     --> support (test ok)
//    * vrsub     (VI, VX)     --> support (test ok)
//
// 2. Vector Widening Integer Add/Subtract
//    * vwadd     (VV, VX)     --> not support
//    * vwsubu    (VV, VX)     --> not support
//    * vwsub     (VV, VX)     --> not support
//    * vwaddu.w  (VV, VX)     --> not support
//    * vwadd.w   (VV, VX)     --> not support
//    * vwsubu.w  (VV, VX)     --> not support
//    * vwsub.w   (VV, VX)     --> not support
//
// 3. Vector Integer Extension
//    * v[z|s]ext.vfi (VV)     --> not support
//
// 4. Vector Integer Add-with-Carry / Subtract-with-Borrow Instructions
//    * vadc      (VV, VI, VX) --> support
//    * vmadc     (VV, VI, VX) --> support
//    * vsbc      (VV, VX)     --> support
//    * vmsbc     (VV, VX)     --> support
//
// 5. Vector Bitwise Logical Instructions
//    * vand      (VV, VI, VX) --> support (test ok)
//    * vor       (VV, VI, VX) --> support (test ok)
//    * vxor      (VV, VI, VX) --> support (test ok)
//
// 6. Vector Single-Width Shift Instructions
//    * vsll      (VV, VI, VX) --> support
//    * vsrl      (VV, VI, VX) --> support
//    * vsra      (VV, VI, VX) --> support
//
// 7. Vector Narrowing Integer Right Shift Instructions
//    * vnsrl     (VV, VI, VX) --> not support
//    * vnsra     (VV, VI, VX) --> not support
//
// 8. Vector Integer Compare Instructions
//    * vmseq     (VV, VI, VX) --> support
//    * vmsne     (VV, VI, VX) --> support
//    * vmsltu    (VV, VX)     --> support
//    * vmslt     (VV, VX)     --> support
//    * vmsleu    (VV, VI, VX) --> support
//    * vmsle     (VV, VI, VX) --> support
//    * vmsgtu    (VI, VX)     --> support
//    * vmsgt     (VI, VX)     --> support
//
// 9. Vector Integer Min/Max Instructions
//    * vminu     (VV, VX)     --> support
//    * vmin      (VV, VX)     --> support
//    * vmaxu     (VV, VX)     --> support
//    * vmax      (VV, VX)     --> support
//
// 10. Vector Single-Width Integer Multiply Instruction
//    * vmulhu    (VV, VX)     --> support
//    * vmul      (VV, VX)     --> support
//    * vmulhsu   (VV, VX)     --> support
//    * vmulh     (VV, VX)     --> support
//
// 11. Vector Widening Integer Multiply Instructions
//    * vwmulu    (VV, VX)     --> not support
//    * vwmulsu   (VV, VX)     --> not support
//    * vwmul     (VV, VX)     --> not support
//
// 12. Vector Single-Width Integer Multiply-Add Instructions
//    * vmadd     (VV, VX)     --> support
//    * vnmsub    (VV, VX)     --> support
//    * vmacc     (VV, VX)     --> support
//    * vnmsac    (VV, VX)     --> support
//
// 13. Vector Widening Integer Multiply-Add Instructions
//    * vwmaccu   (VV, VX)     --> not support
//    * vwmacc    (VV, VX)     --> not support
//    * vwmaccus  (VX)         --> not support
//    * vwmaccsu  (VV, VX)     --> not support
//
// 14. Vector Integer Merge Instructions / Vector Integer Move Instructions
//    * vmerge    (VV, VI, VX) --> support
//    * vmv       (VV, VI, VX) --> support
//
// --------------------------------------------
//       Vector Fixed-Point Instructions       
// --------------------------------------------
// 15. Vector Single-Width Saturating Add and Subtract
//    * vsaddu    (VV, VI, VX) --> support
//    * vsadd     (VV, VI, VX) --> support
//    * vssubu    (VV, VX)     --> support
//    * vssub     (VV, VX)     --> support
//
// 16. Vector Single-Width Averaging Add and Subtract
//    * vaaddu    (VV, VX)     --> support
//    * vaadd     (VV, VX)     --> support
//    * vasubu    (VV, VX)     --> support
//    * vasub     (VV, VX)     --> support
//
// 17. Vector Single-Width Fractional Multiply with Rounding and Saturation
//    * vsmul     (VV, VX)     --> support
//
// 18. Vector Single-Width Scaling Shift Instructions
//    * vssrl     (VV, VI, VX) --> support
//    * vssra     (VV, VI, VX) --> support
// 19. Vector Narrowing Fixed-Point Clip Instructions
//    * vnclipu   (VV, VI, VX) --> not support
//    * vnclip    (VV, VI, VX) --> not support
//
// --------------------------------------------
//        Vector Reduction Instructions        
// --------------------------------------------
// 20. Vector Single-Width Integer Reduction Instructions
//    * vredsum   (VV)         --> support
//    * vredand   (VV)         --> not support
//    * vredor    (VV)         --> not support
//    * vredxor   (VV)         --> not support
//    * vredminu  (VV)         --> not support
//    * vredmin   (VV)         --> not support
//    * vredmaxu  (VV)         --> not support
//    * vredmax   (VV)         --> not support
//
// 21. Vector Widening Integer Reduction Instructions
//    * vwredsumu (VV)         --> not support
//    * vwredsum  (VV)         --> not support
//
// --------------------------------------------
//           Vector Mask Instructions          
// --------------------------------------------
// 22. Vector Mask-Register Logical Instructions
//    * vmandnot  (VV)         --> support
//    * vmand     (VV)         --> support
//    * vmor      (VV)         --> support
//    * vmxor     (VV)         --> support
//    * vmornot   (VV)         --> support
//    * vmnand    (VV)         --> support
//    * vmnor     (VV)         --> support
//    * vmxnor    (VV)         --> support
//
// 23. VMUNARY0
//    * vmsbf     (VV)         --> support
//    * vmsof     (VV)         --> support
//    * vmsif     (VV)         --> support
//    * viota     (VV)         --> support
//    * vid       (VV)         --> support
//
// 24. VWXUNARY0
//    * vmv.x.s   (VV)         --> not support
//    * vpopc     (VV)         --> not support
//    * vfirst    (VV)         --> not support
//
// --------------------------------------------
//       Vector Permutation Instructions       
// --------------------------------------------
// 25. Integer Scalar Move Instructions
//    * vmv.s.x   (VX)         --> support
//
// 26. Vector Slide Instructions
//    * vslideup    (VI, VX)   --> support
//    * vslidedown  (VI, VX)   --> support
//    * vslide1up   (VX)       --> support
//    * vslide1down (VX)       --> support
//
// 27. Vector Register Gather Instructions
//    * vrgather  (VV, VI, VX) --> not support
//
// 28. Vector Compress Instruction
//    * vcomprss  (VV)         --> not support
//
// 29. Whole Vector Register Move
//    * vmv<nr>r  (VI)         --> not support
//
// --------------------------------------------
//        Vector Load/Store Instructions       
// --------------------------------------------
// 30. Load / Store Instruction
//    * vle                    --> support
//    * vlse                   --> not support
//    * vse                    --> support
//    * vsse                   --> support

// --------------------------------------------
//       RISC-V Zve64x Vector Coprocessor      
// --------------------------------------------
module VPU (
    input  logic        clk_i,
    input  logic        rst_i,

    // from CPU
    input  logic        vector_inst_valid_i,
    input  logic [31:0] vector_inst_i,
    input  logic [31:0] vector_xrs1_val_i,
    input  logic [31:0] vector_xrs2_val_i,
    output logic        vector_ack_o,
    output logic        vector_writeback_o,
    output logic        vector_pend_lsu_o,

    // to CPU
    output logic        vector_lsu_valid_o,
    output logic        vector_result_valid_o,
    output logic [31:0] vector_result_o,

    // request to D$
    output logic        dcache_vpu_request_o,
    output logic [ 3:0] dcache_vpu_write_o,
    output logic [31:0] dcache_vpu_addr_o,
    output logic [31:0] dcache_vpu_in_o,

    // response from D$
    input  logic        dcache_vpu_wait_i,
    input  logic [31:0] dcache_vpu_out_i
);

    // --------------------------------------------
    //              Signal Declaration             
    // --------------------------------------------
    // to VCFG unit
    logic                   VCFG_valid;
    VPU_uOP_t               VCFG_entry;
    logic                   VCFG_read_valid;
    logic [31:0]            VCFG_read_data;
    logic                   VCFG_commit;

    // to VPU IQ
    logic                   decode_entry_valid;
    VPU_uOP_t               decode_entry;
    logic                   decode_ack;

    // to VPU EXE
    logic                   dispatch_valid;
    VPU_uOP_t               dispatch_entry;
    logic                   dispatch_ready;

    // to COMMIT
    logic                   lsu_commit;

    // EXE reg read / write
    logic [2:0][4:0]        vreg_read_addr;
    logic [2:0][VLEN-1:0]   vreg_read_data;
    logic [VLEN-1:0]        vreg_v0;

    logic                   vreg_write_en;
    logic [4:0]             vreg_write_addr;
    logic [VLEN/8-1:0]      vreg_write_bweb;
    logic [VLEN-1:0]        vreg_write_data;

    // Vector CSRs
    logic [VL_BITS-2:0]     vstart;
    VXRM_e                  vxrm;
    logic                   vxsat;
    VTYPE_CSR_t             vtype;
    logic [VL_BITS-1:0]     vl;

    // --------------------------------------------
    //                  VPU Stages                 
    // --------------------------------------------
    VPU_id_stage i_VPU_id_stage (
        .clk_i,
        .rst_i,

        .vector_inst_valid_i,
        .vector_inst_i,
        .vector_xrs1_val_i,
        .vector_xrs2_val_i,
        .vector_ack_o,
        .vector_writeback_o,
        .vector_pend_lsu_o,

        .vsew_i                 ( vtype.vsew           ),
        .vlmul_i                ( vtype.vlmul          ),
        .vxrm_i                 ( vxrm                 ),
        .vl_i                   ( vl                   ),

        .decode_entry_valid_o   ( decode_entry_valid   ),
        .decode_entry_o         ( decode_entry         ),
        .decode_ack_i           ( decode_ack           ),
        .VCFG_commit_i          ( VCFG_commit          )
    );

    VPU_issue_stage i_VPU_issue_stage (
        .clk_i,
        .rst_i,

        .decode_entry_valid_i   ( decode_entry_valid   ),
        .decode_entry_i         ( decode_entry         ),
        .decode_ack_o           ( decode_ack           ),

        .VCFG_valid_o           ( VCFG_valid           ),
        .VCFG_entry_o           ( VCFG_entry           ),

        .dispatch_valid_o       ( dispatch_valid       ),
        .dispatch_entry_o       ( dispatch_entry       ),
        .dispatch_ready_i       ( dispatch_ready       )
    );

    // --------------------------------------------
    //             VPU Execution Unit              
    // --------------------------------------------
    VPU_cfg i_VPU_cfg (
        .clk_i,
        .rst_i,

        // from VPU ISSUE
        .VCFG_valid_i           ( VCFG_valid           ),
        .VCFG_entry_i           ( VCFG_entry           ),

        // csr value
        .vstart_o               ( vstart               ),
        .vxsat_o                ( vxsat                ),
        .vxrm_o                 ( vxrm                 ),
        .vtype_o                ( vtype                ),
        .vl_o                   ( vl                   ),

        .VCFG_read_valid_o      ( VCFG_read_valid      ),
        .VCFG_read_data_o       ( VCFG_read_data       )
    );

    VPU_execute_stage i_VPU_execute_stage (
        .clk_i,
        .rst_i,

        // from ISSUE
        .dispatch_valid_i       ( dispatch_valid       ),
        .dispatch_entry_i       ( dispatch_entry       ),
        .dispatch_ready_o       ( dispatch_ready       ),

        // to VPU regfile
        .vreg_read_addr_o       ( vreg_read_addr       ),
        .vreg_read_data_i       ( vreg_read_data       ),
        .vreg_v0_i              ( vreg_v0              ),

        .vreg_write_en_o        ( vreg_write_en        ),
        .vreg_write_addr_o      ( vreg_write_addr      ),
        .vreg_write_bweb_o      ( vreg_write_bweb      ),
        .vreg_write_data_o      ( vreg_write_data      ),

        // request to D$
        .dcache_vpu_request_o,
        .dcache_vpu_write_o,
        .dcache_vpu_addr_o,
        .dcache_vpu_in_o,

        // response from D$
        .dcache_vpu_wait_i,
        .dcache_vpu_out_i,

        .lsu_commit_o           ( lsu_commit           )
    );


    // --------------------------------------------
    //              VPU regisetr file              
    // --------------------------------------------

    VPU_regfile i_VPU_regfile (
        .clk_i,
        .rst_i,

        // read port (3 ports, and 1 v0 read port)
        .vreg_read_addr_i       ( vreg_read_addr       ),
        .vreg_read_data_o       ( vreg_read_data       ),
        .vreg_v0_o              ( vreg_v0              ),

        // write port (1 ports)
        .vreg_write_en_i        ( vreg_write_en        ),
        .vreg_write_addr_i      ( vreg_write_addr      ),
        .vreg_write_bweb_i      ( vreg_write_bweb      ),
        .vreg_write_data_i      ( vreg_write_data      )
    );

    /*

    VLEN=128b, SEW=8b, LMUL=8

    Byte          F E D C B A 9 8 7 6 5 4 3 2 1 0
    v8*n                3       2       1       0 --> lane 0~4
    v8*n+1              7       6       5       4 --> lane 0~8
    v8*n+2              B       A       9       8
    v8*n+3              F       E       D       C
    v8*n+4             13      12      11      10
    v8*n+5             17      16      15      14
    v8*n+6             1B      1A      19      18
    v8*n+7             1F      1E      1D      1C

    VLEN=128b, SEW=64b, LMUL=8

    Byte          F E D C B A 9 8 7 6 5 4 3 2 1 0
    v8*n                        1               0 --> lane 0~1
    v8*n+1                      3               2 --> lane 2~3
    v8*n+2                      5               4 --> lane 3~4
    v8*n+3                      7               6 --> lane 6~7
    v8*n+4                      9               8
    v8*n+5                      B               A
    v8*n+6                      D               C
    v8*n+7                      F               E
    */

    // --------------------------------------------
    //          VPU Commit stage (to CPU)          
    // --------------------------------------------
    VPU_commit_stage i_VPU_commit_stage (
        .clk_i,
        .rst_i,

        .VCFG_read_valid_i      ( VCFG_read_valid      ),
        .VCFG_read_data_i       ( VCFG_read_data       ),
        .VCFG_commit_o          ( VCFG_commit          ),
        .lsu_commit_i           ( lsu_commit           ),

        .vector_lsu_valid_o,
        .vector_result_valid_o,
        .vector_result_o
    );

endmodule