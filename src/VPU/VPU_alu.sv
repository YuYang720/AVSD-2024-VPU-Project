module VPU_alu (
    // alu contorl
    input  logic        valid_i,
    input  VALU_OP_t    valu_ctrl_i,
    input  VSEW_e       vsew_i,
    input  VXRM_e       vxrm_i,

    // alu operand
    input  logic [63:0] operand1_i,
    input  logic [63:0] operand2_i,
    input  logic        mask_i,

    // alu result
    output logic        result_valid_o,
    output logic        result_en_o,
    output logic [63:0] result_o
);

    // --------------------------------------------
    //              Signal Declaration             
    // --------------------------------------------
    typedef union packed {
        logic [7:0][ 7:0] w8;
        logic [3:0][15:0] w16;
        logic [1:0][31:0] w32;
        logic      [63:0] w64;
    } alu_operand_t;

    logic [ 8:0]  sum9 , sub9;
    logic [16:0]  sum17, sub17;
    logic [32:0]  sum33, sub33;
    logic [64:0]  sum65, sub65;
    logic         equal, less;

    logic [ 7:0]  r_add_8 , r_sub_8;
    logic [15:0]  r_add_16, r_sub_16;
    logic [31:0]  r_add_32, r_sub_32;
    logic [63:0]  r_add_64, r_sub_64;
    logic         vsat_add_8, vsat_add_16, vsat_add_32, vsat_add_64;
    logic         vsat_sub_8, vsat_sub_16, vsat_sub_32, vsat_sub_64;

    alu_operand_t operand1, operand2, result;

    // --------------------------------------------
    //                Operand assign               
    // --------------------------------------------
    assign operand1 = (valu_ctrl_i.op == VRSUB) ? (operand2_i) : (operand1_i);
    assign operand2 = (valu_ctrl_i.op == VRSUB) ? (operand1_i) : (operand2_i);

    // alu can always finish in one cycle
    // if mask is write enable, then the result will be invalid when mask = 0
    assign result_valid_o = valid_i;
    assign result_en_o    = ~(valu_ctrl_i.op_mask == VALU_MASK_WRITE && mask_i == 1'b0);
    assign result_o       = result;

    // --------------------------------------------
    //                   Calculate                 
    // --------------------------------------------
    always_comb begin
        sum9  = operand2.w8 [0] + operand1.w8 [0] + (valu_ctrl_i.op_mask == VALU_MASK_CARRY && mask_i);
        sum17 = operand2.w16[0] + operand1.w16[0] + (valu_ctrl_i.op_mask == VALU_MASK_CARRY && mask_i);
        sum33 = operand2.w32[0] + operand1.w32[0] + (valu_ctrl_i.op_mask == VALU_MASK_CARRY && mask_i);
        sum65 = operand2.w64    + operand1.w64    + (valu_ctrl_i.op_mask == VALU_MASK_CARRY && mask_i);

        sub9  = operand2.w8 [0] - operand1.w8 [0] - (valu_ctrl_i.op_mask == VALU_MASK_CARRY && mask_i);
        sub17 = operand2.w16[0] - operand1.w16[0] - (valu_ctrl_i.op_mask == VALU_MASK_CARRY && mask_i);
        sub33 = operand2.w32[0] - operand1.w32[0] - (valu_ctrl_i.op_mask == VALU_MASK_CARRY && mask_i);
        sub65 = operand2.w64    - operand1.w64    - (valu_ctrl_i.op_mask == VALU_MASK_CARRY && mask_i);

        unique case (vsew_i)
            VSEW_8  : equal = (operand2.w8 [0] == operand1.w8 [0]);
            VSEW_16 : equal = (operand2.w16[0] == operand1.w16[0]);
            VSEW_32 : equal = (operand2.w32[0] == operand1.w32[0]);
            VSEW_64 : equal = (operand2.w64    == operand1.w64   );
            default : equal = 1'b0;
        endcase

        unique case (vsew_i)
            VSEW_8  : less = $signed({valu_ctrl_i.signext & operand2.w8 [0][ 7], operand2.w8 [0]}) <
                             $signed({valu_ctrl_i.signext & operand1.w8 [0][ 7], operand1.w8 [0]});
            VSEW_16 : less = $signed({valu_ctrl_i.signext & operand2.w16[0][15], operand2.w16[0]}) <
                             $signed({valu_ctrl_i.signext & operand1.w16[0][15], operand1.w16[0]});
            VSEW_32 : less = $signed({valu_ctrl_i.signext & operand2.w32[0][31], operand2.w32[0]}) <
                             $signed({valu_ctrl_i.signext & operand1.w32[0][31], operand1.w32[0]});
            VSEW_64 : less = $signed({valu_ctrl_i.signext & operand2.w64   [63], operand2.w64   }) <
                             $signed({valu_ctrl_i.signext & operand1.w64   [63], operand1.w64   });
            default : less = 1'b0;
        endcase

        vsat_add_8  = (valu_ctrl_i.signext) ? ((sum9 [ 7] ^ operand2.w8 [0][ 7]) & ~(operand1.w8 [0][ 7] ^ operand2.w8 [0][ 7])) : (sum9 [ 8]);
        vsat_add_16 = (valu_ctrl_i.signext) ? ((sum17[15] ^ operand2.w16[0][15]) & ~(operand1.w16[0][15] ^ operand2.w16[0][15])) : (sum17[16]);
        vsat_add_32 = (valu_ctrl_i.signext) ? ((sum33[31] ^ operand2.w32[0][31]) & ~(operand1.w32[0][31] ^ operand2.w32[0][31])) : (sum33[32]);
        vsat_add_64 = (valu_ctrl_i.signext) ? ((sum65[63] ^ operand2.w64   [63]) & ~(operand1.w64   [63] ^ operand2.w64   [63])) : (sum65[64]);
        vsat_sub_8  = (valu_ctrl_i.signext) ? (^sum9 [ 8: 7]) : (sub9 [ 8]);
        vsat_sub_16 = (valu_ctrl_i.signext) ? (^sum17[16:15]) : (sub17[16]);
        vsat_sub_32 = (valu_ctrl_i.signext) ? (^sum33[32:31]) : (sub33[32]);
        vsat_sub_64 = (valu_ctrl_i.signext) ? (^sum65[64:63]) : (sub65[64]);

        r_add_8  = 8'b0;
        r_add_16 = 16'b0;
        r_add_32 = 32'b0;
        r_add_64 = 64'b0;
        r_sub_8  = 8'b0;
        r_sub_16 = 16'b0;
        r_sub_32 = 32'b0;
        r_sub_64 = 64'b0;

        unique case (vxrm_i)
            VXRM_RNU : begin
                r_add_8  = { 7'd0, sum9 [0]};
                r_add_16 = {15'd0, sum17[0]};
                r_add_32 = {31'd0, sum33[0]};
                r_add_64 = {63'd0, sum65[0]};
                r_sub_8  = { 7'd0, sub9 [0]};
                r_sub_16 = {15'd0, sub17[0]};
                r_sub_32 = {31'd0, sub33[0]};
                r_sub_64 = {63'd0, sub65[0]};
            end

            VXRM_RNE : begin
                r_add_8  = { 7'd0, &sum9 [1:0]};
                r_add_16 = {15'd0, &sum17[1:0]};
                r_add_32 = {31'd0, &sum33[1:0]};
                r_add_64 = {63'd0, &sum65[1:0]};
                r_sub_8  = { 7'd0, &sub9 [1:0]};
                r_sub_16 = {15'd0, &sub17[1:0]};
                r_sub_32 = {31'd0, &sub33[1:0]};
                r_sub_64 = {63'd0, &sub65[1:0]};
            end

            VXRM_RDN : begin
                r_add_8  = { 7'd0, 1'b0};
                r_add_16 = {15'd0, 1'b0};
                r_add_32 = {31'd0, 1'b0};
                r_add_64 = {63'd0, 1'b0};
                r_sub_8  = { 7'd0, 1'b0};
                r_sub_16 = {15'd0, 1'b0};
                r_sub_32 = {31'd0, 1'b0};
                r_sub_64 = {63'd0, 1'b0};
            end

            VXRM_ROD : begin
                r_add_8  = { 7'd0, !sum9 [1] & (sum9 [0] != 1'b0)};
                r_add_16 = {15'd0, !sum17[1] & (sum17[0] != 1'b0)};
                r_add_32 = {31'd0, !sum33[1] & (sum33[0] != 1'b0)};
                r_add_64 = {63'd0, !sum65[1] & (sum65[0] != 1'b0)};
                r_sub_8  = { 7'd0, !sub9 [1] & (sub9 [0] != 1'b0)};
                r_sub_16 = {15'd0, !sub17[1] & (sub17[0] != 1'b0)};
                r_sub_32 = {31'd0, !sub33[1] & (sub33[0] != 1'b0)};
                r_sub_64 = {63'd0, !sub65[1] & (sub65[0] != 1'b0)};
            end

            default : ;
        endcase
    end

    always_comb begin
        result = 64'd0;

        unique case (valu_ctrl_i.op)
            VADD : begin
                unique case (vsew_i)
                    VSEW_8  : result.w8 [0] = (valu_ctrl_i.mask_res) ? ({7'd0 , sum9 [ 8]}) : (sum9 [ 7:0]);
                    VSEW_16 : result.w16[0] = (valu_ctrl_i.mask_res) ? ({15'd0, sum17[16]}) : (sum17[15:0]);
                    VSEW_32 : result.w32[0] = (valu_ctrl_i.mask_res) ? ({31'd0, sum33[32]}) : (sum33[31:0]);
                    VSEW_64 : result.w64    = (valu_ctrl_i.mask_res) ? ({63'd0, sum65[64]}) : (sum65[63:0]);
                    default : ;
                endcase
            end

            VSADD : begin
                unique case (vsew_i)
                    VSEW_8  : result.w8 [0] = (vsat_add_8 ) ? ((sum9 [ 7]) ? ({1'b0, { 7{1'b1}}}) : ({1'b1,  7'd0})) : (sum9 [ 7:0]);
                    VSEW_16 : result.w16[0] = (vsat_add_16) ? ((sum17[15]) ? ({1'b0, {15{1'b1}}}) : ({1'b1, 15'd0})) : (sum17[15:0]);
                    VSEW_32 : result.w32[0] = (vsat_add_32) ? ((sum33[31]) ? ({1'b0, {31{1'b1}}}) : ({1'b1, 31'd0})) : (sum33[31:0]);
                    VSEW_64 : result.w64    = (vsat_add_64) ? ((sum65[63]) ? ({1'b0, {63{1'b1}}}) : ({1'b1, 63'd0})) : (sum65[63:0]);
                    default : ;
                endcase
            end

            VSADDU : begin
                unique case (vsew_i)
                    VSEW_8  : result.w8 [0] = (vsat_add_8 ) ? ({ 8{1'b1}}) : (sum9 [ 7:0]);
                    VSEW_16 : result.w16[0] = (vsat_add_16) ? ({16{1'b1}}) : (sum17[15:0]);
                    VSEW_32 : result.w32[0] = (vsat_add_32) ? ({32{1'b1}}) : (sum33[31:0]);
                    VSEW_64 : result.w64    = (vsat_add_64) ? ({64{1'b1}}) : (sum65[63:0]);
                    default : ;
                endcase
            end

            VAADD : begin
                unique case (vsew_i)
                    VSEW_8  : result.w8 [0] = (valu_ctrl_i.signext) ? ({sum9 [ 7], sum9 [ 7:1]} + r_add_8 ) : (sum9 [ 8:1] + r_add_8 );
                    VSEW_16 : result.w16[0] = (valu_ctrl_i.signext) ? ({sum17[15], sum17[15:1]} + r_add_16) : (sum17[16:1] + r_add_16);
                    VSEW_32 : result.w32[0] = (valu_ctrl_i.signext) ? ({sum33[31], sum33[31:1]} + r_add_32) : (sum33[32:1] + r_add_32);
                    VSEW_64 : result.w64    = (valu_ctrl_i.signext) ? ({sum65[63], sum65[63:1]} + r_add_64) : (sum65[64:1] + r_add_64);
                    default : ;
                endcase
            end

            VSUB, VRSUB : begin
                unique case (vsew_i)
                    VSEW_8  : result.w8 [0] = (valu_ctrl_i.mask_res) ? ({7'd0 , sum9 [ 8]}) : (sub9 [ 7:0]);
                    VSEW_16 : result.w16[0] = (valu_ctrl_i.mask_res) ? ({15'd0, sum17[16]}) : (sub17[15:0]);
                    VSEW_32 : result.w32[0] = (valu_ctrl_i.mask_res) ? ({31'd0, sum33[32]}) : (sub33[31:0]);
                    VSEW_64 : result.w64    = (valu_ctrl_i.mask_res) ? ({63'd0, sum65[64]}) : (sub65[63:0]);
                    default : ;
                endcase
            end

            V_SSUB, V_SSUBU : begin
                unique case (vsew_i)
                    VSEW_8  : result.w8 [0] = (vsat_sub_8 ) ? ({ 8{1'b0}}) : (sum9 [ 7:0]);
                    VSEW_16 : result.w16[0] = (vsat_sub_16) ? ({16{1'b0}}) : (sum17[15:0]);
                    VSEW_32 : result.w32[0] = (vsat_sub_32) ? ({32{1'b0}}) : (sum33[31:0]);
                    VSEW_64 : result.w64    = (vsat_sub_64) ? ({64{1'b0}}) : (sum65[63:0]);
                    default : ;
                endcase
            end

            VASUB : begin
                unique case (vsew_i)
                    VSEW_8  : result.w8 [0] = (valu_ctrl_i.signext) ? (($signed(sub9 [ 7:0]) >>> 1) + r_sub_8 ) : ((sub9 [ 7:0] >> 1) + r_add_8 );
                    VSEW_16 : result.w16[0] = (valu_ctrl_i.signext) ? (($signed(sub17[15:0]) >>> 1) + r_sub_16) : ((sub17[15:0] >> 1) + r_add_16);
                    VSEW_32 : result.w32[0] = (valu_ctrl_i.signext) ? (($signed(sub33[31:0]) >>> 1) + r_sub_32) : ((sub33[31:0] >> 1) + r_add_32);
                    VSEW_64 : result.w64    = (valu_ctrl_i.signext) ? (($signed(sub65[63:0]) >>> 1) + r_sub_64) : ((sub65[63:0] >> 1) + r_add_64);
                    default : ;
                endcase
            end

            VAND : result = operand2 & operand1;
            VOR  : result = operand2 | operand1;
            VXOR : result = operand2 ^ operand1;

            VSLL : begin
                unique case (vsew_i)
                    VSEW_8  : result.w8 [0] = operand2.w8 [0] << operand1.w8 [0][2:0];
                    VSEW_16 : result.w16[0] = operand2.w16[0] << operand1.w16[0][3:0];
                    VSEW_32 : result.w32[0] = operand2.w32[0] << operand1.w32[0][4:0];
                    VSEW_64 : result.w64    = operand2.w64    << operand1.w64   [5:0];
                    default : ;
                endcase
            end

            VSRL : begin
                unique case (vsew_i)
                    VSEW_8  : result.w8 [0] = operand2.w8 [0] >> operand1.w8 [0][2:0];
                    VSEW_16 : result.w16[0] = operand2.w16[0] >> operand1.w16[0][3:0];
                    VSEW_32 : result.w32[0] = operand2.w32[0] >> operand1.w32[0][4:0];
                    VSEW_64 : result.w64    = operand2.w64    >> operand1.w64   [5:0];
                    default : ;
                endcase
            end

            VSRA : begin
                unique case (vsew_i)
                    VSEW_8  : result.w8 [0] = $signed(operand2.w8 [0]) >>> operand1.w8 [0][2:0];
                    VSEW_16 : result.w16[0] = $signed(operand2.w16[0]) >>> operand1.w16[0][3:0];
                    VSEW_32 : result.w32[0] = $signed(operand2.w32[0]) >>> operand1.w32[0][4:0];
                    VSEW_64 : result.w64    = $signed(operand2.w64   ) >>> operand1.w64   [5:0];
                    default : ;
                endcase
            end

            VMSEQ  : result[0] =  equal;
            VMSNE  : result[0] = ~equal;
            VMSLT  : result[0] =  less ;
            VMSLE  : result[0] =  (less || equal);
            VMSGT  : result[0] = ~(less || equal);

            VMIN, VMAX : begin
                unique case (vsew_i)
                    VSEW_8  : result.w8 [0] = (less ^ (valu_ctrl_i.op == VMAX)) ? (operand2.w8 [0]) : (operand1.w8 [0]);
                    VSEW_16 : result.w16[0] = (less ^ (valu_ctrl_i.op == VMAX)) ? (operand2.w16[0]) : (operand1.w16[0]);
                    VSEW_32 : result.w32[0] = (less ^ (valu_ctrl_i.op == VMAX)) ? (operand2.w32[0]) : (operand1.w32[0]);
                    VSEW_64 : result.w64    = (less ^ (valu_ctrl_i.op == VMAX)) ? (operand2.w64   ) : (operand1.w64   );
                    default : ;
                endcase
            end

            VMERGE : begin
                unique case (vsew_i)
                    VSEW_8  : result.w8 [0] = (mask_i) ? (operand1.w8 [0]) : (operand2.w8 [0]);
                    VSEW_16 : result.w16[0] = (mask_i) ? (operand1.w16[0]) : (operand2.w16[0]);
                    VSEW_32 : result.w32[0] = (mask_i) ? (operand1.w32[0]) : (operand2.w32[0]);
                    VSEW_64 : result.w64    = (mask_i) ? (operand1.w64   ) : (operand2.w64   );
                    default : ;
                endcase
            end

            VMV  : result = operand1;
            VMVR : result = operand2;

            default : ;

        endcase
    end

endmodule