module VPU_commit_stage (
    input  logic        clk_i,
    input  logic        rst_i,

    // from VCFG unit
    input  logic        VCFG_read_valid_i,
    input  logic [31:0] VCFG_read_data_i,
    output logic        VCFG_commit_o,

    // from EXE
    input  logic        lsu_commit_i,

    // writeback to CPU
    output logic        vector_lsu_valid_o,
    output logic        vector_result_valid_o,
    output logic [31:0] vector_result_o
);

    // --------------------------------------------
    //              Signal Declaration             
    // --------------------------------------------

    // --------------------------------------------
    //           VPU <-> CPU commit logic          
    // --------------------------------------------
    always_comb begin
        VCFG_commit_o         = 1'b0;
        vector_result_valid_o = 1'b0;
        vector_result_o       = 32'd0;

        if (VCFG_read_valid_i) begin
            VCFG_commit_o         = 1'b1;
            vector_result_valid_o = 1'b1;
            vector_result_o       = VCFG_read_data_i;
        end
    end

    // --------------------------------------------
    //          VPU internal commit logic          
    // --------------------------------------------
    assign vector_lsu_valid_o = lsu_commit_i;

endmodule