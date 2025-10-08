`ifndef _vpu_define
`define _vpu_define

// --------------------------------------------
//                  Bits Count                 
// --------------------------------------------
localparam int unsigned ID_BITS     = 3;
localparam int unsigned FUNC6_BITS  = 6;
localparam int unsigned VLEN        = 64;
localparam int unsigned CFG_VL_BITS = $clog2(VLEN);
localparam int unsigned VL_BITS     = $clog2(VLEN) + 1;

// --------------------------------------------
//              Instruction Index              
// --------------------------------------------
`define VM     25
`define MOP    27:26
`define MEW    28
`define NF     31:29
`define FUNC6  31:26

// --------------------------------------------
//                 Opcode Types                
// --------------------------------------------
// localparam logic [`OPCODE] FLW_OP    = 7'b0000111;
// localparam logic [`OPCODE] FSW_OP    = 7'b0100111;
// localparam logic [`OPCODE] CSR_OP    = 7'b1110011;
localparam logic [`OPCODE] VECTOR_OP = 7'b1010111;


// --------------------------------------------
//              Vector CSR address             
// --------------------------------------------
localparam logic [`CSRS ] CSR_VSTART = 12'h008;
localparam logic [`CSRS ] CSR_VXSAT  = 12'h009;
localparam logic [`CSRS ] CSR_VXRM   = 12'h00a;
localparam logic [`CSRS ] CSR_VCSR   = 12'h00f;
localparam logic [`CSRS ] CSR_VL     = 12'hc20;
localparam logic [`CSRS ] CSR_VTYPE  = 12'hc21;
localparam logic [`CSRS ] CSR_VLENB  = 12'hc22;

// --------------------------------------------
//                 Vector Func3                
// --------------------------------------------
localparam logic [`FUNC3] OPIVV = 3'b000;
localparam logic [`FUNC3] OPFVV = 3'b001; // no FP support
localparam logic [`FUNC3] OPMVV = 3'b010;
localparam logic [`FUNC3] OPIVI = 3'b011;
localparam logic [`FUNC3] OPIVX = 3'b100;
localparam logic [`FUNC3] OPFVF = 3'b101; // no FP support
localparam logic [`FUNC3] OPMVX = 3'b110;
localparam logic [`FUNC3] OPCFG = 3'b111;

