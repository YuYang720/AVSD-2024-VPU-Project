/**************************************************
 *  Course   : AVSD - Autumn 2024                 *
 *  Project  : Final Project                      *
 *  Editor   : NicholasCYC                        *
 *  Date     : January 2025                       *
 **************************************************/

module ras (
    input  logic        clk,
    input  logic        rst,
    input  logic        push,
    input  logic        pop,
    input  logic [31:0] data_in,
    output logic [31:0] data_out,
    output              valid
);

    parameter int DEPTH = 8;

    typedef struct packed {
        logic        valid;
        logic [31:0] return_addr;
    } RAS_info;

    RAS_info stack_C[DEPTH], stack_N[DEPTH];

    assign data_out = stack_C[0].return_addr; // always return the top address
    assign valid = stack_C[0].valid;

    always_comb begin
        stack_N = stack_C;

        if (push) begin
            stack_N[0].return_addr = data_in;
            stack_N[0].valid = 1'b1;
            stack_N[1:DEPTH-1] = stack_C[0:DEPTH-2]; // shift existing entries
        end else if (pop) begin
            stack_N[0:DEPTH-2] = stack_C[1:DEPTH-1]; // shift up entries
            stack_N[DEPTH-1].valid = 1'b0;
            stack_N[DEPTH-1].return_addr = 32'd0;
        end
    end

    always_ff @(posedge clk) begin : update_RAS
        if (rst) begin
            for (int i = 0; i < DEPTH; i = i + 1) begin
                stack_C[i] <= RAS_info'(0);
            end
        end else begin
            stack_C <= stack_N;
        end
    end

endmodule
