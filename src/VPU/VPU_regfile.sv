module VPU_regfile (
    input  logic                 clk_i,
    input  logic                 rst_i,

    // read port (3 ports, and 1 v0 read port)
    input  logic [2:0][4:0]      vreg_read_addr_i,
    output logic [2:0][VLEN-1:0] vreg_read_data_o,
    output logic [VLEN-1:0]      vreg_v0_o,

    // write port (1 ports)
    input  logic                 vreg_write_en_i,
    input  logic [4:0]           vreg_write_addr_i,
    input  logic [VLEN/8-1:0]    vreg_write_bweb_i,
    input  logic [VLEN-1:0]      vreg_write_data_i
);

    // --------------------------------------------
    //              Signal Declaration             
    // --------------------------------------------
    logic [VLEN-1:0] register[32]; // 32 x 64 bits registers

    // --------------------------------------------
    //               Registers update              
    // --------------------------------------------
    assign vreg_v0_o           = register[0];
    assign vreg_read_data_o[0] = register[vreg_read_addr_i[0]];
    assign vreg_read_data_o[1] = register[vreg_read_addr_i[1]];
    assign vreg_read_data_o[2] = register[vreg_read_addr_i[2]];
    
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            foreach (register[i]) begin
                register[i] <= VLEN'(0);
            end
        end else begin
            // update architectural state
            for (int i = 0; i < VLEN / 8; i++) begin
                if (vreg_write_en_i && vreg_write_bweb_i[i]) begin
                    register[vreg_write_addr_i][i*8 +: 8] <= vreg_write_data_i[i*8 +: 8];
                end
            end
        end
    end

endmodule