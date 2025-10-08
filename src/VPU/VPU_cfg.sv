module VPU_cfg (
    input  logic               clk_i,
    input  logic               rst_i,

    // from VPU ISSUE
    input  logic               VCFG_valid_i,
    input  VPU_uOP_t           VCFG_entry_i,

    // csr value
    output logic [VL_BITS-2:0] vstart_o,
    output logic               vxsat_o,
    output VXRM_e              vxrm_o,
    output VTYPE_CSR_t         vtype_o,
    output logic [VL_BITS-1:0] vl_o,

    // to COMMIT
    output logic               VCFG_read_valid_o,
    output logic [31:0]        VCFG_read_data_o
);

    // --------------------------------------------
    //              Signal Declaration             
    // --------------------------------------------
    // Vector CSRs (RISC-V Vector Extension define 7 Vector CSRs)
    logic [VL_BITS-2:0] vstart_q, vstart_n;   // 1. vector start index
    logic               vxsat_q, vxsat_n;     // 2. fixed-point saturation flag
    VXRM_e              vxrm_q, vxrm_n;       // 3. fixed-point rounding mode
    logic [31:0]        vcsr;                 // 4. vector control and status register (actually 2 and 3)
    logic [VL_BITS-1:0] vl_q, vl_n;           // 5. vector length (vl) register
    VTYPE_CSR_t         vtype_q, vtype_n;     // 6. vector data type register
    logic [31:0]        vlenb;                // 7. VLEN / 8 (vector register length in bytes)

    // if the current CSRs in valid
    logic               vill;                 // should inside vtype, but spec said can use vsew to indicate

    // CSRs read data -> to CPU
    logic [31:0]        read_data;

    // application vector length for vset[i]vl[i]
    logic [31:0]        avl;
    logic [VL_BITS-1:0] vlmax;

    // --------------------------------------------
    //              Output Assignment              
    // --------------------------------------------
    assign VCFG_read_valid_o = VCFG_valid_i;
    assign VCFG_read_data_o  = read_data;
    assign vstart_o          = vstart_q;
    assign vxsat_o           = vxsat_q;
    assign vxrm_o            = vxrm_q;
    assign vtype_o           = vtype_q;
    assign vl_o              = vl_q;

    // --------------------------------------------
    //                 CSRs update                 
    // --------------------------------------------
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            vstart_q   <= (VL_BITS-1)'(0);
            vxsat_q    <= 1'b0;
            vxrm_q     <= VXRM_e'(0);
            vtype_q    <= VTYPE_CSR_t'(0);
            vl_q       <= VL_BITS'(0);
        end else begin
            vstart_q   <= vstart_n;
            vxsat_q    <= vxsat_n;
            vxrm_q     <= vxrm_n;
            vtype_q    <= vtype_n;
            vl_q       <= vl_n;
        end
    end

    // --------------------------------------------
    //     vset[i]vl[i] and zicsr update logic     
    // --------------------------------------------
    always_comb begin
        vstart_n   = vstart_q;
        vxsat_n    = vxsat_q;
        vxrm_n     = vxrm_q;
        vcsr       = {29'd0, vxrm_q, vxsat_q};
        vtype_n    = vtype_q;
        vl_n       = vl_q;
        vill       = (vtype_q.vsew == VSEW_INVALID);
        avl        = VCFG_entry_i.rs1.xval;
        vlmax      = VL_BITS'(0);

        // zicsr read / write
        read_data  = 32'd0;

        if (VCFG_valid_i) begin
            unique case (VCFG_entry_i.mode.cfg.csr_op)
                CFG_VTYPE_READ   : read_data = (vill) ? (32'h80000000) : ({24'd0, vtype_q});
                CFG_VL_READ      : read_data = (vill) ? (32'd0) : ({(32-VL_BITS)'(0), vl_q});
                CFG_VLENB_READ   : read_data = VLEN / 8;
                CFG_VSTART_WRITE : read_data = {(33-VL_BITS)'(0), vstart_q};
                CFG_VSTART_SET   : read_data = {(33-VL_BITS)'(0), vstart_q};
                CFG_VSTART_CLEAR : read_data = {(33-VL_BITS)'(0), vstart_q};
                CFG_VXSAT_WRITE  : read_data = {31'd0, vxsat_q};
                CFG_VXSAT_SET    : read_data = {31'd0, vxsat_q};
                CFG_VXSAT_CLEAR  : read_data = {31'd0, vxsat_q};
                CFG_VXRM_WRITE   : read_data = {30'd0, vxrm_q };
                CFG_VXRM_SET     : read_data = {30'd0, vxrm_q };
                CFG_VXRM_CLEAR   : read_data = {30'd0, vxrm_q };
                CFG_VCSR_WRITE   : read_data = vcsr;
                CFG_VCSR_SET     : read_data = vcsr;
                CFG_VCSR_CLEAR   : read_data = vcsr;
                default :        ; // nothing to do
            endcase

            unique case (VCFG_entry_i.mode.cfg.csr_op)
                CFG_VSTART_WRITE : vstart_n          =  VCFG_entry_i.rs1.xval[VL_BITS-2:0];
                CFG_VSTART_SET   : vstart_n          =  VCFG_entry_i.rs1.xval[VL_BITS-2:0] | vstart_q;
                CFG_VSTART_CLEAR : vstart_n          = ~VCFG_entry_i.rs1.xval[VL_BITS-2:0] & vstart_q;
                CFG_VXSAT_WRITE  : vxsat_n           =  VCFG_entry_i.rs1.xval[0];
                CFG_VXSAT_SET    : vxsat_n           =  VCFG_entry_i.rs1.xval[0] | vxsat_q;
                CFG_VXSAT_CLEAR  : vxsat_n           = ~VCFG_entry_i.rs1.xval[0] & vxsat_q;
                CFG_VXRM_WRITE   : vxrm_n            = VXRM_e'( VCFG_entry_i.rs1.xval[1:0]);
                CFG_VXRM_SET     : vxrm_n            = VXRM_e'( VCFG_entry_i.rs1.xval[1:0] | vxrm_q);
                CFG_VXRM_CLEAR   : vxrm_n            = VXRM_e'(~VCFG_entry_i.rs1.xval[1:0] & vxrm_q);
                CFG_VCSR_WRITE   : {vxrm_n, vxsat_n} =  VCFG_entry_i.rs1.xval[2:0];
                CFG_VCSR_SET     : {vxrm_n, vxsat_n} =  VCFG_entry_i.rs1.xval[2:0] | {vxrm_q, vxsat_q};
                CFG_VCSR_CLEAR   : {vxrm_n, vxsat_n} = ~VCFG_entry_i.rs1.xval[2:0] & {vxrm_q, vxsat_q};
                default :        ; // nothing to do
            endcase
        end

        // vset[i]vl[i] instructions update
        if (VCFG_valid_i && VCFG_entry_i.mode.cfg.csr_op == CFG_VSETVL) begin
            vtype_n  = VCFG_entry_i.mode.cfg.vtype;

            // ---------------------------------------------------------------------------------
            // Note that the spec states:
            // > When rs1=x0 and rd=x0, the instruction operates as if the current vector length
            // > in vl is used as the AVL, and the resulting value is written to vl, but not to
            // > a destination register. This form can only be used when VLMAX and hence vl is
            // > not actually changed by the new SEW/LMUL ratio. Use of the instruction with a
            // > new SEW/LMUL ratio that would result in a change of VLMAX is reserved.
            // > Implementations may set vill in this case.
            // ---------------------------------------------------------------------------------
            // Change VSEW and LMUL while keeping the current VL.
            // if current VSEW/LMUL ratio change, we set VSEW to VSEW_INVALID.
            if (VCFG_entry_i.mode.cfg.keep_vl) begin
                unique case ({vtype_q.vsew, VCFG_entry_i.mode.cfg.vtype.vsew})
                    // VSEW scaled by 8
                    {VSEW_8, VSEW_64} : begin
                        // VMUL should also scaled by 8
                        // otherwise set VSEW to invalid
                        unique case ({vtype_q.vlmul, VCFG_entry_i.mode.cfg.vtype.vlmul})
                            {LMUL_F8, LMUL_1},
                            {LMUL_F4, LMUL_2},
                            {LMUL_F2, LMUL_4},
                            {LMUL_1 , LMUL_8}: ;
                            default : vtype_n.vsew = VSEW_INVALID;
                        endcase
                    end

                    // VSEW scaled by 4
                    {VSEW_8, VSEW_32}, {VSEW_16, VSEW_64} : begin
                        // VMUL should also scaled by 4
                        // otherwise set VSEW to invalid
                        unique case ({vtype_q.vlmul, VCFG_entry_i.mode.cfg.vtype.vlmul})
                            {LMUL_F8, LMUL_F2},
                            {LMUL_F4, LMUL_1 },
                            {LMUL_F2, LMUL_2 },
                            {LMUL_1 , LMUL_4 },
                            {LMUL_2 , LMUL_8 }: ;
                            default : vtype_n.vsew = VSEW_INVALID;
                        endcase
                    end

                    // VSEW scaled by 2
                    {VSEW_8, VSEW_16}, {VSEW_16, VSEW_32}, {VSEW_32, VSEW_64} : begin
                        // VMUL should also scaled by 2
                        // otherwise set VSEW to invalid
                        unique case ({vtype_q.vlmul, VCFG_entry_i.mode.cfg.vtype.vlmul})
                            {LMUL_F8, LMUL_F4},
                            {LMUL_F4, LMUL_F2},
                            {LMUL_F2, LMUL_1 },
                            {LMUL_1 , LMUL_2 },
                            {LMUL_2 , LMUL_4 },
                            {LMUL_4 , LMUL_8 }: ;
                            default : vtype_n.vsew = VSEW_INVALID;
                        endcase
                    end

                    // VSEW scaled by 1
                    {VSEW_8, VSEW_8  }, {VSEW_16, VSEW_16},
                    {VSEW_32, VSEW_32}, {VSEW_64, VSEW_64} : begin
                        // VMUL should also scaled by 1
                        // otherwise set VSEW to invalid
                        if (vtype_q.vlmul != VCFG_entry_i.mode.cfg.vtype.vlmul) begin
                            vtype_n.vsew = VSEW_INVALID;
                        end
                    end

                    // VSEW scaled by 1/2
                    {VSEW_16, VSEW_8}, {VSEW_32, VSEW_16}, {VSEW_64, VSEW_32} : begin
                        // VMUL should also scaled by 1/2
                        // otherwise set VSEW to invalid
                        unique case ({vtype_q.vlmul, VCFG_entry_i.mode.cfg.vtype.vlmul})
                            {LMUL_F4, LMUL_F8},
                            {LMUL_F2, LMUL_F4},
                            {LMUL_1 , LMUL_F2},
                            {LMUL_2 , LMUL_1 },
                            {LMUL_4 , LMUL_2 },
                            {LMUL_8 , LMUL_4 }: ;
                            default: vtype_n.vsew = VSEW_INVALID;
                        endcase
                    end

                    // VSEW scaled by 1/4
                    {VSEW_32, VSEW_8}, {VSEW_64, VSEW_16} : begin
                        // VMUL should also scaled by 1/4
                        // otherwise set VSEW to invalid
                        unique case ({vtype_q.vlmul, VCFG_entry_i.mode.cfg.vtype.vlmul})
                            {LMUL_F2, LMUL_F8},
                            {LMUL_1 , LMUL_F4},
                            {LMUL_2 , LMUL_F2},
                            {LMUL_4 , LMUL_1 },
                            {LMUL_8 , LMUL_2 }: ;
                            default: vtype_n.vsew = VSEW_INVALID;
                        endcase
                    end

                    // VSEW scaled by 1/8
                    {VSEW_64, VSEW_8} : begin
                        // VMUL should also scaled by 1/8
                        // otherwise set VSEW to invalid
                        unique case ({vtype_q.vlmul, VCFG_entry_i.mode.cfg.vtype.vlmul})
                            {LMUL_8, LMUL_1 },
                            {LMUL_4, LMUL_F2},
                            {LMUL_2, LMUL_F4},
                            {LMUL_1, LMUL_F8}: ;
                            default: vtype_n.vsew = VSEW_INVALID;
                        endcase
                    end

                    default : ;
                endcase

            // We supports all integer LMUL settings combined with any legal SEW setting.
            // ---------------------------------------------------------------------------------
            // Note that the spec states:
            // > Implementations must provide fractional LMUL settings [...] to support
            // > LMUL ≥ SEWMIN/ELEN, where SEWMIN is the narrowest supported SEW value and ELEN
            // > is the widest supported SEW value.
            // ---------------------------------------------------------------------------------
            // The minimum SEW is 8 and ELEN is 64, hence we supports LMULs of 1/2, 1/4, 1/8.
            // However, the fractional LMUL cannot be combined with any SEW.
            // ---------------------------------------------------------------------------------
            // Note that the spec states:
            // > For a given supported fractional LMUL setting, implementations must support
            // > SEW settings between SEWMIN and LMUL * ELEN, inclusive.
            // ---------------------------------------------------------------------------------
            // LMUL 1/8 is only compatible with a SEW of 8.
            // LMUL 1/4 is only compatible with a SEW of 8, 16.
            // LMUL 1/2 is only compatible with a SEW of 8, 16, 32.
            // Attempts to use an illegal combination sets the `vill` bit in `vtype`
            // by overwriting the VSEW setting with VSEW_INVALID.
            end else begin
                unique case ({VCFG_entry_i.mode.cfg.vtype.vlmul, VCFG_entry_i.mode.cfg.vtype.vsew})
                    // SEW/LMUL ratio = 64
                    {LMUL_F8, VSEW_8 }, {LMUL_F4, VSEW_16}, {LMUL_F2, VSEW_32}, {LMUL_1 , VSEW_64} : begin
                        vlmax = VL_BITS'(VLEN / 64);
                    end

                    // SEW/LMUL ratio = 32
                    {LMUL_F4, VSEW_8 }, {LMUL_F2, VSEW_16}, {LMUL_1 , VSEW_32}, {LMUL_2 , VSEW_64} : begin
                        vlmax = VL_BITS'(VLEN / 32);
                    end

                    // SEW/LMUL ratio = 16
                    {LMUL_F2, VSEW_8 }, {LMUL_1 , VSEW_16}, {LMUL_2 , VSEW_32}, {LMUL_4 , VSEW_64} : begin
                        vlmax = VL_BITS'(VLEN / 16);
                    end

                    // SEW/LMUL ratio = 8
                    {LMUL_1 , VSEW_8 }, {LMUL_2 , VSEW_16}, {LMUL_4 , VSEW_32}, {LMUL_8, VSEW_64 } : begin
                        vlmax = VL_BITS'(VLEN / 8);
                    end

                    // SEW/LMUL ratio = 4
                    {LMUL_2 , VSEW_8 }, {LMUL_4 , VSEW_16}, {LMUL_8 , VSEW_32} : begin
                        vlmax = VL_BITS'(VLEN / 4);
                    end

                    // SEW/LMUL ratio = 2
                    {LMUL_4 , VSEW_8 }, {LMUL_8 , VSEW_16} : begin
                        vlmax = VL_BITS'(VLEN / 2);
                    end

                    // SEW/LMUL ratio = 1
                    {LMUL_8 , VSEW_8 } : begin
                        vlmax = VL_BITS'(VLEN / 1);
                    end

                    default: vtype_n.vsew = VSEW_INVALID;
                endcase

                vl_n = (VCFG_entry_i.mode.cfg.vlmax || avl > ({(32-VL_BITS)'(0), vlmax})) ? (vlmax) : (avl[VL_BITS-1:0]);
            end

            // if the set CSRs is illegal --> reset vl to zero
            if (vtype_n.vsew == VSEW_INVALID) begin
                vl_n = VL_BITS'(0);
            end

            // set up CSRs read value for vset[i]vl[i] instructions
            read_data = {(32-VL_BITS)'(0), vl_n};
        end
    end

endmodule