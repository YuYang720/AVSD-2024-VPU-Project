`define FORMAL
module Formal_AXI_top(
    input         top_clk,  // 0.1  ns
    input         top_rst,

    // ROM memory port
    input  [31:0] ROM_out,
    output        ROM_read,
    output        ROM_enable,
    output [11:0] ROM_address,

    // DRAM memory port
    output        DRAM_CSn,
    output [ 3:0] DRAM_WEn,
    output        DRAM_RASn,
    output        DRAM_CASn,
    input         DRAM_valid,
    input  [31:0] DRAM_Q,
    output [10:0] DRAM_A,
    output [31:0] DRAM_D
);

    // --------------------------------------------
    //              Signal Declaration             
    // --------------------------------------------
    logic        cpu_clk_i;
    logic        cpu_rst_i;
    logic        wdt_clk_i;
    logic        wdt_rst_i;
    logic [31:0] ROM_out_i;
    logic        ROM_read_o;
    logic        ROM_enable_o;
    logic [11:0] ROM_address_o;
    logic [31:0] DRAM_Q_i;
    logic        DRAM_CSn_o;
    logic [ 3:0] DRAM_WEn_o;
    logic        DRAM_RASn_o;
    logic        DRAM_CASn_o;
    logic [10:0] DRAM_A_o;
    logic [31:0] DRAM_D_o;
    logic        DRAM_valid_i;
/*
    logic [31:0] cpu_counter_c, cpu_counter_n;
    logic [31:0] axi_counter_c, axi_counter_n;
    logic [31:0] rom_counter_c, rom_counter_n;
    logic [31:0] dram_counter_c, dram_counter_n;
    logic [31:0] rst_counter_c, rst_counter_n;
    always_ff @(posedge top_clk or posedge top_rst) begin        
        if (top_rst) begin
            cpu_counter_c   <= 32'b0;
            axi_counter_c   <= 32'b0;
            rom_counter_c   <= 32'b0;
            dram_counter_c  <= 32'b0;
            rst_counter_c   <= 32'b0;
        end
        else begin
            cpu_counter_c   <= cpu_counter_n;
            axi_counter_c   <= axi_counter_n;
            rom_counter_c   <= rom_counter_n;
            dram_counter_c  <= dram_counter_n;
            rst_counter_c   <= rst_counter_n;
        end
    end

    always_comb begin
        cpu_counter_n       = cpu_counter_c  + 32'b1;
        axi_counter_n       = axi_counter_c  + 32'b1;
        rom_counter_n       = rom_counter_c  + 32'b1;
        dram_counter_n      = dram_counter_c + 32'b1;
        rst_counter_n       = rst_counter_c  + 32'b1;
        if (top_rst) begin
            cpu_counter_n   = 32'b0;
            axi_counter_n   = 32'b0;
            rom_counter_n   = 32'b0;
            dram_counter_n  = 32'b0;
            rst_counter_n   = 32'b0;
        end
        if (cpu_counter_c  == 32'd19) begin
            cpu_counter_n   = 32'b0;
        end
        if (axi_counter_c  == 32'd49) begin
            axi_counter_n   = 32'b0;
        end
        if (rom_counter_c  == 32'd1001) begin
            rom_counter_n   = 32'b0;
        end
        if (dram_counter_c == 32'd99) begin
            dram_counter_n  = 32'b0;
        end
        if (rst_counter_c  == 32'd1002) begin
            rst_counter_n   = 32'd1002;
        end
    end

    assign cpu_clk_i  = cpu_counter_c  < 32'd10  ;
    assign wdt_clk_i  = axi_counter_c  < 32'd25  ;
    assign rom_clk_i  = rom_counter_c  < 32'd501 ;
    assign dram_clk_i = dram_counter_c < 32'd50  ;
    assign cpu_rst_i  = rst_counter_c  < 32'd1002;
    assign wdt_rst_i  = rst_counter_c  < 32'd1002;
    assign rom_rst_i  = rst_counter_c  < 32'd1002;
    assign dram_rst_i = rst_counter_c  < 32'd1002;
*/

assign cpu_clk_i  = top_clk;
assign wdt_clk_i  = top_clk;
assign cpu_rst_i  = top_rst;
assign wdt_rst_i  = top_rst;

    // assign ROM_out_i   = ROM_out;
    // assign ROM_read    = ROM_read_o;
    // assign ROM_enable  = ROM_enable_o;
    // assign ROM_address = ROM_address_o;

    // assign DRAM_CSn     = DRAM_CSn_o;
    // assign DRAM_WEn     = DRAM_WEn_o;
    // assign DRAM_RASn    = DRAM_RASn_o;
    // assign DRAM_CASn    = DRAM_CASn_o;
    // assign DRAM_valid_i = DRAM_valid;
    // assign DRAM_Q_i     = DRAM_Q;
    // assign DRAM_A       = DRAM_A_o;
    // assign DRAM_D       = DRAM_D_o;

    // --------------------------------------------
    //                Core instance                
    // --------------------------------------------
    top u_TOP(
        // CLOCK DOMAIN
        .cpu_clk     ( cpu_clk_i     ), // 1    ns
        .cpu_rst     ( cpu_rst_i     ),
        .wdt_clk     ( wdt_clk_i     ), // 2.5  ns
        .wdt_rst     ( wdt_rst_i     ),

        // ROM memory port
        .ROM_out     ( ROM_out_i     ),
        .ROM_read    ( ROM_read_o    ),
        .ROM_enable  ( ROM_enable_o  ),
        .ROM_address ( ROM_address_o ),

        // DRAM memory port
        .DRAM_valid  ( DRAM_valid_i  ),
        .DRAM_Q      ( DRAM_Q_i      ),
        .DRAM_CSn    ( DRAM_CSn_o    ),
        .DRAM_WEn    ( DRAM_WEn_o    ),
        .DRAM_RASn   ( DRAM_RASn_o   ),
        .DRAM_CASn   ( DRAM_CASn_o   ),
        .DRAM_A      ( DRAM_A_o      ),
        .DRAM_D      ( DRAM_D_o      )
    );
endmodule