module R_FIFO (
    // write port
    input  logic        w_clk,
    input  logic        w_rst,
    input  logic        w_push,
    input  logic [38:0] w_data,
    output logic        w_full,

    // read port
    input  logic        r_clk,
    input  logic        r_rst,
    input  logic        r_pop,
    output logic [38:0] r_data,
    output logic        r_empty
);

    // --------------------------------------------
    //              Signal Declaration             
    // --------------------------------------------
    localparam int unsigned data_bits = 39;
    localparam int unsigned ptr_bits  = 3;
    localparam int unsigned depth     = 2 ** (ptr_bits - 1);

    // fifo memory
    logic [data_bits-1:0] mem[depth];

    // fifo pointer
    logic                 write_enable, read_enable;
    logic [ptr_bits-1:0]  write_ptr, read_ptr;
    logic [ptr_bits-1:0]  write_ptr_r_clk, read_ptr_w_clk;

    // gray code
    logic [ptr_bits-1:0]  write_ptr_gray, read_ptr_gray;
    logic [ptr_bits-1:0]  write_ptr_gray_q, read_ptr_gray_q;
    logic [ptr_bits-1:0]  write_ptr_r_clk_gray, read_ptr_w_clk_gray;

    // two filp-flop synchronzier
    logic [ptr_bits-1:0]  temp_data_r_clk, temp_data_w_clk;

    // --------------------------------------------
    //            Gray code conversion             
    // --------------------------------------------
    // binary -> gray code
    assign write_ptr_gray = write_ptr ^ (write_ptr >> 1);
    assign read_ptr_gray  = read_ptr  ^ (read_ptr  >> 1);

    // gray code -> binary
    always_comb begin
        write_ptr_r_clk[ptr_bits-1] = write_ptr_r_clk_gray[ptr_bits-1];
        read_ptr_w_clk [ptr_bits-1] = read_ptr_w_clk_gray [ptr_bits-1];

        for (int i = ptr_bits - 2; i >= 0; i--) begin
            write_ptr_r_clk[i] = write_ptr_r_clk[i+1] ^ write_ptr_r_clk_gray[i];
            read_ptr_w_clk [i] = read_ptr_w_clk [i+1] ^ read_ptr_w_clk_gray [i];
        end
    end

    // prevent glitch
    always_ff @(posedge w_clk) begin
        if (w_rst) write_ptr_gray_q <= ptr_bits'(0);
        else       write_ptr_gray_q <= write_ptr_gray;
    end

    always_ff @(posedge r_clk) begin
        if (r_rst) read_ptr_gray_q <= ptr_bits'(0);
        else       read_ptr_gray_q <= read_ptr_gray;
    end

    // --------------------------------------------
    //          Two Flip-Flop synchronizer         
    // --------------------------------------------
    always_ff @(posedge r_clk) begin
        if (r_rst) begin
            temp_data_r_clk      <= ptr_bits'(0);
            write_ptr_r_clk_gray <= ptr_bits'(0);
        end else begin
            temp_data_r_clk      <= write_ptr_gray_q;
            write_ptr_r_clk_gray <= temp_data_r_clk;
        end
    end

    always_ff @(posedge w_clk) begin
        if (w_rst) begin
            temp_data_w_clk     <= ptr_bits'(0);
            read_ptr_w_clk_gray <= ptr_bits'(0);
        end else begin
            temp_data_w_clk     <= read_ptr_gray_q;
            read_ptr_w_clk_gray <= temp_data_w_clk;
        end
    end

    // --------------------------------------------
    //               FIFO data update              
    // --------------------------------------------
    assign w_full       = (write_ptr[ptr_bits-1]   != read_ptr_w_clk[ptr_bits-1]  ) &&
                          (write_ptr[ptr_bits-2:0] == read_ptr_w_clk[ptr_bits-2:0]);
    assign r_empty      = (read_ptr  == write_ptr_r_clk);
    assign r_data       = mem[ read_ptr[ptr_bits-2:0] ];
    assign write_enable = (w_push && ~w_full);
    assign read_enable  = (r_pop  && ~r_empty);

    always_ff @(posedge w_clk) begin : push
        if (w_rst) begin
            foreach (mem[i]) mem[i] <= data_bits'(0);
            write_ptr <= ptr_bits'(0);
        end else if (write_enable) begin
            mem[ write_ptr[ptr_bits-2:0] ] <= w_data;
            write_ptr <= write_ptr + ptr_bits'(1);
        end
    end

    always_ff @(posedge r_clk) begin
        if      (r_rst)       read_ptr <= ptr_bits'(0);
        else if (read_enable) read_ptr <= read_ptr + ptr_bits'(1);
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