/**************************************************
 *  Course   : AVSD - Autumn 2024                 *
 *  Project  : Final Project                      *
 *  Editor   : NicholasCYC                        *
 *  Date     : January 2025                       *
 **************************************************/

module btb (
    input  logic        clk,
    input  logic        rst,
    input  logic [31:0] pc,     // current PC to query
    output logic [31:0] target, // predicted target address
    output logic        valid,  // whether the prediction is valid

    input BTB_data btb_update
);

    parameter BTB_SIZE = 32; // number of entries in the BTB
    parameter INDEX_BITS = 5;

    BTB_data btb [BTB_SIZE];

    logic [INDEX_BITS-1:0] index;
    assign index = pc[INDEX_BITS+1:2]; // pc[1:0] is always 0

    // query the BTB
    assign target = btb[index].target_addr;
    assign valid  = (btb[index].valid && btb[index].pc == pc);


    logic  update_pc_valid;
    assign update_pc_valid = btb_update.pc[INDEX_BITS+1:2] != 5'd0;

    always_ff @(posedge clk) begin : update_BTB
        if (rst) begin
            for (int i = 0; i < BTB_SIZE; i++) begin
                btb[i] <= BTB_data'(0);
            end
        end else if (btb_update.valid && update_pc_valid) begin
            btb[btb_update.pc[INDEX_BITS+1:2]] <= 
            {1'd1, btb_update.pc, btb_update.target_addr};
        end
    end

endmodule
