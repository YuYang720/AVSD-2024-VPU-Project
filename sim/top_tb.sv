`timescale 1ns/10ps
`include "CYCLE_MAX.sv"
`include "ROM/ROM.v"
`include "DRAM/DRAM.sv"

`ifdef SYN
`include "CHIP_syn.v"
`include "data_array/data_array_rtl.sv"
`include "tag_array/tag_array_rtl.sv"
`include "SRAM/SRAM_rtl.sv"
`timescale 1ns/10ps
`include "/usr/cad/CBDK/Executable_Package/Collaterals/IP/stdcell/N16ADFP_StdCell/VERILOG/N16ADFP_StdCell.v"
`include "/usr/cad/CBDK/Executable_Package/Collaterals/IP/stdio/N16ADFP_StdIO/VERILOG/N16ADFP_StdIO.v"
`elsif PR
`include "../pr/CHIP_pr.v"
`include "SRAM/SRAM_rtl.sv"
`include "data_array/data_array_rtl.sv"
`include "tag_array/tag_array_rtl.sv"
`timescale 1ns/10ps
`include "/usr/cad/CBDK/Executable_Package/Collaterals/IP/stdcell/N16ADFP_StdCell/VERILOG/N16ADFP_StdCell.v"
`include "/usr/cad/CBDK/Executable_Package/Collaterals/IP/stdio/N16ADFP_StdIO/VERILOG/N16ADFP_StdIO.v"
`else
`include "CHIP.v"
`include "SRAM/SRAM_rtl.sv"
`include "data_array/data_array_rtl.sv"
`include "tag_array/tag_array_rtl.sv"
`endif

