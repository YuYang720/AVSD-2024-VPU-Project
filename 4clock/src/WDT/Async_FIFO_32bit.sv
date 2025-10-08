module Async_FIFO_32bit (
    input  logic        w_clk,
    input  logic        w_rst,
    input  logic        w_push,
    input  logic [31:0] w_data,
    output logic        w_full,

    input  logic        r_clk,
    input  logic        r_rst,
    input  logic        r_pop,
    output logic [31:0] r_data,
    output logic        r_empty
);

    logic [31:0] mem [2];
    logic [31:0] read_data;
    logic        read_enable;
    logic        read_ptr;
    logic        read_ptr_wclk;
    logic        write_enable;
    logic        write_ptr;
    logic        write_ptr_rclk;

    assign write_full   = (write_ptr != read_ptr_wclk );
    assign read_empty   = (read_ptr  == write_ptr_rclk);
    assign write_enable = (w_push & ~write_full);
    assign read_enable  = (r_pop  & ~read_empty);

    Two_Flip_Flop write_ptr_rclk_wire (
        .clk     (r_clk         ),
        .rst     (r_rst         ),
        .din     (write_ptr     ),
        .dout    (write_ptr_rclk)
    );

    Two_Flip_Flop read_ptr_wclk_wire (
        .clk     (w_clk         ),
        .rst     (w_rst         ),
        .din     (read_ptr      ),
        .dout    (read_ptr_wclk )
    );

    // FIFO write control
    always_ff @(posedge w_clk) begin
        if (w_rst) begin
            foreach(mem[i]) mem[i] <= 32'd0;
            write_ptr              <= 1'b0;
        end else if (write_enable) begin
            mem[write_ptr] <= w_data;
            write_ptr      <= ~write_ptr; // wptr + 1
        end else begin
            mem       <= mem;
            write_ptr <= write_ptr;
        end
    end

    // FIFO read control
    always_ff @(posedge r_clk) begin
        if (r_rst) begin
            read_ptr  <= 1'b0;
            read_data <= 32'd0;
        end else if (read_enable) begin
            read_ptr  <= ~read_ptr; // rptr + 1
            read_data <= mem[read_ptr];
        end else begin
            read_ptr  <= read_ptr;
            read_data <= read_data;
        end
    end

    assign w_full  = write_full;
    assign r_data  = read_data;
    assign r_empty = read_empty;

endmodule