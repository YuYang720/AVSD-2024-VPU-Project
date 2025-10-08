module AR_FIFO (
    // write port
    input  logic        w_clk,
    input  logic        w_rst,
    input  logic        w_push,
    input  logic [44:0] w_data,
    output logic        w_full,

    // read port
    input  logic        r_clk,
    input  logic        r_rst,
    input  logic        r_pop,
    output logic [44:0] r_data,
    output logic        r_empty
);

    // --------------------------------------------
    //              Signal Declaration             
    // --------------------------------------------
    localparam int unsigned data_bits = 45;

    // fifo memory
    logic [data_bits-1:0] mem;

    // fifo pointer
    logic                 write_enable, read_enable;
    logic                 write_ptr, read_ptr;
    logic                 write_ptr_r_clk, read_ptr_w_clk;

    // two filp-flop synchronzier
    logic                 temp_data_r_clk, temp_data_w_clk;

    // --------------------------------------------
    //          Two Flip-Flop synchronizer         
    // --------------------------------------------
    always_ff @(posedge r_clk) begin
        if (r_rst) begin
            temp_data_r_clk <= 1'b0;
            write_ptr_r_clk <= 1'b0;
        end else begin
            temp_data_r_clk <= write_ptr;
            write_ptr_r_clk <= temp_data_r_clk;
        end
    end

    always_ff @(posedge w_clk) begin
        if (w_rst) begin
            temp_data_w_clk <= 1'b0;
            read_ptr_w_clk  <= 1'b0;
        end else begin
            temp_data_w_clk <= read_ptr;
            read_ptr_w_clk  <= temp_data_w_clk;
        end
    end

    // --------------------------------------------
    //               FIFO data update              
    // --------------------------------------------
    assign w_full       = (write_ptr != read_ptr_w_clk);
    assign r_empty      = (read_ptr  == write_ptr_r_clk);
    assign r_data       = mem;
    assign write_enable = (w_push && ~w_full);
    assign read_enable  = (r_pop  && ~r_empty);

    always_ff @(posedge w_clk) begin : push
        if (w_rst) begin
            mem       <= data_bits'(0);
            write_ptr <= 1'b0;
        end else if (write_enable) begin
            mem       <= w_data;
            write_ptr <= ~write_ptr;
        end
    end

    always_ff @(posedge r_clk) begin
        if      (r_rst)       read_ptr <= 1'b0;
        else if (read_enable) read_ptr <= ~read_ptr;
    end

    // --------------------------------------------
    //               Assertions Check              
    // --------------------------------------------
    // WRITE_FULL_CHECK :
    //     assert property (
    //         @(posedge w_clk) disable iff (w_rst) (!w_push || !w_full))
    //         else $error ("\n *** Assertion failed: Push operation when FIFO is full. *** \n");

    // READ_EMPTY_CHECK :
    //     assert property (
    //         @(posedge r_clk) disable iff (r_rst) (!r_pop || !r_empty))
    //         else $error ("\n *** Assertion failed: Pop operation when FIFO is empty. *** \n");

endmodule