// --------------------------------------------
//    Vector Integer Arithmetic Instructions   
// --------------------------------------------
// Vector Single-Width Integer Add and Subtract
// vadd (VV, VI, VX)
localparam logic [8:0] VADD_VV  = {OPIVV, 6'b000000};
localparam logic [8:0] VADD_VI  = {OPIVI, 6'b000000};
localparam logic [8:0] VADD_VX  = {OPIVX, 6'b000000};
// vsub (VV, VX)
localparam logic [8:0] VSUB_VV  = {OPIVV, 6'b000010};
localparam logic [8:0] VSUB_VX  = {OPIVX, 6'b000010};
// vrsub (VI, VX)
localparam logic [8:0] VRSUB_VI = {OPIVI, 6'b000011};
localparam logic [8:0] VRSUB_VX = {OPIVX, 6'b000011};

// Vector Widening Integer Add/Subtract
// vwaddu (VV, VX)
localparam logic [8:0] VWADDU_VV  = {OPMVV, 6'b110000};
localparam logic [8:0] VWADDU_VX  = {OPMVX, 6'b110000};
// vwadd (VV, VX)
localparam logic [8:0] VWADD_VV   = {OPMVV, 6'b110001};
localparam logic [8:0] VWADD_VX   = {OPMVX, 6'b110001};
// vwsubu (VV, VX)
localparam logic [8:0] VWSUBU_VV  = {OPMVV, 6'b110010};
localparam logic [8:0] VWSUBU_VX  = {OPMVX, 6'b110010};
// vwsub (VV, VX)
localparam logic [8:0] VWSUB_VV   = {OPMVV, 6'b110011};
localparam logic [8:0] VWSUB_VX   = {OPMVX, 6'b110011};
// vwaddu.w (VV, VX)
localparam logic [8:0] VWADDUW_VV = {OPMVV, 6'b110100};
localparam logic [8:0] VWADDUW_VX = {OPMVX, 6'b110100};
// vwadd.w (VV, VX)
localparam logic [8:0] VWADDW_VV  = {OPMVV, 6'b110101};
localparam logic [8:0] VWADDW_VX  = {OPMVX, 6'b110101};
// vwsubu.w (VV, VX)
localparam logic [8:0] VWSUBUW_VV = {OPMVV, 6'b110110};
localparam logic [8:0] VWSUBUW_VX = {OPMVX, 6'b110110};
// vwsub.w (VV, VX)
localparam logic [8:0] VWSUBW_VV  = {OPMVV, 6'b110111};
localparam logic [8:0] VWSUBW_VX  = {OPMVX, 6'b110111};

// Vector Integer Extension
// VXUNARY0 (only support v[z|s]ext.vf2) (VV)
localparam logic [8:0] VXUNARY0_VV = {OPMVV, 6'b010010};

// Vector Integer Add-with-Carry / Subtract-with-Borrow Instructions
// vadc (VV, VI, VX)
localparam logic [8:0] VADC_VV  = {OPIVV, 6'b010000};
localparam logic [8:0] VADC_VI  = {OPIVI, 6'b010000};
localparam logic [8:0] VADC_VX  = {OPIVX, 6'b010000};
// vmadc (VV, VI, VX)
localparam logic [8:0] VMADC_VV = {OPIVV, 6'b010001};
localparam logic [8:0] VMADC_VI = {OPIVI, 6'b010001};
localparam logic [8:0] VMADC_VX = {OPIVX, 6'b010001};
// vsbc (VV, VX)
localparam logic [8:0] VSBC_VV  = {OPIVV, 6'b010010};
localparam logic [8:0] VSBC_VX  = {OPIVX, 6'b010010};
// vmsbc (VV, VX)
localparam logic [8:0] VMSBC_VV = {OPIVV, 6'b010011};
localparam logic [8:0] VMSBC_VX = {OPIVX, 6'b010011};

// Vector Bitwise Logical Instructions
// vand (VV, VI, VX)
localparam logic [8:0] VAND_VV = {OPIVV, 6'b001001};
localparam logic [8:0] VAND_VI = {OPIVI, 6'b001001};
localparam logic [8:0] VAND_VX = {OPIVX, 6'b001001};
// vor (VV, VI, VX)
localparam logic [8:0] VOR_VV  = {OPIVV, 6'b001010};
localparam logic [8:0] VOR_VI  = {OPIVI, 6'b001010};
localparam logic [8:0] VOR_VX  = {OPIVX, 6'b001010};
// vxor (VV, VI, VX)
localparam logic [8:0] VXOR_VV = {OPIVV, 6'b001011};
localparam logic [8:0] VXOR_VI = {OPIVI, 6'b001011};
localparam logic [8:0] VXOR_VX = {OPIVX, 6'b001011};

// Vector Single-Width Shift Instructions
// vsll (VV, VI, VX)
localparam logic [8:0] VSLL_VV = {OPIVV, 6'b100101};
localparam logic [8:0] VSLL_VI = {OPIVI, 6'b100101};
localparam logic [8:0] VSLL_VX = {OPIVX, 6'b100101};
// vsrl (VV, VI, VX)
localparam logic [8:0] VSRL_VV = {OPIVV, 6'b101000};
localparam logic [8:0] VSRL_VI = {OPIVI, 6'b101000};
localparam logic [8:0] VSRL_VX = {OPIVX, 6'b101000};
// vsra (VV, VI, VX)
localparam logic [8:0] VSRA_VV = {OPIVV, 6'b101001};
localparam logic [8:0] VSRA_VI = {OPIVI, 6'b101001};
localparam logic [8:0] VSRA_VX = {OPIVX, 6'b101001};

// Vector Narrowing Integer Right Shift Instructions
// vnsrl (VV, VI, VX)
localparam logic [8:0] VNSRL_VV = {OPIVV, 6'b101100};
localparam logic [8:0] VNSRL_VI = {OPIVI, 6'b101100};
localparam logic [8:0] VNSRL_VX = {OPIVX, 6'b101100};
// vnsra (VV, VI, VX)
localparam logic [8:0] VNSRA_VV = {OPIVV, 6'b101101};
localparam logic [8:0] VNSRA_VI = {OPIVI, 6'b101101};
localparam logic [8:0] VNSRA_VX = {OPIVX, 6'b101101};

// Vector Integer Compare Instructions
// vmseq (VV, VI, VX)
localparam logic [8:0] VMSEQ_VV  = {OPIVV, 6'b011000};
localparam logic [8:0] VMSEQ_VI  = {OPIVI, 6'b011000};
localparam logic [8:0] VMSEQ_VX  = {OPIVX, 6'b011000};
// vmsne (VV, VI, VX)
localparam logic [8:0] VMSNE_VV  = {OPIVV, 6'b011001};
localparam logic [8:0] VMSNE_VI  = {OPIVI, 6'b011001};
localparam logic [8:0] VMSNE_VX  = {OPIVX, 6'b011001};
// vmsltu (VV, VX)
localparam logic [8:0] VMSLTU_VV = {OPIVV, 6'b011010};
localparam logic [8:0] VMSLTU_VX = {OPIVX, 6'b011010};
// vmslt (VV, VX)
localparam logic [8:0] VMSLT_VV  = {OPIVV, 6'b011011};
localparam logic [8:0] VMSLT_VX  = {OPIVX, 6'b011011};
// vmsleu (VV, VI, VX)
localparam logic [8:0] VMSLEU_VV = {OPIVV, 6'b011100};
localparam logic [8:0] VMSLEU_VI = {OPIVI, 6'b011100};
localparam logic [8:0] VMSLEU_VX = {OPIVX, 6'b011100};
// vmsle (VV, VI, VX)
localparam logic [8:0] VMSLE_VV  = {OPIVV, 6'b011101};
localparam logic [8:0] VMSLE_VI  = {OPIVI, 6'b011101};
localparam logic [8:0] VMSLE_VX  = {OPIVX, 6'b011101};
// vmsgtu (VI, VX)
localparam logic [8:0] VMSGTU_VI = {OPIVI, 6'b011110};
localparam logic [8:0] VMSGTU_VX = {OPIVX, 6'b011110};
// vmsgt (VI, VX)
localparam logic [8:0] VMSGT_VI  = {OPIVI, 6'b011111};
localparam logic [8:0] VMSGT_VX  = {OPIVX, 6'b011111};

// Vector Integer Min/Max Instructions
// vminu (VV, VX)
localparam logic [8:0] VMINU_VV = {OPIVV, 6'b000100};
localparam logic [8:0] VMINU_VX = {OPIVX, 6'b000100};
// vmin (VV, VX)
localparam logic [8:0] VMIN_VV  = {OPIVV, 6'b000101};
localparam logic [8:0] VMIN_VX  = {OPIVX, 6'b000101};
// vmaxu (VV, VX)
localparam logic [8:0] VMAXU_VV = {OPIVV, 6'b000110};
localparam logic [8:0] VMAXU_VX = {OPIVX, 6'b000110};
// vmax (VV, VX)
localparam logic [8:0] VMAX_VV = {OPIVV, 6'b000111};
localparam logic [8:0] VMAX_VX = {OPIVX, 6'b000111};

// Vector Single-Width Integer Multiply Instruction
// vmulhu (VV, VX)
localparam logic [8:0] VMULHU_VV  = {OPMVV, 6'b100100};
localparam logic [8:0] VMULHU_VX  = {OPMVX, 6'b100100};
// vmul (VV, VX)
localparam logic [8:0] VMUL_VV    = {OPMVV, 6'b100101};
localparam logic [8:0] VMUL_VX    = {OPMVX, 6'b100101};
// vmulhsu (VV, VX)
localparam logic [8:0] VMULHSU_VV = {OPMVV, 6'b100110};
localparam logic [8:0] VMULHSU_VX = {OPMVX, 6'b100110};
// vmulh (VV, VX)
localparam logic [8:0] VMULH_VV   = {OPMVV, 6'b100111};
localparam logic [8:0] VMULH_VX   = {OPMVX, 6'b100111};

// Vector Widening Integer Multiply Instructions
// vwmulu (VV, VX)
localparam logic [8:0] VWMULU_VV  = {OPMVV, 6'b111000};
localparam logic [8:0] VWMULU_VX  = {OPMVX, 6'b111000};
// vwmulsu (VV, VX)
localparam logic [8:0] VWMULSU_VV = {OPMVV, 6'b111010};
localparam logic [8:0] VWMULSU_VX = {OPMVX, 6'b111010};
// vwmul (VV, VX)
localparam logic [8:0] VWMUL_VV   = {OPMVV, 6'b111011};
localparam logic [8:0] VWMUL_VX   = {OPMVX, 6'b111011};

// Vector Single-Width Integer Multiply-Add Instructions
// vmadd (VV, VX)
localparam logic [8:0] VMADD_VV  = {OPMVV, 6'b101001};
localparam logic [8:0] VMADD_VX  = {OPMVX, 6'b101001};
// vnmsub (VV, VX)
localparam logic [8:0] VNMSUB_VV = {OPMVV, 6'b101011};
localparam logic [8:0] VNMSUB_VX = {OPMVX, 6'b101011};
// vmacc (VV, VX)
localparam logic [8:0] VMACC_VV  = {OPMVV, 6'b101101};
localparam logic [8:0] VMACC_VX  = {OPMVX, 6'b101101};
// vnmsac (VV, VX)
localparam logic [8:0] VNMSAC_VV = {OPMVV, 6'b101111};
localparam logic [8:0] VNMSAC_VX = {OPMVX, 6'b101111};

// Vector Widening Integer Multiply-Add Instructions
// vwmaccu (VV, VX)
localparam logic [8:0] VWMACCU_VV  = {OPMVV, 6'b111100};
localparam logic [8:0] VWMACCU_VX  = {OPMVX, 6'b111100};
// vwmacc (VV, VX)
localparam logic [8:0] VWMACC_VV   = {OPMVV, 6'b111101};
localparam logic [8:0] VWMACC_VX   = {OPMVX, 6'b111101};
// vwmaccus (VX)
localparam logic [8:0] VWMACCUS_VX = {OPMVX, 6'b111110};
// vwmaccsu (VV, VX)
localparam logic [8:0] VWMACCSU_VV = {OPMVV, 6'b111111};
localparam logic [8:0] VWMACCSU_VX = {OPMVX, 6'b111111};

// Vector Integer Merge Instructions
// Vector Integer Move Instructions
// vmv/merge (VV, VI, VX)
localparam logic [8:0] VMERGE_VV = {OPIVV, 6'b010111};
localparam logic [8:0] VMERGE_VI = {OPIVI, 6'b010111};
localparam logic [8:0] VMERGE_VX = {OPIVX, 6'b010111};

// --------------------------------------------
//       Vector Fixed-Point Instructions       
// --------------------------------------------
// Vector Single-Width Saturating Add and Subtract
// vsaddu (VV, VI, VX)
localparam logic [8:0] VSADDU_VV = {OPIVV, 6'b100000};
localparam logic [8:0] VSADDU_VI = {OPIVI, 6'b100000};
localparam logic [8:0] VSADDU_VX = {OPIVX, 6'b100000};
// vsadd (VV, VI, VX)
localparam logic [8:0] VSADD_VV  = {OPIVV, 6'b100001};
localparam logic [8:0] VSADD_VI  = {OPIVI, 6'b100001};
localparam logic [8:0] VSADD_VX  = {OPIVX, 6'b100001};
// vssubu (VV, VX)
localparam logic [8:0] VSSUBU_VV = {OPIVV, 6'b100010};
localparam logic [8:0] VSSUBU_VX = {OPIVX, 6'b100010};
// vssub (VV, VX)
localparam logic [8:0] VSSUB_VV  = {OPIVV, 6'b100011};
localparam logic [8:0] VSSUB_VX  = {OPIVX, 6'b100011};

// Vector Single-Width Averaging Add and Subtract
// vaaddu (VV, VX)
localparam logic [8:0] VAADDU_VV = {OPMVV, 6'b001000};
localparam logic [8:0] VAADDU_VX = {OPMVX, 6'b001000};
// vaadd (VV, VX)
localparam logic [8:0] VAADD_VV  = {OPMVV, 6'b001001};
localparam logic [8:0] VAADD_VX  = {OPMVX, 6'b001001};
// vasubu (VV, VX)
localparam logic [8:0] VASUBU_VV = {OPMVV, 6'b001010};
localparam logic [8:0] VASUBU_VX = {OPMVX, 6'b001010};
// vasub (VV, VX)
localparam logic [8:0] VASUB_VV  = {OPMVV, 6'b001011};
localparam logic [8:0] VASUB_VX  = {OPMVX, 6'b001011};

// Vector Single-Width Fractional Multiply with Rounding and Saturation
// vsmul (VV, VX)
localparam logic [8:0] VSMUL_VV = {OPIVV, 6'b100111};
localparam logic [8:0] VSMUL_VX = {OPIVX, 6'b100111};

// Vector Single-Width Scaling Shift Instructions
// vssrl (VV, VI, VX)
localparam logic [8:0] VSSRL_VV = {OPIVV, 6'b101010};
localparam logic [8:0] VSSRL_VI = {OPIVI, 6'b101010};
localparam logic [8:0] VSSRL_VX = {OPIVX, 6'b101010};
// vssra (VV, VI, VX)
localparam logic [8:0] VSSRA_VV = {OPIVV, 6'b101011};
localparam logic [8:0] VSSRA_VI = {OPIVI, 6'b101011};
localparam logic [8:0] VSSRA_VX = {OPIVX, 6'b101011};

// Vector Narrowing Fixed-Point Clip Instructions
// vnclipu (VV, VI, VX)
localparam logic [8:0] VNCLIPU_VV = {OPIVV, 6'b101110};
localparam logic [8:0] VNCLIPU_VI = {OPIVI, 6'b101110};
localparam logic [8:0] VNCLIPU_VX = {OPIVX, 6'b101110};
// vnclip (VV, VI, VX)
localparam logic [8:0] VNCLIP_VV  = {OPIVV, 6'b101111};
localparam logic [8:0] VNCLIP_VI  = {OPIVI, 6'b101111};
localparam logic [8:0] VNCLIP_VX  = {OPIVX, 6'b101111};

// --------------------------------------------
//        Vector Reduction Instructions        
// --------------------------------------------
// Vector Single-Width Integer Reduction Instructions
// vredsum (VV)
localparam logic [8:0] VREDSUM_VV  = {OPMVV, 6'b000000};
// vredand (VV)
localparam logic [8:0] VREDAND_VV  = {OPMVV, 6'b000001};
// vredor (VV)
localparam logic [8:0] VREDOR_VV   = {OPMVV, 6'b000010};
// vredxor (VV)
localparam logic [8:0] VREDXOR_VV  = {OPMVV, 6'b000011};
// vredminu (VV)
localparam logic [8:0] VREDMINU_VV = {OPMVV, 6'b000100};
// vredmin (VV)
localparam logic [8:0] VREDMIN_VV  = {OPMVV, 6'b000101};
// vredmaxu (VV)
localparam logic [8:0] VREDMAXU_VV = {OPMVV, 6'b000110};
// vredmax (VV)
localparam logic [8:0] VREDAMX_VV  = {OPMVV, 6'b000111};

// Vector Widening Integer Reduction Instructions
// vwredsumu (VV)
localparam logic [8:0] VWREDSUMU_VV = {OPIVV, 6'b110000};
// vwredsum (VV)
localparam logic [8:0] VWREDSUM_VV  = {OPIVV, 6'b110001};

// --------------------------------------------
//           Vector Mask Instructions          
// --------------------------------------------
// Vector Mask-Register Logical Instructions
// vmandnot (VV)
localparam logic [8:0] VMANDNOT_VV = {OPMVV, 6'b011000};
// vmand (VV)
localparam logic [8:0] VMAND_VV    = {OPMVV, 6'b011001};
// vmor (VV)
localparam logic [8:0] VMOR_VV     = {OPMVV, 6'b011010};
// vmxor (VV)
localparam logic [8:0] VMXOR_VV    = {OPMVV, 6'b011011};
// vmornot (VV)
localparam logic [8:0] VMORNOT_VV  = {OPMVV, 6'b011100};
// vmnand (VV)
localparam logic [8:0] VMNAND_VV   = {OPMVV, 6'b011101};
// vmnor (VV)
localparam logic [8:0] VMNOR_VV    = {OPMVV, 6'b011110};
// vmxnor (VV)
localparam logic [8:0] VMXNOR_VV   = {OPMVV, 6'b011111};

// VMUNARY0 (VV)
// vmsbf, vmsof, vmsif, viota, vid
localparam logic [8:0] VMUNARY0_VV = {OPMVV, 6'b010100};

// VWXUNARY0 (VV)
// vmv.x.s(permutation), vpopc(mask), vfirst(mask)
localparam logic [8:0] VWXUNARY0_VV   = {OPMVV, 6'b010000};

// --------------------------------------------
//       Vector Permutation Instructions       
// --------------------------------------------
// Integer Scalar Move Instructions
// VRXUNARY0 (vmv.s.x) (VX)
localparam logic [8:0] VRXUNARY0_VX = {OPMVX, 6'b010000};

// Vector Slide Instructions
// vslideup (VI, VX)
localparam logic [8:0] VSLIDEUP_VI    = {OPIVI, 6'b001110};
localparam logic [8:0] VSLIDEUP_VX    = {OPIVX, 6'b001110};
// vslidedown (VI, VX)
localparam logic [8:0] VSLIDEDOWN_VI  = {OPIVI, 6'b001111};
localparam logic [8:0] VSLIDEDOWN_VX  = {OPIVX, 6'b001111};
// vslide1up (VX)
localparam logic [8:0] VSLIDE1UP_VX   = {OPMVX, 6'b001110};
// vslide1down (VX)
localparam logic [8:0] VSLIDE1DOWN_VX = {OPMVX, 6'b001111};

// Vector Register Gather Instructions
// vrgather (VV, VI, VX)
localparam logic [8:0] VRGATHER_VV = {OPIVV, 6'b001100};
localparam logic [8:0] VRGATHER_VI = {OPIVI, 6'b001100};
localparam logic [8:0] VRGATHER_VX = {OPIVX, 6'b001100};

// Vector Compress Instruction
// vcomprss (VV)
localparam logic [8:0] VCOMPRESS_VV = {OPMVV, 6'b010111};

// Whole Vector Register Move
// vmv<nr>r (VI)
localparam logic [8:0] VMVNRR_VI = {OPIVI, 6'b100111};

// --------------------------------------------
//                Vector config                
// --------------------------------------------
typedef enum logic [2:0] {
    VSEW_8       = 3'b000,
    VSEW_16      = 3'b001,
    VSEW_32      = 3'b010,
    VSEW_64      = 3'b011,
    VSEW_INVALID = 3'b100
} VSEW_e;

typedef enum logic [2:0] {
    LMUL_INVALID = 3'b100,
    LMUL_F8      = 3'b101,
    LMUL_F4      = 3'b110,
    LMUL_F2      = 3'b111,
    LMUL_1       = 3'b000,
    LMUL_2       = 3'b001,
    LMUL_4       = 3'b010,
    LMUL_8       = 3'b011
} VLMUL_e;

typedef enum logic [1:0] {
    EMUL_1 = 2'b00,
    EMUL_2 = 2'b01,
    EMUL_4 = 2'b10,
    EMUL_8 = 2'b11
} EMUL_e;

// Policy for determining the effective vector length of an instruction
typedef enum logic [1:0] {
    EVL_DEFAULT, // default EVL (VL for most instr; depends on EEW/SEW ratio for loads and stores)
    EVL_1,       // set EVL to 1
    EVL_MASK,    // set EVL to ceil(VL/8) (used for loading/storing vector masks)
    EVL_MAX      // set EVL to the maximum value for the current config
} EVL_POLICY_e;

typedef enum logic [1:0] {
    OP_SINGLEWIDTH,  // neither widening nor narrowing
    OP_WIDENING,     // widening operation with 2*SEW =   SEW op SEW
    OP_WIDENING_VS2, // widening operation with 2*SEW = 2*SEW op SEW
    OP_NARROWING     // narrowing operating with  SEW = 2*SEW op SEW
} OP_WIDENARROW_e;

// fixed-point rounding mode
typedef enum logic [1:0] {
    VXRM_RNU = 2'b00,   // round-to-nearest-up
    VXRM_RNE = 2'b01,   // round-to-nearest-even
    VXRM_RDN = 2'b10,   // round-down
    VXRM_ROD = 2'b11    // round-to-odd
} VXRM_e;

typedef struct packed {
    logic   vma;
    logic   vta;
    VSEW_e  vsew;
    VLMUL_e vlmul;
} VTYPE_CSR_t;

// --------------------------------------------
//                VCFG Operands                
// --------------------------------------------
typedef enum logic [3:0] {
    CFG_VSETVL,
    CFG_VTYPE_READ,
    CFG_VL_READ,
    CFG_VLENB_READ,
    CFG_VSTART_WRITE,
    CFG_VSTART_SET,
    CFG_VSTART_CLEAR,
    CFG_VXSAT_WRITE,
    CFG_VXSAT_SET,
    CFG_VXSAT_CLEAR,
    CFG_VXRM_WRITE,
    CFG_VXRM_SET,
    CFG_VXRM_CLEAR,
    CFG_VCSR_WRITE,
    CFG_VCSR_SET,
    CFG_VCSR_CLEAR
} CFG_CSR_OP_e;

typedef struct packed {
    CFG_CSR_OP_e csr_op;
    VTYPE_CSR_t  vtype;
    logic        vlmax;
    logic        keep_vl;
} VCFG_OP_t; // --> 4 + 8 + 1 + 1 = 14 bit

// --------------------------------------------
//                VALU Operands                
// --------------------------------------------
typedef enum logic [5:0] {
    VADD , VSUB  , VRSUB,
    VAND , VOR   , VXOR ,
    VSLL , VSRL  , VSRA ,
    VMSEQ, VMSNE , VMSLT, VMSLE , VMSGT,
    VMIN , VMAX  ,
    VSADD, VSADDU, VSSUB, VSSUBU,
    VAADD, VASUB ,
    VMV  , VMERGE, VMVR
} VLAU_OP_e;

typedef enum logic [1:0] {
    VALU_MASK_NONE,  // mask vreg is not used
    VALU_MASK_WRITE, // mask used as write enable (regular masked operation)
    VALU_MASK_CARRY, // mask used as carry
    VALU_MASK_SEL    // mask used as selector
} VALU_MASK_e;

typedef struct packed {
    VLAU_OP_e   op;
    VALU_MASK_e op_mask;
    logic       mask_res; // result is a mask
    logic       sat_res;  // saturate result for narrowing operations
    logic       signext;  // if operand needs sign extend
    logic [2:0] unused;
} VALU_OP_t; // 6 + 2 + 3 + 3 = 14 bit

// --------------------------------------------
//                VLSU Operands                
// --------------------------------------------
typedef enum logic [1:0] {
    VLSU_UNITSTRIDE,
    VLSU_STRIDED,
    VLSU_INDEXED
} VLSU_STRIDE_e;

typedef struct packed {
    logic         masked;
    logic         store;
    VLSU_STRIDE_e stride;
    VSEW_e        eew;
    logic [2:0]   nfields;
    logic [3:0]   unused;
} VLSU_OP_t; // 1 + 1 + 2 + 3 + 3 + 4 = 14 bits

// --------------------------------------------
//                VMUL Operands                
// --------------------------------------------
typedef enum logic [2:0] {
    VMUL_VMUL,   // regular multiplication
    VMUL_VMULH,  // multiplication retaining high part
    VMUL_VSMUL,  // multiplication with rounding and saturation
    VMUL_VMACC,  // multiply-add
    VMUL_VNMSUB  // multiply-sub
} VMUL_OPCODE_e;

typedef struct packed {
    logic         masked;
    VMUL_OPCODE_e op;
    logic         op1_signed;
    logic         op2_signed;
    logic         op2_is_vd;
    logic [6:0]   unused;
} VMUL_OP_t; // 1 + 2 + 4 + 7 = 14 bits

// --------------------------------------------
//                VMASK Operands               
// --------------------------------------------
typedef enum logic [3:0] {
    VMAND  , VMOR    , VMXOR,
    VMNAND , VMNOR   , VMXNOR,
    VMORNOT, VMANDNOT
} VMASK_OP_e;

typedef struct packed {
    logic       masked;
    VMASK_OP_e  op;
    logic [8:0] unused;
} VMASK_OP_t; // 5 + 9 = 14 bits

// --------------------------------------------
//                VSLD Operands                
// --------------------------------------------
typedef enum logic {
    VSLD_UP, VSLD_DOWN
} VSLD_DIR_e;

typedef struct packed {
    logic        masked;
    VSLD_DIR_e   dir;    // slide direction
    logic        slide1; // slide 1 element
    logic [10:0] unused;
} VSLD_OP_t; // 1 + 1 + 1 + 11 = 14 bits

// --------------------------------------------
//                VELEM Operands               
// --------------------------------------------
typedef enum logic [3:0] {
    VELEM_XMV,
    VELEM_VPOPC,
    VELEM_VFIRST,
    VELEM_VID,
    VELEM_VIOTA,
    VELEM_VRGATHER,
    VELEM_VCOMPRESS,
    VELEM_FLUSH,
    VELEM_VREDSUM,
    VELEM_VREDAND,
    VELEM_VREDOR,
    VELEM_VREDXOR,
    VELEM_VREDMINU,
    VELEM_VREDMIN,
    VELEM_VREDMAXU,
    VELEM_VREDMAX
} VELEM_OPCODE_t;

typedef struct packed {
    logic          masked;
    VELEM_OPCODE_t op;
    logic          signext;
    logic          xreg;
    logic [6:0]    unused;
} VELEM_OP_t; // 1 + 4 + 2 + 7 = 14 bits

// --------------------------------------------
//              VPU Function Unit              
// --------------------------------------------
typedef enum logic [3:0] {
    VNONE, VCFG, VALU, VMASK, VLSU, VMUL, VSLD, VELEM
} VPU_FU_t;

typedef union packed {
    logic [13:0] unused;
    VALU_OP_t    alu;
    VLSU_OP_t    lsu;
    VMASK_OP_t   mask;
    VMUL_OP_t    mul;
    VSLD_OP_t    sld;
    VELEM_OP_t   elem;
    VCFG_OP_t    cfg;
} VPU_MODE_t;

// --------------------------------------------
//            Vector Micro Operations          
// --------------------------------------------
typedef struct packed {
    logic        vreg;
    logic        xreg;
    REG_t        index;
    logic [31:0] xval;
} VS_REG_t;

typedef struct packed {
    logic vreg;
    REG_t index;
} VD_REG_t;

typedef struct packed {
    VPU_FU_t            fu;
    VPU_MODE_t          mode;
    VS_REG_t            rs1, rs2;
    VD_REG_t            rd;
    OP_WIDENARROW_e     widenarrow;
    VSEW_e              eew;
    VLMUL_e             emul;
    VXRM_e              vxrm;
    logic [VL_BITS-1:0] vl;
} VPU_uOP_t;

// --------------------------------------------
//           Vector Instruction Queue          
// --------------------------------------------
localparam int unsigned VIQ_DEPTH    = 8;
localparam int unsigned VIQ_TAG_BITS = $clog2(IQ_DEPTH);

typedef struct packed {
    logic     valid;
    VPU_uOP_t uOP;
} VIQ_ENTRY_t;

`endif