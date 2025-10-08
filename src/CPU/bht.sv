/**************************************************
 *  Course   : AVSD - Autumn 2024                 *
 *  Project  : Final Project                      *
 *  Editor   : NicholasCYC                        *
 *  Date     : January 2025                       *
 **************************************************/

module bht (
    input  logic        clk,
    input  logic        rst,
    input  logic [31:0] pc,    // current PC to query
    output logic        taken, // whether taken

    input BHT_data bht_update
);

    parameter BHT_SIZE = 32; // number of entries in the BHT
    parameter INDEX_BITS = 5;

    logic [1:0] bht [BHT_SIZE];

    logic [INDEX_BITS-1:0] index;
    assign index = pc[INDEX_BITS+1:2]; // pc[1:0] is always 0

    // query the BHT
    assign taken = (bht[index][1] == 1'b1);


    logic [1:0] counter;
    assign counter = bht[bht_update.pc[INDEX_BITS+1:2]];

    always_ff @(posedge clk) begin : updata_BHT
        if (rst) begin
            for (int i = 0; i < BHT_SIZE; i++) begin
                bht[i] <= 2'd0;
            end
        end else if (bht_update.valid) begin
            if (bht_update.taken) begin
                if (counter != 2'b11) begin // increment if not at max
                    bht[bht_update.pc[INDEX_BITS+1:2]] <= counter + 2'd1;
                end
            end else begin
                if (counter != 2'b00) begin // decrement if not at min
                    bht[bht_update.pc[INDEX_BITS+1:2]] <= counter - 2'd1;
                end
            end
        end
    end

endmodule
