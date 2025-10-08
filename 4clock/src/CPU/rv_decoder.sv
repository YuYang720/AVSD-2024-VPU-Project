module rv_decoder (
    input  FETCH_ENTRY_t fetch_entry_i,
    output uOP_t         decode_instr_o
);

    // --------------------------------------------
    //              Signal Declaration             
    // --------------------------------------------
    logic [31:0]            inst;
    logic [OPCODE_BITS-1:0] opcode;
    REG_t                   rs1, rs2, rs3, rd;
    logic                   f1;
    logic [FUNC3_BITS -1:0] f3;
    logic [FUNC7_BITS -1:0] f7;
    logic [31:0]            itype_imm, stype_imm, btype_imm, utype_imm, jtype_imm;
    uOP_t                   decode_instr;

    // --------------------------------------------
    //        Decoder / Immediate Generation       
    // --------------------------------------------
    // output assignment
    assign decode_instr_o = (fetch_entry_i.valid) ? (decode_instr) : (uOP_t'(0));

    // instruction decouple
    assign inst   = fetch_entry_i.inst;
    assign opcode = inst[`OPCODE];
    assign rs1    = REG_t'(inst[`RS1]);
    assign rs2    = REG_t'(inst[`RS2]);
    assign rs3    = REG_t'(inst[`RS3]);
    assign rd     = REG_t'(inst[`RD ]);
    assign f1     = inst[20];
    assign f3     = inst[`FUNC3];
    assign f7     = inst[`FUNC7];

    // decoder
    always_comb begin
        decode_instr.valid    = 1'b0;
        decode_instr.pc       = fetch_entry_i.pc;
        decode_instr.fu       = NONE;
        decode_instr.op       = _ADD;
        decode_instr.rs1      = x0;
        decode_instr.rs2      = x0;
        decode_instr.rs3      = x0;
        decode_instr.rd       = x0;
        decode_instr.use_fpr  = 4'd0;
        decode_instr.use_pc   = 1'b0;
        decode_instr.use_imme = 1'b0;

        unique case (opcode)
            RTYPE_OP : begin
                decode_instr.fu  = (f7[0]) ? (GMUL) : (GALU);
                decode_instr.rs1 = rs1;
                decode_instr.rs2 = rs2;
                decode_instr.rd  = rd;

                unique case ({f7[0], f3})
                    {1'b0, ADD_FUNC3 } : decode_instr.op = (f7[5]) ? (_SUB) : (_ADD);
                    {1'b0, SLL_FUNC3 } : decode_instr.op = _SLL;
                    {1'b0, SLT_FUNC3 } : decode_instr.op = _LT;
                    {1'b0, SLTU_FUNC3} : decode_instr.op = _LTU;
                    {1'b0, XOR_FUNC3 } : decode_instr.op = _XOR;
                    {1'b0, SRL_FUNC3 } : decode_instr.op = (f7[5]) ? (_SRA) : (_SRL);
                    {1'b0, OR_FUNC3  } : decode_instr.op = _OR;
                    {1'b0, AND_FUNC3 } : decode_instr.op = _AND;
                    {1'b1, ADD_FUNC3 } : decode_instr.op = _MUL;
                    {1'b1, SLL_FUNC3 } : decode_instr.op = _MULH;
                    {1'b1, SLT_FUNC3 } : decode_instr.op = _MULHSU;
                    {1'b1, SLTU_FUNC3} : decode_instr.op = _MULHU;
                    default            : decode_instr.op = _ADD;
                endcase
            end

            ITYPE_OP : begin
                decode_instr.fu       = GALU;
                decode_instr.rs1      = rs1;
                decode_instr.rd       = rd;
                decode_instr.use_imme = 1'b1;

                unique case (f3)
                    ADD_FUNC3  : decode_instr.op = _ADD;
                    SLL_FUNC3  : decode_instr.op = _SLL;
                    SLT_FUNC3  : decode_instr.op = _LT;
                    SLTU_FUNC3 : decode_instr.op = _LTU;
                    XOR_FUNC3  : decode_instr.op = _XOR;
                    SRL_FUNC3  : decode_instr.op = (f7[5]) ? (_SRA) : (_SRL);
                    OR_FUNC3   : decode_instr.op = _OR;
                    AND_FUNC3  : decode_instr.op = _AND;
                endcase
            end

            LOAD_OP : begin
                decode_instr.fu       = GLSU;
                decode_instr.rs1      = rs1;
                decode_instr.rd       = rd;
                decode_instr.use_imme = 1'b1;

                unique case (f3)
                    LB_FUNC3  : decode_instr.op= _LB;
                    LH_FUNC3  : decode_instr.op= _LH;
                    LW_FUNC3  : decode_instr.op= _LW;
                    LBU_FUNC3 : decode_instr.op= _LBU;
                    LHU_FUNC3 : decode_instr.op= _LHU;
                    default   : decode_instr.op= _ADD;
                endcase
            end

            JALR_OP : begin
                decode_instr.fu     = BRU;
                decode_instr.op     = _JALR;
                decode_instr.rs1    = rs1;
                decode_instr.rd     = rd;
                decode_instr.use_pc = 1'b1;
            end

            STYPE_OP : begin
                decode_instr.fu       = GLSU;
                decode_instr.rs1      = rs1;
                decode_instr.rs2      = rs2;
                decode_instr.use_imme = 1'b1;

                unique case (f3)
                    SB_FUNC3 : decode_instr.op = _SB;
                    SH_FUNC3 : decode_instr.op = _SH;
                    SW_FUNC3 : decode_instr.op = _SW;
                    default  : decode_instr.op = _ADD;
                endcase
            end

            BTYPE_OP : begin
                decode_instr.fu  = BRU;
                decode_instr.rs1 = rs1;
                decode_instr.rs2 = rs2;
                
                unique case (f3)
                    BEQ_FUNC3  : decode_instr.op = _EQ;
                    BNE_FUNC3  : decode_instr.op = _NE;
                    BLT_FUNC3  : decode_instr.op = _LT;
                    BGE_FUNC3  : decode_instr.op = _GE;
                    BLTU_FUNC3 : decode_instr.op = _LTU;
                    BGEU_FUNC3 : decode_instr.op = _GEU;
                    default    : decode_instr.op = _ADD;
                endcase
            end

            AUIPC_OP : begin
                decode_instr.fu       = GALU;
                decode_instr.op       = _ADD;
                decode_instr.rd       = rd;
                decode_instr.use_pc   = 1'b1;
                decode_instr.use_imme = 1'b1;
            end

            LUI_OP : begin
                decode_instr.fu       = GALU;
                decode_instr.op       = _ADD;
                decode_instr.rd       = rd;
                decode_instr.use_imme = 1'b1;
            end

            JAL_OP : begin
                decode_instr.fu     = BRU;
                decode_instr.op     = _JAL;
                decode_instr.rd     = rd;
                decode_instr.use_pc = 1'b1;
            end

            FLW_OP : begin
                if (f3 == FLS_FUNC3) begin
                    decode_instr.fu       = GLSU;
                    decode_instr.op       = _LW;
                    decode_instr.rs1      = rs1;
                    decode_instr.rd       = rd;
                    decode_instr.use_fpr  = 4'b0001;
                    decode_instr.use_imme = 1'b1;
                end else begin
                    decode_instr.fu  = VPU;
                    decode_instr.rs1 = rs1;

                    if (inst[`MOP] == 2'b10) begin
                        decode_instr.rs2 = rs2;
                    end
                end
            end

            FSW_OP : begin
                if (f3 == FLS_FUNC3) begin
                    decode_instr.fu       = GLSU;
                    decode_instr.op       = _SW;
                    decode_instr.rs1      = rs1;
                    decode_instr.rs2      = rs2;
                    decode_instr.use_fpr  = 4'b0010;
                    decode_instr.use_imme = 1'b1;
                end else begin
                    decode_instr.fu  = VPU;
                    decode_instr.rs1 = rs1;

                    if (inst[`MOP] == 2'b10) begin
                        decode_instr.rs2 = rs2;
                    end
                end
            end

            FMADD_OP   : begin
                decode_instr.fu      = FPU;
                decode_instr.op      = _FMADD;
                decode_instr.rs3     = rs3;
                decode_instr.rs1     = rs1;
                decode_instr.rs2     = rs2;
                decode_instr.rd      = rd;
                decode_instr.use_fpr = 4'b1111;
            end

            FMSUB_OP   : begin
                decode_instr.fu      = FPU;
                decode_instr.op      = _FMSUB;
                decode_instr.rs3     = rs3;
                decode_instr.rs1     = rs1;
                decode_instr.rs2     = rs2;
                decode_instr.rd      = rd;
                decode_instr.use_fpr = 4'b1111;
            end

            FNMADD_OP  : begin
                decode_instr.fu      = FPU;
                decode_instr.op      = _FNMADD;
                decode_instr.rs3     = rs3;
                decode_instr.rs1     = rs1;
                decode_instr.rs2     = rs2;
                decode_instr.rd      = rd;
                decode_instr.use_fpr = 4'b1111;
            end

            FNMSUB_OP  : begin
                decode_instr.fu      = FPU;
                decode_instr.op      = _FNMSUB;
                decode_instr.rs3     = rs3;
                decode_instr.rs1     = rs1;
                decode_instr.rs2     = rs2;
                decode_instr.rd      = rd;
                decode_instr.use_fpr = 4'b1111;
            end
            
            F_RTYPE_OP : begin
                decode_instr.fu = FPU;

                unique case ({f7[6:2]})
                    {5'b00000} : begin
                        decode_instr.op      = _FADDS;
                        decode_instr.rs1     = rs1;
                        decode_instr.rs2     = rs2;
                        decode_instr.rd      = rd;
                        decode_instr.use_fpr = 4'b0111;
                    end

                    {5'b00001} : begin
                        decode_instr.op      = _FSUBS;
                        decode_instr.rs1     = rs1;
                        decode_instr.rs2     = rs2;
                        decode_instr.rd      = rd;
                        decode_instr.use_fpr = 4'b0111;
                    end

                    {5'b00010} : begin
                        decode_instr.op      = _FMULS;
                        decode_instr.rs1     = rs1;
                        decode_instr.rs2     = rs2;
                        decode_instr.rd      = rd;
                        decode_instr.use_fpr = 4'b0111;
                    end

                    {5'b00100} : begin
                        decode_instr.op = (f3[1:0] == 2'b10) ? (_FSGNJXS) :
                                          (f3[1:0] == 2'b01) ? (_FSGNJNS) : (_FSGNJS);
                        decode_instr.rs1     = rs1;
                        decode_instr.rs2     = rs2;
                        decode_instr.rd      = rd;
                        decode_instr.use_fpr = 4'b0111;
                    end

                    {5'b00101} : begin
                        decode_instr.op      = (f3[0]) ? (_FMAXS) : (_FMINS);
                        decode_instr.rs1     = rs1;
                        decode_instr.rs2     = rs2;
                        decode_instr.rd      = rd;
                        decode_instr.use_fpr = 4'b0111;
                    end

                    {5'b11000} : begin
                        decode_instr.op      = (f1) ? (_FCVTWUS) : (_FCVTWS);
                        decode_instr.rs1     = rs1;
                        decode_instr.rd      = rd;
                        decode_instr.use_fpr = 4'b0100;
                    end

                    {5'b11100} : begin
                        decode_instr.op      = (f3[0]) ? (_FCLASSS) : (_FMVXW);
                        decode_instr.rs1     = rs1;
                        decode_instr.rd      = rd;
                        decode_instr.use_fpr = 4'b0100;
                    end

                    {5'b11110} : begin
                        decode_instr.op      = _FMVWX;
                        decode_instr.rs1     = rs1;
                        decode_instr.rd      = rd;
                        decode_instr.use_fpr = 4'b0001;
                    end

                    {5'b10100} : begin
                        decode_instr.op = (f3[1:0] == 2'b10) ? (_FEQS) :
                                          (f3[1:0] == 2'b01) ? (_FLTS) : (_FLES);
                        decode_instr.rs1     = rs1;
                        decode_instr.rs2     = rs2;
                        decode_instr.rd      = rd;
                        decode_instr.use_fpr = 4'b0110;
                    end

                    {5'b11010} : begin
                        decode_instr.op      = (f1) ? (_FCVTSWU) : (_FCVTSW);
                        decode_instr.rs1     = rs1;
                        decode_instr.rd      = rd;
                        decode_instr.use_fpr = 4'b0100;
                    end

                    default : decode_instr.op = _ADD;
                endcase
            end

            CSRS_OP : begin
                // vector CSRs instruction
                if (inst[31:20] inside {CSR_VSTART, CSR_VXSAT, CSR_VXRM,
                                        CSR_VCSR, CSR_VL, CSR_VTYPE, CSR_VLENB}) begin
                    decode_instr.fu       = VPU;
                    decode_instr.rs1      = rs1;
                    decode_instr.rd       = rd;
                    decode_instr.use_imme = (f3 inside {CSRRWI_FUNC3, CSRRSI_FUNC3, CSRRCI_FUNC3});
                end else begin
                    decode_instr.fu       = CSR;
                    decode_instr.rs1      = rs1;
                    decode_instr.rd       = rd;
                    decode_instr.use_imme = (f3 inside {CSRRWI_FUNC3, CSRRSI_FUNC3, CSRRCI_FUNC3});

                    unique case (f3)
                        CSRRW_FUNC3  : decode_instr.op = _CSRRW;
                        CSRRS_FUNC3  : decode_instr.op = _CSRRS;
                        CSRRC_FUNC3  : decode_instr.op = _CSRRC;
                        CSRRWI_FUNC3 : decode_instr.op = _CSRRW;
                        CSRRSI_FUNC3 : decode_instr.op = _CSRRS;
                        CSRRCI_FUNC3 : decode_instr.op = _CSRRC;

                        PRIV_FUNC3 : begin
                            unique case (inst[31:20])
                                MRET_FUNC12 : decode_instr.op = _MRET;
                                WFI_FUNC12  : decode_instr.op = _WFI;
                                default     : decode_instr.op = _ADD;
                            endcase
                        end

                        default : decode_instr.op = _ADD;
                    endcase
                end
            end

            VECTOR_OP : begin
                decode_instr.fu = VPU;

                // select operands
                unique case (f3)
                    OPMVV : begin
                        // vmv.x.s(permutation), vpopc(mask), vfirst(mask)
                        if (inst[`FUNC6] == 6'b010000) begin
                            decode_instr.rd = rd;
                        end
                    end

                    OPIVX, OPMVX : begin
                        decode_instr.rs1 = rs1;
                    end

                    OPCFG : begin
                        decode_instr.rs1 = (inst[31:30] != 2'b11) ? (rs1) : (x0);
                        decode_instr.rs2 = (inst[31:30] == 2'b10) ? (rs2) : (x0);
                        decode_instr.rd  = rd;
                    end

                    default : ;
                endcase
            end

            default : ; // nothing to do
        endcase
    end

    // immediate generate
    assign itype_imm = { {20{inst[31]}}, inst[31:20] };
    assign stype_imm = { {20{inst[31]}}, inst[31:25], inst[11:7] };
    assign btype_imm = { {20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0 };
    assign utype_imm = { inst[31:12], 12'd0 };
    assign jtype_imm = { {12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0 };

    always_comb begin
        unique case (opcode)
            RTYPE_OP   : decode_instr.result = 32'd0;
            ITYPE_OP   : decode_instr.result = itype_imm;
            LOAD_OP    : decode_instr.result = itype_imm;
            JALR_OP    : decode_instr.result = itype_imm;
            STYPE_OP   : decode_instr.result = stype_imm;
            BTYPE_OP   : decode_instr.result = btype_imm;
            AUIPC_OP   : decode_instr.result = utype_imm;
            LUI_OP     : decode_instr.result = utype_imm;
            JAL_OP     : decode_instr.result = jtype_imm;
            FLW_OP     : decode_instr.result = itype_imm;
            FSW_OP     : decode_instr.result = stype_imm;
            FMADD_OP   : decode_instr.result = 32'd0;
            FMSUB_OP   : decode_instr.result = 32'd0;
            FNMADD_OP  : decode_instr.result = 32'd0;
            FNMSUB_OP  : decode_instr.result = 32'd0;
            F_RTYPE_OP : decode_instr.result = 32'd0;
            CSRS_OP    : decode_instr.result = itype_imm;
            default    : decode_instr.result = 32'd0;
        endcase

        if (decode_instr.fu == VPU) begin
            decode_instr.result = inst;
        end
    end

endmodule