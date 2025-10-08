module VPU_decoder (
    // from CPU
    input  logic               vector_inst_valid_i,
    input  logic [31:0]        vector_inst_i,
    input  logic [31:0]        vector_xrs1_val_i,
    input  logic [31:0]        vector_xrs2_val_i,

    // from VCFG (current vector CSRs)
    input  VSEW_e              vsew_i,  // current SEW
    input  VLMUL_e             vlmul_i, // current register group multiplier
    input  VXRM_e              vxrm_i,  // current rounding mode
    input  logic [VL_BITS-1:0] vl_i,    // current vector length

    // to ISSUE
    output logic               decode_instr_valid_o,
    output VPU_uOP_t           decode_instr_o
);

    // --------------------------------------------
    //              Signal Declaration             
    // --------------------------------------------
    logic                   illegal_instr;
    logic                   illegal_operation;
    logic                   vtype_invalid;
    
    // register validity
    logic                   rs1_invalid, rs2_invalid, rd_invalid;
    logic                   vreg_invalid;
    logic [2:0]             reg_mask, reg_mask_narrow;
    
    // effective lmul
    logic                   emul_override;
    logic                   emul_invalid;
    VLMUL_e                 emul;

    // vl constrant
    EVL_POLICY_e            evl_policy;

    logic [31:0]            inst;
    logic [OPCODE_BITS-1:0] opcode;
    REG_t                   vs1, vs2, vd;
    logic [FUNC3_BITS -1:0] f3;
    logic [FUNC6_BITS -1:0] f6;
    logic [8:0]             vop;
    logic                   masked;
    VPU_uOP_t               decode_instr;

    // --------------------------------------------
    //                   Decoder                   
    // --------------------------------------------
    // output assignment
    assign decode_instr_valid_o = vector_inst_valid_i & (~illegal_instr) & (~illegal_operation);
    assign decode_instr_o       = decode_instr;

    // instruction decouple
    assign inst   = vector_inst_i;
    assign opcode = inst[`OPCODE];
    assign vs1    = REG_t'(inst[`RS1]);
    assign vs2    = REG_t'(inst[`RS2]);
    assign vd     = REG_t'(inst[`RD ]);
    assign f3     = inst[`FUNC3];
    assign f6     = inst[`FUNC6];
    assign vop    = {f3, f6};
    assign masked = ~inst[`VM];

    // decoder
    always_comb begin
        illegal_instr           = 1'b0;

        emul_override           = 1'b0;
        emul                    = VLMUL_e'(0);
        evl_policy              = EVL_DEFAULT;

        decode_instr.fu         = VNONE;
        decode_instr.mode       = VPU_MODE_t'(0);
        decode_instr.rs1        = VS_REG_t'(0);
        decode_instr.rs2        = VS_REG_t'(0);
        decode_instr.rd         = VD_REG_t'(0);
        decode_instr.widenarrow = OP_WIDENARROW_e'(0);
        decode_instr.vxrm       = VXRM_e'(0);

        unique case (opcode)
            // vector CSRs read write
            CSRS_OP : begin
                decode_instr.fu = VCFG;

                // select either rs1 or immediate value
                unique case (f3)
                    CSRRW_FUNC3  : decode_instr.rs1.xval = vector_xrs1_val_i;
                    CSRRS_FUNC3  : decode_instr.rs1.xval = vector_xrs1_val_i;
                    CSRRC_FUNC3  : decode_instr.rs1.xval = vector_xrs1_val_i;
                    CSRRWI_FUNC3 : decode_instr.rs1.xval = {27'd0, vs1};
                    CSRRSI_FUNC3 : decode_instr.rs1.xval = {27'd0, vs1};
                    CSRRCI_FUNC3 : decode_instr.rs1.xval = {27'd0, vs1};
                    default : ;
                endcase

                // slect csr operation
                unique case ({f3, inst[31:20]})
                    // read-write CSR
                    {CSRRW_FUNC3 , CSR_VSTART} : decode_instr.mode.cfg.csr_op = CFG_VSTART_WRITE;
                    {CSRRWI_FUNC3, CSR_VSTART} : decode_instr.mode.cfg.csr_op = CFG_VSTART_WRITE;
                    {CSRRS_FUNC3 , CSR_VSTART} : decode_instr.mode.cfg.csr_op = CFG_VSTART_SET;
                    {CSRRSI_FUNC3, CSR_VSTART} : decode_instr.mode.cfg.csr_op = CFG_VSTART_SET;
                    {CSRRC_FUNC3 , CSR_VSTART} : decode_instr.mode.cfg.csr_op = CFG_VSTART_CLEAR;
                    {CSRRCI_FUNC3, CSR_VSTART} : decode_instr.mode.cfg.csr_op = CFG_VSTART_CLEAR;

                    {CSRRW_FUNC3 , CSR_VXSAT } : decode_instr.mode.cfg.csr_op = CFG_VXSAT_WRITE;
                    {CSRRWI_FUNC3, CSR_VXSAT } : decode_instr.mode.cfg.csr_op = CFG_VXSAT_WRITE;
                    {CSRRS_FUNC3 , CSR_VXSAT } : decode_instr.mode.cfg.csr_op = CFG_VXSAT_SET;
                    {CSRRSI_FUNC3, CSR_VXSAT } : decode_instr.mode.cfg.csr_op = CFG_VXSAT_SET;
                    {CSRRC_FUNC3 , CSR_VXSAT } : decode_instr.mode.cfg.csr_op = CFG_VXSAT_CLEAR;
                    {CSRRCI_FUNC3, CSR_VXSAT } : decode_instr.mode.cfg.csr_op = CFG_VXSAT_CLEAR;

                    {CSRRW_FUNC3 , CSR_VXRM  } : decode_instr.mode.cfg.csr_op = CFG_VXRM_WRITE;
                    {CSRRWI_FUNC3, CSR_VXRM  } : decode_instr.mode.cfg.csr_op = CFG_VXRM_WRITE;
                    {CSRRS_FUNC3 , CSR_VXRM  } : decode_instr.mode.cfg.csr_op = CFG_VXRM_SET;
                    {CSRRSI_FUNC3, CSR_VXRM  } : decode_instr.mode.cfg.csr_op = CFG_VXRM_SET;
                    {CSRRC_FUNC3 , CSR_VXRM  } : decode_instr.mode.cfg.csr_op = CFG_VXRM_CLEAR;
                    {CSRRCI_FUNC3, CSR_VXRM  } : decode_instr.mode.cfg.csr_op = CFG_VXRM_CLEAR;

                    {CSRRW_FUNC3 , CSR_VCSR  } : decode_instr.mode.cfg.csr_op = CFG_VCSR_WRITE;
                    {CSRRWI_FUNC3, CSR_VCSR  } : decode_instr.mode.cfg.csr_op = CFG_VCSR_WRITE;
                    {CSRRS_FUNC3 , CSR_VCSR  } : decode_instr.mode.cfg.csr_op = CFG_VCSR_SET;
                    {CSRRSI_FUNC3, CSR_VCSR  } : decode_instr.mode.cfg.csr_op = CFG_VCSR_SET;
                    {CSRRC_FUNC3 , CSR_VCSR  } : decode_instr.mode.cfg.csr_op = CFG_VCSR_CLEAR;
                    {CSRRCI_FUNC3, CSR_VCSR  } : decode_instr.mode.cfg.csr_op = CFG_VCSR_CLEAR;

                    // read only CSR
                    {CSRRS_FUNC3 , CSR_VL}, {CSRRSI_FUNC3, CSR_VL},
                    {CSRRC_FUNC3 , CSR_VL}, {CSRRCI_FUNC3, CSR_VL} : begin
                        decode_instr.mode.cfg.csr_op = CFG_VL_READ;
                        illegal_instr                = (vs1 != x0); // attempts to write read-only CSR
                    end

                    {CSRRS_FUNC3 , CSR_VTYPE}, {CSRRSI_FUNC3, CSR_VTYPE},
                    {CSRRC_FUNC3 , CSR_VTYPE}, {CSRRCI_FUNC3, CSR_VTYPE} : begin
                        decode_instr.mode.cfg.csr_op = CFG_VTYPE_READ;
                        illegal_instr                = (vs1 != x0); // attempts to write read-only CSR
                    end

                    {CSRRS_FUNC3 , CSR_VLENB}, {CSRRSI_FUNC3, CSR_VLENB},
                    {CSRRC_FUNC3 , CSR_VLENB}, {CSRRCI_FUNC3, CSR_VLENB} : begin
                        decode_instr.mode.cfg.csr_op = CFG_VLENB_READ;
                        illegal_instr                = (vs1 != x0); // attempts to write read-only CSR
                    end

                    default : illegal_instr = 1'b1;
                endcase
            end

            // vector load/store (use LOAD-FP and STORE-FP)
            FLW_OP, FSW_OP : begin
                decode_instr.fu               = VLSU;
                decode_instr.mode.lsu.store   = (opcode == FSW_OP);
                decode_instr.mode.lsu.masked  = masked;
                decode_instr.mode.lsu.nfields = inst[`NF];

                // select source operands
                decode_instr.rs1.xreg = 1'b1;
                decode_instr.rs1.xval = vector_xrs1_val_i;
                decode_instr.rd.vreg  = 1'b1;
                decode_instr.rd.index = vd;

                // width field
                unique case ({inst[`MEW], f3})
                    4'b0000 : decode_instr.mode.lsu.eew = VSEW_8;
                    4'b0101 : decode_instr.mode.lsu.eew = VSEW_16;
                    4'b0110 : decode_instr.mode.lsu.eew = VSEW_32;
                    4'b0111 : decode_instr.mode.lsu.eew = VSEW_64;
                    default : illegal_instr = 1'b1;
                endcase

                // mop field
                unique case (inst[`MOP])
                    // unit-stride
                    2'b00 : begin
                        decode_instr.mode.lsu.stride = VLSU_UNITSTRIDE;

                        // lumop/sumop field
                        unique case (vs2)
                            // unit-strided load/store
                            5'b00000: begin
                                if (inst[`NF] != 3'd0) begin
                                    // Unit-strided segment stores result in strided stores
                                    decode_instr.mode.lsu.stride = VLSU_STRIDED;

                                    // set the byte stride (which is usually held in rs2) depending
                                    // on the element width and the number of fields as follows:
                                    //     stride = (EEW/8) * nf = (EEW/8) * (instr_i[31:29] + 1)
                                    unique case (f3) // width field
                                        3'b000  : decode_instr.rs2.xval = {28'b0, {1'b0, inst[`NF]} + 4'h1       }; // EEW 8
                                        3'b101  : decode_instr.rs2.xval = {27'b0, {1'b0, inst[`NF]} + 4'h1, 1'b0 }; // EEW 16
                                        3'b110  : decode_instr.rs2.xval = {26'b0, {1'b0, inst[`NF]} + 4'h1, 2'b00}; // EEW 32
                                        default : ;
                                    endcase
                                end
                            end

                            // fault-only-first load
                            5'b10000 : illegal_instr = (opcode == FSW_OP); // illegal for stores

                            // whole register load/store
                            5'b01000 : begin
                                emul_override                 = 1'b1;
                                evl_policy                    = EVL_MAX;
                                decode_instr.mode.lsu.nfields = 3'd0;

                                unique case (inst[`NF])
                                    3'b000  : emul          = LMUL_1;
                                    3'b001  : emul          = LMUL_2;
                                    3'b011  : emul          = LMUL_4;
                                    3'b111  : emul          = LMUL_8;
                                    default : illegal_instr = 1'b1;
                                endcase
                            end

                            // mask load/store
                            5'b01011 : begin
                                emul_override = 1'b1;
                                emul          = LMUL_1;
                                evl_policy    = EVL_MASK;
                            end

                            default : illegal_instr = 1'b1;
                        endcase
                    end

                    // strided load/store
                    2'b10 : begin
                        decode_instr.mode.lsu.stride = VLSU_STRIDED;
                        decode_instr.rs2.xreg        = 1'b1;
                        decode_instr.rs2.xval        = vector_xrs2_val_i;
                    end

                    // indexed load / store
                    2'b01, 2'b11 : begin
                        decode_instr.mode.lsu.stride = VLSU_INDEXED;
                        decode_instr.rs2.vreg        = 1'b1;
                        decode_instr.rs2.index       = vs2;
                    end
                endcase
            end

            // OP-V (not FP support)
            VECTOR_OP : begin
                // fisrt assume rd is from VREG
                // --> rd is a VREG for most instructions
                decode_instr.rd.vreg  = 1'b1;
                decode_instr.rd.index = vd;

                // select source operands
                unique case (f3)
                    OPIVV, OPFVV, OPMVV : begin
                        decode_instr.rs1.vreg  = 1'b1;
                        decode_instr.rs1.index = vs1;
                        decode_instr.rs2.vreg  = 1'b1;
                        decode_instr.rs2.index = vs2;
                    end

                    OPIVI : begin
                        decode_instr.rs1.xval  = (inst[31:26] inside {6'b001110, 6'b001111}) ? ({27'd0, vs1}) : ({{27{vs1[4]}}, vs1});
                        decode_instr.rs2.vreg  = 1'b1;
                        decode_instr.rs2.index = vs2;
                    end

                    OPIVX, OPMVX : begin
                        decode_instr.rs1.xreg  = 1'b1;
                        decode_instr.rs1.xval  = vector_xrs1_val_i;
                        decode_instr.rs2.vreg  = 1'b1;
                        decode_instr.rs2.index = vs2;
                    end

                    OPCFG : begin
                        decode_instr.rs1.xreg = (inst[31:30] != 2'b11);
                        decode_instr.rs1.xval = (decode_instr.rs1.xreg) ? (vector_xrs1_val_i) : ({{27{1'b0}}, vs1});
                        decode_instr.rs2.xreg = (inst[31:30] == 2'b10);
                        decode_instr.rs2.xval = (decode_instr.rs2.vreg) ? (vector_xrs2_val_i) : ({{21{1'b0}}, inst[30] & ~inst[31], inst[29:20]});
                    end

                    default : ; // nothing to do
                endcase

                // configuration instrcution
                if (f3 == OPCFG) begin
                    decode_instr.fu              = VCFG;
                    decode_instr.mode.cfg.csr_op = CFG_VSETVL;
                    decode_instr.rd.vreg         = 1'b0; // rd is an x register

                    // read out vtype register layout from from rs2 xval 
                    // --> rs2 field contains xval or imme
                    decode_instr.mode.cfg.vtype.vlmul = VLMUL_e'(decode_instr.rs2.xval[2:0]);
                    decode_instr.mode.cfg.vtype.vta   = decode_instr.rs2.xval[6];
                    decode_instr.mode.cfg.vtype.vma   = decode_instr.rs2.xval[7];

                    unique case (decode_instr.rs2.xval[5:3])
                        3'b000  : decode_instr.mode.cfg.vtype.vsew = VSEW_8;
                        3'b001  : decode_instr.mode.cfg.vtype.vsew = VSEW_16;
                        3'b010  : decode_instr.mode.cfg.vtype.vsew = VSEW_32;
                        3'b011  : decode_instr.mode.cfg.vtype.vsew = VSEW_64;
                        default : decode_instr.mode.cfg.vtype.vsew = VSEW_INVALID;
                    endcase

                    // if reserved bits of vtype is not zero
                    // --> we should set vill to 1 (set vsew as invalid)
                    if (decode_instr.rs2.xval[31:8] != 24'd0) begin
                        decode_instr.mode.cfg.vtype.vsew = VSEW_INVALID;
                    end

                    // AVL encoding (see spec 32.6.2)
                    // set up vl config (normal stripmining)
                    decode_instr.mode.cfg.vlmax   = 1'b0;
                    decode_instr.mode.cfg.keep_vl = 1'b0;

                    // special AVL encoding (only vsetvli, vsetvl)
                    if (vs1 == x0 && inst[31:30] != 2'b11) begin
                        decode_instr.mode.cfg.vlmax   = (vd != x0); // set vl to vlmax if rd is not x0
                        decode_instr.mode.cfg.keep_vl = (vd == x0); // keep exist vl   if rd is x0
                    end

                // arithmetic instruction
                end else begin
                    unique case (vop)
                        // --------------------------------------------
                        //    Vector Integer Arithmetic Instructions   
                        // --------------------------------------------
                        // 1. Vector Single-Width Integer Add and Subtract
                        VADD_VV, VADD_VI, VADD_VX : begin
                            decode_instr.fu               = VALU;
                            decode_instr.mode.alu.op      = VADD;
                            decode_instr.mode.alu.op_mask = (masked) ? (VALU_MASK_WRITE) : (VALU_MASK_NONE);
                        end

                        VSUB_VV, VSUB_VX : begin
                            decode_instr.fu               = VALU;
                            decode_instr.mode.alu.op      = VSUB;
                            decode_instr.mode.alu.op_mask = (masked) ? (VALU_MASK_WRITE) : (VALU_MASK_NONE);
                        end

                        VRSUB_VI, VRSUB_VX : begin
                            decode_instr.fu               = VALU;
                            decode_instr.mode.alu.op      = VRSUB;
                            decode_instr.mode.alu.op_mask = (masked) ? (VALU_MASK_WRITE) : (VALU_MASK_NONE);
                        end

                        // 2. Vector Widening Integer Add/Subtract
                        // * IMPORTANT : we not yet support widening or narrowing instruction
                        VWADDU_VV , VWADDU_VX , VWADD_VV , VWADD_VX,
                        VWSUBU_VV , VWSUBU_VX , VWSUB_VV , VWSUB_VX,
                        VWADDUW_VV, VWADDUW_VX, VWADDW_VV, VWADDW_VX,
                        VWSUBUW_VV, VWSUBUW_VX, VWSUBW_VV, VWSUBW_VX : begin
                            illegal_instr = 1'b1;
                        end

                        // 3. Vector Integer Extension (only support v[z|s]ext.vf2)
                        // * IMPORTANT : we not yet support widening or narrowing instruction
                        VXUNARY0_VV : begin
                            illegal_instr = 1'b1;
                        end

                        // 4. Vector Integer Add-with-Carry / Subtract-with-Borrow Instructions
                        VADC_VV, VADC_VI, VADC_VX : begin
                            decode_instr.fu               = VALU;
                            decode_instr.mode.alu.op      = VADD;
                            decode_instr.mode.alu.op_mask = (masked) ? (VALU_MASK_CARRY) : (VALU_MASK_NONE);;
                        end

                        VSBC_VV, VSBC_VX : begin
                            decode_instr.fu               = VALU;
                            decode_instr.mode.alu.op      = VSUB;
                            decode_instr.mode.alu.op_mask = (masked) ? (VALU_MASK_CARRY) : (VALU_MASK_NONE);;
                        end

                        VMADC_VV, VMADC_VI, VMADC_VX : begin
                            decode_instr.fu                = VALU;
                            decode_instr.mode.alu.op       = VADD;
                            decode_instr.mode.alu.op_mask  = (masked) ? (VALU_MASK_CARRY) : (VALU_MASK_NONE);
                            decode_instr.mode.alu.mask_res = 1'b1;
                        end

                        VMSBC_VV, VMSBC_VX : begin
                            decode_instr.fu                = VALU;
                            decode_instr.mode.alu.op       = VSUB;
                            decode_instr.mode.alu.op_mask  = (masked) ? (VALU_MASK_CARRY) : (VALU_MASK_NONE);
                            decode_instr.mode.alu.mask_res = 1'b1;
                        end

                        // 5. Vector Bitwise Logical Instructions
                        VAND_VV, VAND_VI, VAND_VX : begin
                            decode_instr.fu               = VALU;
                            decode_instr.mode.alu.op      = VAND;
                            decode_instr.mode.alu.op_mask = (masked) ? (VALU_MASK_WRITE) : (VALU_MASK_NONE);
                        end

                        VOR_VV, VOR_VI, VOR_VX : begin
                            decode_instr.fu               = VALU;
                            decode_instr.mode.alu.op      = VOR;
                            decode_instr.mode.alu.op_mask = (masked) ? (VALU_MASK_WRITE) : (VALU_MASK_NONE);
                        end

                        VXOR_VV, VXOR_VI, VXOR_VX : begin
                            decode_instr.fu               = VALU;
                            decode_instr.mode.alu.op      = VXOR;
                            decode_instr.mode.alu.op_mask = (masked) ? (VALU_MASK_WRITE) : (VALU_MASK_NONE);
                        end

                        // 6. Vector Single-Width Shift Instructions
                        VSLL_VV, VSLL_VI, VSLL_VX : begin
                            decode_instr.fu               = VALU;
                            decode_instr.mode.alu.op      = VSLL;
                            decode_instr.mode.alu.op_mask = (masked) ? (VALU_MASK_WRITE) : (VALU_MASK_NONE);
                        end

                        VSRL_VV, VSRL_VI, VSRL_VX : begin
                            decode_instr.fu               = VALU;
                            decode_instr.mode.alu.op      = VSRL;
                            decode_instr.mode.alu.op_mask = (masked) ? (VALU_MASK_WRITE) : (VALU_MASK_NONE);
                        end

                        VSRA_VV, VSRA_VI, VSRA_VX : begin
                            decode_instr.fu               = VALU;
                            decode_instr.mode.alu.op      = VSRA;
                            decode_instr.mode.alu.op_mask = (masked) ? (VALU_MASK_WRITE) : (VALU_MASK_NONE);
                        end

                        // 7. Vector Narrowing Integer Right Shift Instructions
                        // * IMPORTANT : we not yet support widening or narrowing instruction
                        VNSRL_VV, VNSRL_VI, VNSRL_VX,
                        VNSRA_VV, VNSRA_VI, VNSRA_VX : begin
                            illegal_instr = 1'b1;
                        end

                        // 8. Vector Integer Compare Instructions
                        VMSEQ_VV, VMSEQ_VI, VMSEQ_VX : begin
                            decode_instr.fu                = VALU;
                            decode_instr.mode.alu.op       = VMSEQ;
                            decode_instr.mode.alu.op_mask  = (masked) ? (VALU_MASK_WRITE) : (VALU_MASK_NONE);
                            decode_instr.mode.alu.mask_res = 1'b1;
                        end

                        VMSNE_VV, VMSNE_VI, VMSNE_VX : begin
                            decode_instr.fu                = VALU;
                            decode_instr.mode.alu.op       = VMSNE;
                            decode_instr.mode.alu.op_mask  = (masked) ? (VALU_MASK_WRITE) : (VALU_MASK_NONE);
                            decode_instr.mode.alu.mask_res = 1'b1;
                        end

                        VMSLTU_VV, VMSLTU_VX : begin
                            decode_instr.fu                = VALU;
                            decode_instr.mode.alu.op       = VMSLT;
                            decode_instr.mode.alu.op_mask  = (masked) ? (VALU_MASK_WRITE) : (VALU_MASK_NONE);
                            decode_instr.mode.alu.mask_res = 1'b1;
                        end

                        VMSLT_VV, VMSLT_VX : begin
                            decode_instr.fu                = VALU;
                            decode_instr.mode.alu.op       = VMSLT;
                            decode_instr.mode.alu.op_mask  = (masked) ? (VALU_MASK_WRITE) : (VALU_MASK_NONE);
                            decode_instr.mode.alu.mask_res = 1'b1;
                            decode_instr.mode.alu.signext  = 1'b1;
                        end

                        VMSLEU_VV, VMSLEU_VI, VMSLEU_VX : begin
                            decode_instr.fu                = VALU;
                            decode_instr.mode.alu.op       = VMSLE;
                            decode_instr.mode.alu.op_mask  = (masked) ? (VALU_MASK_WRITE) : (VALU_MASK_NONE);
                            decode_instr.mode.alu.mask_res = 1'b1;
                        end

                        VMSLE_VV, VMSLE_VI, VMSLE_VX : begin
                            decode_instr.fu                = VALU;
                            decode_instr.mode.alu.op       = VMSLE;
                            decode_instr.mode.alu.op_mask  = (masked) ? (VALU_MASK_WRITE) : (VALU_MASK_NONE);
                            decode_instr.mode.alu.mask_res = 1'b1;
                            decode_instr.mode.alu.signext  = 1'b1;
                        end

                        VMSGTU_VI, VMSGTU_VX : begin
                            decode_instr.fu                = VALU;
                            decode_instr.mode.alu.op       = VMSGT;
                            decode_instr.mode.alu.op_mask  = (masked) ? (VALU_MASK_WRITE) : (VALU_MASK_NONE);
                            decode_instr.mode.alu.mask_res = 1'b1;
                        end

                        VMSGT_VI, VMSGT_VX : begin
                            decode_instr.fu                = VALU;
                            decode_instr.mode.alu.op       = VMSGT;
                            decode_instr.mode.alu.op_mask  = (masked) ? (VALU_MASK_WRITE) : (VALU_MASK_NONE);
                            decode_instr.mode.alu.mask_res = 1'b1;
                            decode_instr.mode.alu.signext  = 1'b1;
                        end

                        // 9. Vector Integer Min/Max Instructions
                        VMINU_VV, VMINU_VX : begin
                            decode_instr.fu               = VALU;
                            decode_instr.mode.alu.op      = VMIN;
                            decode_instr.mode.alu.op_mask = (masked) ? (VALU_MASK_WRITE) : (VALU_MASK_NONE);
                        end

                        VMIN_VV, VMIN_VX : begin
                            decode_instr.fu               = VALU;
                            decode_instr.mode.alu.op      = VMIN;
                            decode_instr.mode.alu.op_mask = (masked) ? (VALU_MASK_WRITE) : (VALU_MASK_NONE);
                            decode_instr.mode.alu.signext = 1'b1;
                        end

                        VMAXU_VV, VMAXU_VX : begin
                            decode_instr.fu               = VALU;
                            decode_instr.mode.alu.op      = VMAX;
                            decode_instr.mode.alu.op_mask = (masked) ? (VALU_MASK_WRITE) : (VALU_MASK_NONE);
                        end

                        VMAX_VV, VMAX_VX : begin
                            decode_instr.fu               = VALU;
                            decode_instr.mode.alu.op      = VMAX;
                            decode_instr.mode.alu.op_mask = (masked) ? (VALU_MASK_WRITE) : (VALU_MASK_NONE);
                            decode_instr.mode.alu.signext = 1'b1;
                        end

                        // 10. Vector Single-Width Integer Multiply Instruction
                        VMULHU_VV, VMULHU_VX : begin
                            decode_instr.fu              = VMUL;
                            decode_instr.mode.mul.op     = VMUL_VMULH;
                            decode_instr.mode.mul.masked = masked;
                        end

                        VMUL_VV, VMUL_VX : begin
                            decode_instr.fu              = VMUL;
                            decode_instr.mode.mul.op     = VMUL_VMUL;
                            decode_instr.mode.mul.masked = masked;
                        end

                        VMULHSU_VV, VMULHSU_VX : begin
                            decode_instr.fu                  = VMUL;
                            decode_instr.mode.mul.op         = VMUL_VMULH;
                            decode_instr.mode.mul.op2_signed = 1'b1;
                            decode_instr.mode.mul.masked     = masked;
                        end

                        VMULH_VV, VMULH_VX : begin
                            decode_instr.fu                  = VMUL;
                            decode_instr.mode.mul.op         = VMUL_VMULH;
                            decode_instr.mode.mul.op1_signed = 1'b1;
                            decode_instr.mode.mul.op2_signed = 1'b1;
                            decode_instr.mode.mul.masked     = masked;
                        end

                        // 11. Vector Widening Integer Multiply Instructions
                        // * IMPORTANT : we not yet support widening or narrowing instruction
                        VWMULU_VV , VWMULU_VX,
                        VWMULSU_VV, VWMULSU_VX,
                        VWMUL_VV  , VWMUL_VX : begin
                            illegal_instr = 1'b1;
                        end

                        // 12. Vector Single-Width Integer Multiply-Add Instructions
                        VMADD_VV, VMADD_VX : begin
                            decode_instr.fu                 = VMUL;
                            decode_instr.mode.mul.op        = VMUL_VMACC;
                            decode_instr.mode.mul.op2_is_vd = 1'b1;
                            decode_instr.mode.mul.masked    = masked;
                        end

                        VNMSUB_VV, VNMSUB_VX : begin
                            decode_instr.fu                 = VMUL;
                            decode_instr.mode.mul.op        = VMUL_VNMSUB;
                            decode_instr.mode.mul.op2_is_vd = 1'b1;
                            decode_instr.mode.mul.masked    = masked;
                        end

                        VMACC_VV, VMACC_VX : begin
                            decode_instr.fu                 = VMUL;
                            decode_instr.mode.mul.op        = VMUL_VMACC;
                            decode_instr.mode.mul.masked    = masked;
                        end

                        VNMSAC_VV, VNMSAC_VX : begin
                            decode_instr.fu                 = VMUL;
                            decode_instr.mode.mul.op        = VMUL_VNMSUB;
                            decode_instr.mode.mul.masked    = masked;
                        end

                        // 13. Vector Widening Integer Multiply-Add Instructions
                        // * IMPORTANT : we not yet support widening or narrowing instruction
                        VWMACCU_VV , VWMACCU_VX , VWMACC_VV, VWMACC_VX,
                        VWMACCUS_VX, VWMACCSU_VV, VWMACCSU_VX : begin
                            illegal_instr = 1'b1;
                        end

                        // 14. Vector Integer Merge Instructions / Vector Integer Move Instructions
                        VMERGE_VV, VMERGE_VI, VMERGE_VX : begin
                            decode_instr.fu               = VALU;
                            decode_instr.mode.alu.op      = (masked) ? (VMERGE) : (VMV);
                            decode_instr.mode.alu.op_mask = (masked) ? (VALU_MASK_SEL) : (VALU_MASK_NONE);
                            decode_instr.rs2.vreg         = masked;
                        end

                        // --------------------------------------------
                        //       Vector Fixed-Point Instructions       
                        // --------------------------------------------
                        // 15. Vector Single-Width Saturating Add and Subtract
                        VSADDU_VV, VSADDU_VI, VSADDU_VX : begin
                            decode_instr.fu               = VALU;
                            decode_instr.mode.alu.op      = VSADDU;
                            decode_instr.mode.alu.op_mask = (masked) ? (VALU_MASK_WRITE) : (VALU_MASK_NONE);
                        end

                        VSADD_VV, VSADD_VI, VSADD_VX : begin
                            decode_instr.fu               = VALU;
                            decode_instr.mode.alu.op      = VSADD;
                            decode_instr.mode.alu.op_mask = (masked) ? (VALU_MASK_WRITE) : (VALU_MASK_NONE);
                            decode_instr.mode.alu.signext = 1'b1;
                        end

                        V_SSUBU_VV, V_SSUBU_VX : begin
                            decode_instr.fu               = VALU;
                            decode_instr.mode.alu.op      = V_SSUBU;
                            decode_instr.mode.alu.op_mask = (masked) ? (VALU_MASK_WRITE) : (VALU_MASK_NONE);
                        end

                        V_SSUB_VV, V_SSUB_VX : begin
                            decode_instr.fu               = VALU;
                            decode_instr.mode.alu.op      = V_SSUB;
                            decode_instr.mode.alu.op_mask = (masked) ? (VALU_MASK_WRITE) : (VALU_MASK_NONE);
                            decode_instr.mode.alu.signext = 1'b1;
                        end

                        // 16. Vector Single-Width Averaging Add and Subtract
                        VAADDU_VV, VAADDU_VX : begin
                            decode_instr.fu               = VALU;
                            decode_instr.mode.alu.op      = VAADD;
                            decode_instr.mode.alu.op_mask = (masked) ? (VALU_MASK_WRITE) : (VALU_MASK_NONE);
                            decode_instr.vxrm             = vxrm_i;
                        end

                        VAADD_VV, VAADD_VX : begin
                            decode_instr.fu               = VALU;
                            decode_instr.mode.alu.op      = VAADD;
                            decode_instr.mode.alu.op_mask = (masked) ? (VALU_MASK_WRITE) : (VALU_MASK_NONE);
                            decode_instr.mode.alu.signext = 1'b1;
                            decode_instr.vxrm             = vxrm_i;
                        end

                        VASUBU_VV, VASUBU_VX : begin
                            decode_instr.fu               = VALU;
                            decode_instr.mode.alu.op      = VASUB;
                            decode_instr.mode.alu.op_mask = (masked) ? (VALU_MASK_WRITE) : (VALU_MASK_NONE);
                            decode_instr.vxrm             = vxrm_i;
                        end

                        VASUB_VV, VASUB_VX : begin
                            decode_instr.fu               = VALU;
                            decode_instr.mode.alu.op      = VASUB;
                            decode_instr.mode.alu.op_mask = (masked) ? (VALU_MASK_WRITE) : (VALU_MASK_NONE);
                            decode_instr.mode.alu.signext = 1'b1;
                            decode_instr.vxrm             = vxrm_i;
                        end

                        // 17. Vector Single-Width Fractional Multiply with Rounding and Saturation
                        VSMUL_VV, VSMUL_VX : begin
                            decode_instr.fu                  = VMUL;
                            decode_instr.mode.mul.op         = VMUL_VSMUL;
                            decode_instr.mode.mul.op1_signed = 1'b1;
                            decode_instr.mode.mul.op2_signed = 1'b1;
                            decode_instr.mode.mul.masked     = masked;
                            decode_instr.vxrm                = vxrm_i;
                        end

                        // 18. Vector Single-Width Scaling Shift Instructions
                        // * IMPORTANT : we not yet support this one
                        V_SSRL_VV, V_SSRL_VI, V_SSRL_VX,
                        V_SSRA_VV, V_SSRA_VI, V_SSRA_VX : begin
                            illegal_instr = 1'b1;
                        end

                        // 19. Vector Narrowing Fixed-Point Clip Instructions
                        // * IMPORTANT : we not yet support widening or narrowing instruction
                        VNCLIPU_VV, VNCLIPU_VI, VNCLIPU_VX,
                        VNCLIP_VV , VNCLIP_VI , VNCLIP_VX : begin
                            illegal_instr = 1'b1;
                        end

                        // --------------------------------------------
                        //        Vector Reduction Instructions        
                        // --------------------------------------------
                        // 20. Vector Single-Width Integer Reduction Instructions
                        VREDSUM_VV : begin
                            decode_instr.fu               = VELEM;
                            decode_instr.mode.elem.op     = VELEM_VREDSUM;
                            decode_instr.mode.elem.masked = masked;
                        end

                        /*
                        VREDAND_VV : begin
                            decode_instr.fu               = VELEM;
                            decode_instr.mode.elem.op     = VELEM_VREDAND;
                            decode_instr.mode.elem.masked = masked;
                        end

                        VREDOR_VV : begin
                            decode_instr.fu               = VELEM;
                            decode_instr.mode.elem.op     = VELEM_VREDOR;
                            decode_instr.mode.elem.masked = masked;
                        end

                        VREDXOR_VV : begin
                            decode_instr.fu               = VELEM;
                            decode_instr.mode.elem.op     = VELEM_VREDXOR;
                            decode_instr.mode.elem.masked = masked;
                        end

                        VREDMINU_VV : begin
                            decode_instr.fu               = VELEM;
                            decode_instr.mode.elem.op     = VELEM_VREDMINU;
                            decode_instr.mode.elem.masked = masked;
                        end

                        VREDMIN_VV : begin
                            decode_instr.fu               = VELEM;
                            decode_instr.mode.elem.op     = VELEM_VREDMIN;
                            decode_instr.mode.elem.masked = masked;
                        end

                        VREDMAXU_VV : begin
                            decode_instr.fu               = VELEM;
                            decode_instr.mode.elem.op     = VELEM_VREDMAXU;
                            decode_instr.mode.elem.masked = masked;
                        end

                        VREDAMX_VV : begin
                            decode_instr.fu               = VELEM;
                            decode_instr.mode.elem.op     = VELEM_VREDMAX;
                            decode_instr.mode.elem.masked = masked;
                        end
                        */

                        // 21. Vector Widening Integer Reduction Instructions
                        // * IMPORTANT : we not yet support widening or narrowing instruction
                        VWREDSUMU_VV, VWREDSUM_VV : begin
                            illegal_instr = 1'b1;
                        end

                        // --------------------------------------------
                        //           Vector Mask Instructions          
                        // --------------------------------------------
                        // 22. Vector Mask-Register Logical Instructions
                        VMANDNOT_VV : begin
                            decode_instr.fu           = VMASK;
                            decode_instr.mode.mask.op = VMANDNOT;
                        end

                        VMAND_VV : begin
                            decode_instr.fu           = VMASK;
                            decode_instr.mode.mask.op = VMAND;
                        end

                        VMOR_VV : begin
                            decode_instr.fu           = VMASK;
                            decode_instr.mode.mask.op = VMOR;
                        end

                        VMXOR_VV : begin
                            decode_instr.fu           = VMASK;
                            decode_instr.mode.mask.op = VMXOR;
                        end

                        VMORNOT_VV : begin
                            decode_instr.fu           = VMASK;
                            decode_instr.mode.mask.op = VMORNOT;
                        end

                        VMNAND_VV : begin
                            decode_instr.fu           = VMASK;
                            decode_instr.mode.mask.op = VMNAND;
                        end

                        VMNOR_VV : begin
                            decode_instr.fu           = VMASK;
                            decode_instr.mode.mask.op = VMNOR;
                        end

                        VMXNOR_VV : begin
                            decode_instr.fu           = VMASK;
                            decode_instr.mode.mask.op = VMXNOR;
                        end

                        /*
                        // 23. vmsbf, vmsof, vmsif, viota, vid
                        VMUNARY0_VV : begin
                            if (vs1[4]) begin
                                decode_instr.fu               = VELEM;
                                decode_instr.mode.elem.op     = (vs1[0]) ? (VELEM_VID) : (VELEM_VIOTA);
                                decode_instr.mode.elem.masked = masked;
                                decode_instr.rs1.vreg         = 1'b0;
                                decode_instr.rs2.vreg         = ~vs1[0]; // vid has no rs2

                                illegal_instr = (vs1[3:1] != 3'b000);
                            end
                        end

                        // 24. vmv.x.s(permutation), vpopc(mask), vfirst(mask)
                        VWXUNARY0_VV : begin
                            decode_instr.fu = VELEM;

                            unique case (vs1)
                                5'b00000 : decode_instr.mode.elem.op = VELEM_XMV;
                                5'b10000 : decode_instr.mode.elem.op = VELEM_VPOPC;
                                5'b10001 : decode_instr.mode.elem.op = VELEM_VFIRST;
                                default  : illegal_instr = 1'b1;
                            endcase

                            decode_instr.mode.elem.xreg   = 1'b1;
                            decode_instr.mode.elem.masked = masked;
                            decode_instr.rs1.vreg         = 1'b0;
                            decode_instr.rd.vreg          = 1'b0;
                        end
                        */

                        // --------------------------------------------
                        //       Vector Permutation Instructions       
                        // --------------------------------------------
                        // 25. Integer Scalar Move Instructions (vmv.s.x)
                        VRXUNARY0_VX : begin
                            if (vs2 == 5'd0) begin
                                decode_instr.fu          = VALU;
                                decode_instr.mode.alu.op = VMV;
                                evl_policy               = EVL_1;
                            end else begin
                                illegal_instr = 1'b1;
                            end
                        end

                        // 26. Vector Slide Instructions
                        VSLIDEUP_VI, VSLIDEUP_VX : begin
                            decode_instr.fu              = VSLD;
                            decode_instr.mode.sld.dir    = VSLD_UP;
                            decode_instr.mode.sld.masked = masked;
                        end

                        VSLIDEDOWN_VI, VSLIDEDOWN_VX : begin
                            decode_instr.fu              = VSLD;
                            decode_instr.mode.sld.dir    = VSLD_DOWN;
                            decode_instr.mode.sld.masked = masked;
                        end

                        VSLIDE1UP_VX : begin
                            decode_instr.fu              = VSLD;
                            decode_instr.mode.sld.dir    = VSLD_UP;
                            decode_instr.mode.sld.slide1 = 1'b1;
                            decode_instr.mode.sld.masked = masked;
                        end

                        VSLIDE1DOWN_VX : begin
                            decode_instr.fu              = VSLD;
                            decode_instr.mode.sld.dir    = VSLD_DOWN;
                            decode_instr.mode.sld.slide1 = 1'b1;
                            decode_instr.mode.sld.masked = masked;
                        end

                        /*
                        // 27. Vector Register Gather Instructions
                        VRGATHER_VV, VRGATHER_VI, VRGATHER_VX : begin
                            decode_instr.fu               = VELEM;
                            decode_instr.mode.elem.op     = VELEM_VRGATHER;
                            decode_instr.mode.elem.masked = masked;
                        end

                        // 28. Vector Compress Instruction
                        VCOMPRESS_VV : begin
                            decode_instr.fu               = VELEM;
                            decode_instr.mode.elem.op     = VELEM_VCOMPRESS;
                            decode_instr.mode.elem.masked = masked;
                        end
                        */

                        // 29. Whole Vector Register Move
                        VMVNRR_VI : begin
                            emul_override = 1'b1;
                            evl_policy    = EVL_MAX;

                            unique case (vs1)
                                5'b00000 : emul          = LMUL_1;
                                5'b00001 : emul          = LMUL_2;
                                5'b00011 : emul          = LMUL_4;
                                5'b00111 : emul          = LMUL_8;
                                default  : illegal_instr = 1'b1;
                            endcase

                            decode_instr.fu               = VALU;
                            decode_instr.mode.alu.op      = VMVR;
                            decode_instr.mode.alu.op_mask = VALU_MASK_NONE;
                        end

                        default : illegal_instr = 1'b1;
                    endcase
                end
            end

            default : illegal_instr = 1'b1; // nothing to do
        endcase
    end

    // --------------------------------------------
    //           Setup esew / emul / evl           
    // --------------------------------------------
    always_comb begin
        emul_invalid      = 1'b0;
        decode_instr.eew  = vsew_i;
        decode_instr.emul = vlmul_i;
        decode_instr.vl   = vl_i;

        if (decode_instr.fu == VLSU) begin
            // ---------------------------------------------------------------------------------
            // Note that the spec states:
            // Vector loads and stores have an EEW encoded directly in the instruction.
            // The corresponding EMUL is calculated as EMUL = (EEW/SEW)*LMUL.
            // If the EMUL would be out of range (EMUL>8 or EMUL<1/8), the instruction encoding
            // is reserved. The vector register groups must have legal register specifiers for
            // the selected EMUL, otherwise the instruction encoding is reserved.
            // ---------------------------------------------------------------------------------
            decode_instr.eew = decode_instr.mode.lsu.eew;

            unique case ({decode_instr.mode.lsu.eew, vsew_i})
                // EEW / SEW = 1 / 8
                {VSEW_8, VSEW_64} : begin
                    unique case (vlmul_i)
                        LMUL_1  : decode_instr.emul = LMUL_F8;
                        LMUL_2  : decode_instr.emul = LMUL_F4;
                        LMUL_4  : decode_instr.emul = LMUL_F2;
                        LMUL_8  : decode_instr.emul = LMUL_1;
                        default : emul_invalid      = 1'b1;
                    endcase
                end

                // EEW / SEW = 1 / 4
                {VSEW_8 , VSEW_32}, {VSEW_16, VSEW_64} : begin
                    unique case (vlmul_i)
                        LMUL_F2 : decode_instr.emul = LMUL_F8;
                        LMUL_1  : decode_instr.emul = LMUL_F4;
                        LMUL_2  : decode_instr.emul = LMUL_F2;
                        LMUL_4  : decode_instr.emul = LMUL_1;
                        LMUL_8  : decode_instr.emul = LMUL_2;
                        default : emul_invalid      = 1'b1;
                    endcase
                end

                // EEW / SEW = 1 / 2
                {VSEW_8 , VSEW_16}, {VSEW_16, VSEW_32}, {VSEW_32, VSEW_64} : begin
                    unique case (vlmul_i)
                        LMUL_F4 : decode_instr.emul = LMUL_F8;
                        LMUL_F2 : decode_instr.emul = LMUL_F4;
                        LMUL_1  : decode_instr.emul = LMUL_F2;
                        LMUL_2  : decode_instr.emul = LMUL_1;
                        LMUL_4  : decode_instr.emul = LMUL_2;
                        LMUL_8  : decode_instr.emul = LMUL_4;
                        default : emul_invalid      = 1'b1;
                    endcase
                end

                // EEW / SEW = 1
                {VSEW_8 , VSEW_8}, {VSEW_16, VSEW_16}, {VSEW_32, VSEW_32}, {VSEW_64, VSEW_64} : begin
                    unique case (vlmul_i)
                        LMUL_F8 : decode_instr.emul = LMUL_F8;
                        LMUL_F4 : decode_instr.emul = LMUL_F4;
                        LMUL_F2 : decode_instr.emul = LMUL_F2;
                        LMUL_1  : decode_instr.emul = LMUL_1;
                        LMUL_2  : decode_instr.emul = LMUL_2;
                        LMUL_4  : decode_instr.emul = LMUL_4;
                        LMUL_8  : decode_instr.emul = LMUL_8;
                        default : emul_invalid      = 1'b1;
                    endcase
                end

                // EEW / SEW = 2
                {VSEW_16, VSEW_8}, {VSEW_32, VSEW_16}, {VSEW_64, VSEW_32}: begin
                    unique case (vlmul_i)
                        LMUL_F8 : decode_instr.emul = LMUL_F4;
                        LMUL_F4 : decode_instr.emul = LMUL_F2;
                        LMUL_F2 : decode_instr.emul = LMUL_1;
                        LMUL_1  : decode_instr.emul = LMUL_2;
                        LMUL_2  : decode_instr.emul = LMUL_4;
                        LMUL_4  : decode_instr.emul = LMUL_8;
                        default : emul_invalid      = 1'b1;
                    endcase
                end

                // EEW / SEW = 4
                {VSEW_32, VSEW_8}, {VSEW_64, VSEW_16} : begin
                    unique case (vlmul_i)
                        LMUL_F8 : decode_instr.emul = LMUL_F2;
                        LMUL_F4 : decode_instr.emul = LMUL_1;
                        LMUL_F2 : decode_instr.emul = LMUL_2;
                        LMUL_1  : decode_instr.emul = LMUL_4;
                        LMUL_2  : decode_instr.emul = LMUL_8;
                        default : emul_invalid      = 1'b1;
                    endcase
                end

                // EEW / SEW = 8
                {VSEW_64, VSEW_8} : begin
                    unique case (vlmul_i)
                        LMUL_F8 : decode_instr.emul = LMUL_1;
                        LMUL_F4 : decode_instr.emul = LMUL_2;
                        LMUL_F2 : decode_instr.emul = LMUL_4;
                        LMUL_1  : decode_instr.emul = LMUL_8;
                        default : emul_invalid      = 1'b1;
                    endcase
                end

                default : emul_invalid = 1'b1;
            endcase
        end

        // some instruction ignore current emul setup
        // and use its own emul
        if (emul_override) begin
            decode_instr.emul = emul;
        end

        // some instruction have different policy to determine vl
        // but most inst use default vl (EVL_DEFAULT)
        unique case (evl_policy)
            EVL_1    : decode_instr.vl = VL_BITS'(1);
            EVL_MASK : decode_instr.vl = {3'd0, vl_i[VL_BITS-1:3]}; // ceil(VL/8)
            EVL_MAX  : decode_instr.vl = (VL_BITS'(VLEN) >> (VL_BITS'(8) << decode_instr.mode.lsu.eew) ) << (decode_instr.emul); // evl = NFIELDS(emul) * VLEN / EEW
            default  : ;
        endcase
    end

    // --------------------------------------------
    //     Check validity of register addresses    
    // --------------------------------------------
    // step 1. find out reg address masks (lower bits that must be 0) based on EMUL:
    always_comb begin
        reg_mask        = 3'd0;
        reg_mask_narrow = 3'd0;

        unique case (decode_instr.emul)
            LMUL_1 : begin
                reg_mask        = 3'b000;
                reg_mask_narrow = 3'b000; // fractional EMUL
            end

            LMUL_2 : begin
                reg_mask        = 3'b001;
                reg_mask_narrow = 3'b000;
            end

            LMUL_4 : begin
                reg_mask        = 3'b011;
                reg_mask_narrow = 3'b001;
            end

            LMUL_8 : begin
                reg_mask        = 3'b111;
                reg_mask_narrow = 3'b011;
            end

            default : ;
        endcase
    end

    // step 2. check rs1, rs2, rd base on mask reg address
    always_comb begin
        rs1_invalid = 1'b0;
        rs2_invalid = 1'b0;
        rd_invalid  = 1'b0;

        unique case (decode_instr.widenarrow)
            OP_SINGLEWIDTH : begin
                rs1_invalid = (vs1 & {2'b00, reg_mask       }) != x0;
                rs2_invalid = (vs2 & {2'b00, reg_mask       }) != x0;
                rd_invalid  = (vd  & {2'b00, reg_mask       }) != x0;
            end

            OP_WIDENING : begin
                rs1_invalid = (vs1 & {2'b00, reg_mask_narrow}) != x0;
                rs2_invalid = (vs2 & {2'b00, reg_mask_narrow}) != x0;
                rd_invalid  = (vd  & {2'b00, reg_mask       }) != x0;
            end

            OP_WIDENING_VS2 : begin
                rs1_invalid = (vs1 & {2'b00, reg_mask_narrow}) != x0;
                rs2_invalid = (vs2 & {2'b00, reg_mask       }) != x0;
                rd_invalid  = (vd  & {2'b00, reg_mask       }) != x0;
            end

            OP_NARROWING : begin
                rs1_invalid = (vs1 & {2'b00, reg_mask       }) != x0;
                rs2_invalid = (vs2 & {2'b00, reg_mask       }) != x0;
                rd_invalid  = (vd  & {2'b00, reg_mask_narrow}) != x0;
            end

            default : ; // nothing to do
        endcase

        // compare type instruction will produce mask -> rd always valid
        if (decode_instr.fu == VALU && decode_instr.mode.alu.mask_res) begin
            rd_invalid = 1'b0;
        end

        if (decode_instr.fu == VELEM) begin
            unique case (decode_instr.mode.elem.op)
                // reduction instructions read the init value from vs1,
                // which is a single vreg rather than a vreg group, and
                // also write to a single vreg rather than a vreg group
                VELEM_VREDSUM , VELEM_VREDAND, VELEM_VREDOR  , VELEM_VREDXOR,
                VELEM_VREDMINU, VELEM_VREDMIN, VELEM_VREDMAXU, VELEM_VREDMAX : begin
                    rs1_invalid = 1'b0;
                    rd_invalid  = 1'b0;
                end

                VELEM_VRGATHER : ; // nothing to do

                // except for vrgather and the reduction instructions,
                // all remaining ELEM instructions read a mask from vs2,
                // which is a single vreg rather than a vreg group
                default : rs2_invalid = 1'b0;
            endcase
        end

        // register addresses are always valid if it is not a vector register:
        if (~decode_instr.rs1.vreg) rs1_invalid = 1'b0;
        if (~decode_instr.rs2.vreg) rs2_invalid = 1'b0;
        if (~decode_instr.rd.vreg ) rd_invalid  = 1'b0;
    end

    // --------------------------------------------
    //           Check operation illegal           
    // --------------------------------------------
    // operation illegal (invalid vtype, invalid EMUL, or register addresses for the current configuration)
    assign vtype_invalid     = (vsew_i == VSEW_INVALID);
    assign vreg_invalid      = (rs1_invalid || rs2_invalid || rd_invalid);
    assign illegal_operation = (decode_instr.fu != VCFG) && (vreg_invalid || vtype_invalid || emul_invalid);

endmodule