`define mem_word0(addr) {chip.u_TOP.DM1.i_SRAM0.MEMORY[addr >> 5][(addr&6'b011111)]}
`define mem_word1(addr) {chip.u_TOP.DM1.i_SRAM1.MEMORY[addr >> 5][(addr&6'b011111)]}

`define dram_word(addr) \
    {i_DRAM.Memory_byte3[addr], \
     i_DRAM.Memory_byte2[addr], \
     i_DRAM.Memory_byte1[addr], \
     i_DRAM.Memory_byte0[addr]}

`define SIM_END 'h3fff
`define SIM_END_CODE -32'd1
`define TEST_START 'h40000

module top_tb;
    logic cpu_clk;
    logic wdt_clk;
    logic cpu_rst;
    logic wdt_rst;

    logic [31:0] GOLDEN[4096];
    logic [ 7:0] Memory_byte0[16383:0];
    logic [ 7:0] Memory_byte1[16383:0];
    logic [ 7:0] Memory_byte2[16383:0];
    logic [ 7:0] Memory_byte3[16383:0];
    logic [31:0] Memory_word [16383:0];

    // ROM memory port
    logic        ROM_read;
    logic        ROM_enable;
    logic [11:0] ROM_address;
    logic [31:0] ROM_out;

    // DRAM memory port
    logic        DRAM_CSn;
    logic [3:0]  DRAM_WEn;
    logic        DRAM_RASn;
    logic        DRAM_CASn;
    logic [10:0] DRAM_A;
    logic [31:0] DRAM_D;
    logic        DRAM_valid;
    logic [31:0] DRAM_Q;

    integer      gf, i, num, fc;
    integer      err;
    string       prog_path;
    logic [31:0] temp;

    always #(`CPU_CYCLE/2) cpu_clk = ~cpu_clk;
    always #(`WDT_CYCLE/2) wdt_clk = ~wdt_clk;
 
    CHIP chip (
        .cpu_clk     ( cpu_clk     ),
        .wdt_clk     ( wdt_clk     ),
        .cpu_rst     ( cpu_rst     ),
        .wdt_rst     ( wdt_rst     ),
        .ROM_out     ( ROM_out     ),
        .DRAM_valid  ( DRAM_valid  ),
        .DRAM_Q      ( DRAM_Q      ),
        .ROM_read    ( ROM_read    ),
        .ROM_enable  ( ROM_enable  ),
        .ROM_address ( ROM_address ),
        .DRAM_CSn    ( DRAM_CSn    ),
        .DRAM_WEn    ( DRAM_WEn    ),
        .DRAM_RASn   ( DRAM_RASn   ),
        .DRAM_CASn   ( DRAM_CASn   ),
        .DRAM_A      ( DRAM_A      ),
        .DRAM_D      ( DRAM_D      )
    );

    ROM i_ROM (
        .CK ( cpu_clk     ),
        .CS ( ROM_enable  ),
        .OE ( ROM_read    ),
        .A  ( ROM_address ),
        .DO ( ROM_out     )
    );

    DRAM i_DRAM (
        .CK    ( cpu_clk    ),
        .Q     ( DRAM_Q     ),
        .RST   ( cpu_rst    ),
        .CSn   ( DRAM_CSn   ),
        .WEn   ( DRAM_WEn   ),
        .RASn  ( DRAM_RASn  ),
        .CASn  ( DRAM_CASn  ),
        .A     ( DRAM_A     ),
        .D     ( DRAM_D     ),
        .VALID ( DRAM_valid )
    );

    initial begin
        cpu_clk = 0; cpu_rst = 1;
        wdt_clk = 0; wdt_rst = 1;
        #(`CPU_CYCLE + `WDT_CYCLE) cpu_rst = 0; wdt_rst = 0;

        $value$plusargs("prog_path=%s", prog_path);
        $readmemh({prog_path, "/rom0.hex" }, i_ROM.Memory_byte0 );
        $readmemh({prog_path, "/rom1.hex" }, i_ROM.Memory_byte1 );
        $readmemh({prog_path, "/rom2.hex" }, i_ROM.Memory_byte2 );
        $readmemh({prog_path, "/rom3.hex" }, i_ROM.Memory_byte3 );
        $readmemh({prog_path, "/dram0.hex"}, i_DRAM.Memory_byte0);
        $readmemh({prog_path, "/dram1.hex"}, i_DRAM.Memory_byte1);
        $readmemh({prog_path, "/dram2.hex"}, i_DRAM.Memory_byte2);
        $readmemh({prog_path, "/dram3.hex"}, i_DRAM.Memory_byte3);

        num = 0;
        gf  = $fopen({prog_path, "/golden.hex"}, "r");
        while (!$feof(gf)) begin
            fc = $fscanf(gf, "%h\n", GOLDEN[num]);
            num++;
        end
        $fclose(gf);

        while (1) begin
            #(`CPU_CYCLE)
            if (`mem_word1(`SIM_END) == `SIM_END_CODE) begin
                break;
            end
        end
        $display("\nDone\n");

        err = 0;
        for (i = 0; i < num; i++) begin
            if (`dram_word(`TEST_START + i) !== GOLDEN[i]) begin
                err = err + 1;
                $display("DRAM[%4d] = %h, expect = %h", `TEST_START + i, `dram_word(`TEST_START + i), GOLDEN[i]);
            end else begin
                $display("DRAM[%4d] = %h, pass", `TEST_START + i, `dram_word(`TEST_START + i));
            end
        end

        result(err, num);
        $finish;
    end

    `ifdef SYN
        initial $sdf_annotate("../syn/CHIP_syn.sdf", chip);
    `elsif PR
        initial $sdf_annotate("../pr/CHIP_pr.sdf", chip);
    `endif

    initial begin
        `ifdef FSDB
        $fsdbDumpfile("chip.fsdb");
        $fsdbDumpvars;
        `elsif FSDB_ALL
        $fsdbDumpfile("chip.fsdb");
        $fsdbDumpvars("+struct", "+mda", chip);
        $fsdbDumpvars("+struct", i_DRAM);
        $fsdbDumpvars("+struct", i_ROM);
        `endif

        #(`CPU_CYCLE * `MAX)
        for (i = 0; i < num; i++) begin
            if (`dram_word(`TEST_START + i) !== GOLDEN[i]) begin
                $display("DRAM[%4d] = %h, expect = %h", `TEST_START + i, `dram_word(`TEST_START + i), GOLDEN[i]);
                err=err+1;
            end else begin
                $display("DRAM[%4d] = %h, pass", `TEST_START + i, `dram_word(`TEST_START + i));
            end
        end

        $display("SIM_END(%5d) = %h, expect = %h", `SIM_END, `dram_word(`SIM_END), `SIM_END_CODE);
        result(num, num);
        $finish;
    end

    task result;
        input integer err;
        input integer num;
        integer rf;

        begin
        `ifdef SYN
            rf = $fopen({prog_path, "/result_syn.txt"}, "w");
            `elsif PR
            rf = $fopen({prog_path, "/result_pr.txt"}, "w");
        `else
            rf = $fopen({prog_path, "/result_rtl.txt"}, "w");
        `endif

        $fdisplay(rf, "%d,%d", num - err, num);
        if (err === 0) begin
            $display("\n");
            $display("\n");
            $display("        ****************************               ");
            $display("        **                        **       |\__||  ");
            $display("        **  Congratulations !!    **      / O.O  | ");
            $display("        **                        **    /_____   | ");
            $display("        **  Simulation PASS!!     **   /^ ^ ^ \\  |");
            $display("        **                        **  |^ ^ ^ ^ |w| ");
            $display("        ****************************   \\m___m__|_|");
            $display("\n");
        end else begin
            $display("\n");
            $display("\n");
            $display("        ****************************               ");
            $display("        **                        **       |\__||  ");
            $display("        **  OOPS!!                **      / X,X  | ");
            $display("        **                        **    /_____   | ");
            $display("        **  Simulation Failed!!   **   /^ ^ ^ \\  |");
            $display("        **                        **  |^ ^ ^ ^ |w| ");
            $display("        ****************************   \\m___m__|_|");
            $display("         Totally has %d errors                     ", err);
            $display("\n");
        end
        end
    endtask

endmodule
