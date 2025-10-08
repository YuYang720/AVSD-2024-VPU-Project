module fp_regfiles(
    input  logic        clk_i,
    input  logic        rst_i,

    // writeback port
    input  logic        wb_en_i,
    input  REG_t        rd_index_i,
    input  logic [31:0] rd_data_i,

    // read port
    input  REG_t        rs1_index_i,
    input  REG_t        rs2_index_i,
    input  REG_t        rs3_index_i,
    output logic [31:0] rs1_data_o,
    output logic [31:0] rs2_data_o,
    output logic [31:0] rs3_data_o
);
    // --------------------------------------------
    //              Signal Declaration             
    // --------------------------------------------
    logic [31:0] register[32]; // 32 x 32 bits registers

    // --------------------------------------------
    //               Registers update              
    // --------------------------------------------
    assign rs1_data_o = register[rs1_index_i];
    assign rs2_data_o = register[rs2_index_i];
    assign rs3_data_o = register[rs3_index_i];

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            foreach (register[i]) begin
                register[i] <= 32'd0;
            end
        end else begin
            // update architectural state
            if (wb_en_i) begin
                register[rd_index_i] <= rd_data_i;
            end
        end
    end

endmodule