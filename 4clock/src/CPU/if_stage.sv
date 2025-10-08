module if_stage (
    input  logic         clk_i,
    input  logic         rst_i,

    // control signal
    input  logic         booting_i,
    input  logic         flush_i,
    input  logic         BU_flush_i,

    // request to I$
    output logic         icache_core_request_o,
    output logic [31:0]  icache_core_pc_o,
    input  logic         icache_core_wait_i,
    input  logic [31:0]  icache_core_addr_i,
    input  logic [31:0]  icache_core_out_i,

    // control flow signals
    input  logic         btkn_i,
    input  logic         trap_valid_i,
    input  logic         mret_i,
    input  logic [31:0]  bta_i,
    input  logic [31:0]  mtvec_i,
    input  logic [31:0]  mepc_i,

    // to ID
    output FETCH_ENTRY_t fetch_entry_o,
    input  logic         fetch_ack_i,

    // Branch Prediction
    input BHT_data       bht_update,
    input BTB_data       btb_update,

    output predict_info  BP_info_IF_to_ID
);

    // --------------------------------------------
    //              Signal Declaration             
    // --------------------------------------------
    // instruction queue
    FETCH_ENTRY_t           IQ[IQ_DEPTH];
    logic                   iq_full, iq_push, iq_pop;
    logic [IQ_TAG_BITS  :0] iq_size_q, iq_size_n;
    logic [IQ_TAG_BITS-1:0] top_ptr_q, top_ptr_n;
    logic [IQ_TAG_BITS-1:0] decode_ptr_q, decode_ptr_n;

    // request to I$
    logic                   fetch_wait;
    logic [31:0]            fetch_pc_q, fetch_pc_n;

    // Branch Prediction
    logic bht_taken, btb_valid, predict_ready;
    logic [31:0] btb_target;

    logic ras_push, ras_pop, ras_valid, push_pop_valid, RET;
    logic [31:0] ras_data_in, ras_data_out;
    logic [31:0] last_inst;

    logic [31:0] if_inst, if_pc;

    // --------------------------------------------
    //        Fetch PC / Request Generation        
    // --------------------------------------------
    // always fetch new instruction when IQ is not full
    assign icache_core_request_o = ~(iq_full | booting_i);
    assign icache_core_pc_o      = fetch_pc_n;
    assign fetch_wait            = (icache_core_wait_i) | (icache_core_addr_i != fetch_pc_q);

    // choose next pc address
    always_comb begin
        priority if (booting_i    ) fetch_pc_n = 32'd0;
        else if     (mret_i       ) fetch_pc_n = mepc_i;
        else if     (trap_valid_i ) fetch_pc_n = mtvec_i;
        //else if     (btkn_i       ) fetch_pc_n = bta_i;
        else if     (BU_flush_i   ) fetch_pc_n = bta_i;
        else if     (iq_full      ) fetch_pc_n = fetch_pc_q;
        else if     (fetch_wait   ) fetch_pc_n = fetch_pc_q;
        else if     (RET          ) fetch_pc_n = ras_data_out;
        else if     (predict_ready) fetch_pc_n = btb_target;
        else                        fetch_pc_n = fetch_pc_q + 32'd4;
    end

    // update flying request pc value
    always_ff @(posedge clk_i) begin
        if (rst_i) fetch_pc_q <= 32'd0;
        else       fetch_pc_q <= fetch_pc_n;
    end

    // --------------------------------------------
    //              Branch Prediction              
    // --------------------------------------------
    assign if_pc         = icache_core_addr_i; //fetch_entry_o.pc;
    assign if_inst       = icache_core_out_i;  //fetch_entry_o.inst;
    assign predict_ready = btb_valid && bht_taken;

    bht branch_history_table (
        .clk        (clk_i     ),
        .rst        (rst_i     ),
        .pc         (if_pc     ),
        .taken      (bht_taken ),

        .bht_update (bht_update)
    );

    btb branch_target_buffer (
        .clk        (clk_i     ),
        .rst        (rst_i     ),
        .pc         (if_pc     ),
        .target     (btb_target),
        .valid      (btb_valid ),

        .btb_update (btb_update)
    );

    ras return_address_stack (
        .clk        (clk_i       ),
        .rst        (rst_i       ),
        .push       (ras_push    ),
        .pop        (ras_pop     ),
        .data_in    (ras_data_in ),
        .data_out   (ras_data_out),
        .valid      (ras_valid   )
    );

    always_ff @(posedge clk_i) begin
        if (rst_i) last_inst <= 32'd0;
        else       last_inst <= if_inst;
    end

    assign push_pop_valid = (last_inst != if_inst);
    assign RET = (if_inst == `RET && ras_valid);

    always_comb begin
        ras_push    = 1'b0;
        ras_pop     = 1'b0;
        ras_data_in = 32'd0;

        // RET instruction (JALR x0, x1, 0)
        if (if_inst == `RET) begin
            ras_pop = push_pop_valid && ras_valid;
        end else if (if_inst[`RD] == 5'd1 && if_inst[`OPCODE] inside {JALR_OP, JAL_OP}) begin
            ras_push = push_pop_valid;
            ras_data_in = if_pc + 32'd4; // return address is PC + 4
        end
    end

    // --------------------------------------------
    //       Instruction Queue (FIFO pointer)      
    // --------------------------------------------
    assign iq_full          = (iq_size_q == (IQ_TAG_BITS+1)'(IQ_DEPTH));
    assign fetch_entry_o    = IQ[decode_ptr_q];
    assign BP_info_IF_to_ID = IQ[decode_ptr_q].BP_info;

    always_comb begin
        iq_size_n    = iq_size_q;
        top_ptr_n    = top_ptr_q;
        decode_ptr_n = decode_ptr_q;
        iq_push      = 1'b0;
        iq_pop       = 1'b0;

        // top pointer update
        if (~(fetch_wait | iq_full)) begin
            iq_push   = 1'b1;
            top_ptr_n = top_ptr_q + IQ_TAG_BITS'(1);
        end

        // decode pointer update
        if (fetch_ack_i) begin
            iq_pop       = 1'b1;
            decode_ptr_n = decode_ptr_q + IQ_TAG_BITS'(1);
        end

        // instruction queue size update
        unique case ({iq_push, iq_pop})
            2'b01   : iq_size_n = iq_size_q - (IQ_TAG_BITS+1)'(1);
            2'b10   : iq_size_n = iq_size_q + (IQ_TAG_BITS+1)'(1);
            default : ; // nothing to do
        endcase

        // flush the whole instruction queue --> reset pointer and size to 0
        if (flush_i) begin
            iq_size_n    = (IQ_TAG_BITS+1)'(0);
            top_ptr_n    = (IQ_TAG_BITS)'(0);
            decode_ptr_n = (IQ_TAG_BITS)'(0);
        end
    end

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            iq_size_q    <= (IQ_TAG_BITS+1)'(0);
            top_ptr_q    <= IQ_TAG_BITS'(0);
            decode_ptr_q <= IQ_TAG_BITS'(0);
        end else begin
            iq_size_q    <= iq_size_n;
            top_ptr_q    <= top_ptr_n;
            decode_ptr_q <= decode_ptr_n;
        end
    end

    // --------------------------------------------
    //          Instruction Queue (Memory)         
    // --------------------------------------------
    always_ff @(posedge clk_i) begin
        if (rst_i) begin

            foreach (IQ[i]) begin
                IQ[i].valid <= 1'b0;
                IQ[i].pc    <= 32'd0;
                IQ[i].inst  <= 32'd0;
                IQ[i].BP_info <= predict_info'(0);
            end

        end else begin

            // insert new instruction into IQ when valid and IQ is not full
            if (~(fetch_wait | iq_full)) begin
                IQ[top_ptr_q].valid <= 1'b1;
                IQ[top_ptr_q].pc    <= icache_core_addr_i;
                IQ[top_ptr_q].inst  <= icache_core_out_i;
                IQ[top_ptr_q].BP_info <= 
                {predict_ready, btb_target, RET, ras_data_out};
            end

            // if the decode entry is ack
            // so the entry is no longer valid and can be replaced
            if (fetch_ack_i) begin
                IQ[decode_ptr_q].valid <= 1'b0;
                IQ[decode_ptr_q].pc    <= 32'd0; // may delete this line
                IQ[decode_ptr_q].inst  <= 32'd0; // may delete this line
                IQ[decode_ptr_q].BP_info <= predict_info'(0);
            end

            // flush the whole instruction queue
            // --> invalidate all the entry
            if (flush_i) begin
                foreach (IQ[i]) begin
                    IQ[i].valid <= 1'b0;
                    IQ[i].pc    <= 32'd0; // may delete this line
                    IQ[i].inst  <= 32'd0; // may delete this line
                    IQ[i].BP_info <= predict_info'(0);
                end
            end
        end
    end

endmodule