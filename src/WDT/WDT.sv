module WDT (
    input  logic        clk,
    input  logic        rst,
    input  logic        WDEN,
    input  logic        WDLIVE,
    input  logic [31:0] WTOCNT,
    output logic        WTO,
    output logic        WTO_write
);

    logic [31:0] WDT_counter;
    logic        timeout;

    always_ff @(posedge clk) begin
        if     (rst)     WDT_counter <= 32'd0;
        else if(!WDEN)   WDT_counter <= 32'd0;
        else if(WDLIVE)  WDT_counter <= 32'd0;
        else if(timeout) WDT_counter <= WDT_counter;
        else             WDT_counter <= WDT_counter + 32'd1;
    end

    assign timeout = (WDT_counter >= WTOCNT);

    always_ff @(posedge clk) begin
        if(rst) begin
            WTO       <= 1'b0;
            WTO_write <= 1'b0;
        end else begin
            WTO       <= (WDEN & timeout);
            WTO_write <= (WTO != (WDEN & timeout));
        end
    end

endmodule