module Two_Flip_Flop (
    input  logic clk,
    input  logic rst,
    input  logic din,
    output logic dout
);

    logic FF1_Data;

    always_ff @(posedge clk) begin
        if (rst) FF1_Data <= 1'b0;
        else     FF1_Data <= din;
    end

    always_ff @(posedge clk) begin
        if (rst) dout <= 1'b0;
        else     dout <= FF1_Data;
    end

endmodule