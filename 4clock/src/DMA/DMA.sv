module DMA (
    input  logic                      clk,
    input  logic                      rst,

    // DMA ports
    output logic                      DMA_interrupt_o,
    input  logic                      valid_i,
    input  logic [31:0]               address_i,
    input  logic                      DMAEN,
    input  logic [31:0]               DMASRC,
    input  logic [31:0]               DMADST,
    input  logic [31:0]               DMALEN,

    // read request
    output logic                      READ_REQUEST,
    output logic [`AXI_ADDR_BITS-1:0] READ_ADDRESS,
    output logic [`AXI_LEN_BITS -1:0] READ_LEN,
    input  logic                      READ_VALID,
    input  logic [`AXI_DATA_BITS-1:0] READ_DATA,
    input  logic                      READ_FINISH,

    // write request
    output logic                      WRITE_REQUEST,
    output logic [`AXI_ADDR_BITS-1:0] WRITE_ADDRESS,
    output logic [`AXI_LEN_BITS -1:0] WRITE_LEN,
    output logic [`AXI_DATA_BITS-1:0] WRITE_DATA,
    output logic                      WRITE_LAST,
    input  logic                      WRITE_VALID,
    input  logic                      WRITE_FINISH
);

    // --------------------------------------------
    //              Signal Declaration             
    // --------------------------------------------
    parameter logic [31:0] EN_ADDR  = 32'h0000_0100;
    parameter logic [31:0] SRC_ADDR = 32'h0000_0200;
    parameter logic [31:0] DST_ADDR = 32'h0000_0300;
    parameter logic [31:0] LEN_ADDR = 32'h0000_0400;

    typedef enum logic [2:0] {VALID, READING, READ_FINISHED, WRITING, WAIT_RESP} STATUS_t;
    typedef enum logic [1:0] {IDLE, MOVE, FINISH} DMA_STATE_t;

    typedef struct packed {
        STATUS_t                   status;
        logic [`AXI_ADDR_BITS-1:0] read_addr;
        logic [`AXI_ADDR_BITS-1:0] write_addr;
        logic [`AXI_LEN_BITS -1:0] burst_length;
        logic [`AXI_DATA_BITS-1:0] data0;
        logic [`AXI_DATA_BITS-1:0] data1;
        logic [`AXI_DATA_BITS-1:0] data2;
        logic [`AXI_DATA_BITS-1:0] data3;
    } DMA_REQUEST_t;
    
    DMA_STATE_t   DMA_STATE_q, DMA_STATE_n;
    logic[31:0]   SRC_q, DST_q, LEN_q;
    logic[31:0]   SRC_n, DST_n, LEN_n;

    DMA_REQUEST_t REQUEST_QUEUE[2];
    DMA_REQUEST_t new_request, read_entry, write_entry;

    logic         request_valid;            // The new request can be inserted
    logic         top_ptr_q,  top_ptr_n;    // where to insert a new   request
    logic         read_ptr_q, read_ptr_n;   // current executing read  request
    logic         write_ptr_q, write_ptr_n; // current executing write request
    logic [1:0]   queue_size_q, queue_size_n;
    logic [1:0]   read_counter_q, read_counter_n;
    logic [1:0]   write_counter_q, write_counter_n;

    // --------------------------------------------
    //                  DMA logic                  
    // --------------------------------------------
    always_ff @(posedge clk) begin
        if (rst) begin
            DMA_STATE_q <= IDLE;
            SRC_q       <= 32'd0;
            DST_q       <= 32'd0;
            LEN_q       <= 32'd0;
        end else begin
            DMA_STATE_q <= DMA_STATE_n;
            SRC_q       <= SRC_n;
            DST_q       <= DST_n;
            LEN_q       <= LEN_n;
        end
    end

    always_comb begin
        DMA_STATE_n     = DMA_STATE_q;
        SRC_n           = SRC_q;
        DST_n           = DST_q;
        LEN_n           = LEN_q;

        // new request default assignment
        request_valid   = 1'b0;
        new_request     = DMA_REQUEST_t'(0);

        // default output
        DMA_interrupt_o = 1'b0;
        READ_REQUEST    = 1'b0;
        READ_ADDRESS    = 32'd0;
        READ_LEN        = 4'd0;
        WRITE_REQUEST   = 1'b0;
        WRITE_ADDRESS   = 32'd0;
        WRITE_LEN       = 4'd0;
        WRITE_DATA      = 32'd0;
        WRITE_LAST      = 1'b0;

        unique case(DMA_STATE_q)
            // in idle state, CSR can be writen by input
            IDLE : begin
                // only when data is valid, then the CSR can be updated
                if (valid_i) begin
                    unique case (address_i)
                        EN_ADDR  : if (DMAEN) DMA_STATE_n = MOVE;
                        SRC_ADDR : SRC_n = DMASRC;
                        DST_ADDR : DST_n = DMADST;
                        LEN_ADDR : LEN_n = DMALEN;
                        default  : ; // Nothing to do
                    endcase
                end
            end

            // in move stage, a read request will be generate to master
            // and if data comes back, it will then push in a queue
            // also, a write request will be generate according to the queue
            MOVE : begin
                // generate a read request if can
                if (queue_size_q != 2'd2 && LEN_q > 32'd0) begin
                    request_valid = 1'b1;
                    SRC_n         = SRC_q + 32'd16;
                    DST_n         = DST_n + 32'd16;
                    LEN_n         = LEN_q - 32'd4;
                    
                    // set up new request
                    new_request.status       = READING;
                    new_request.read_addr    = SRC_q;
                    new_request.write_addr   = DST_q;
                    new_request.burst_length = 4'd3; // --> read 4 words actually

                    // the last burst may have length < 4
                    if (LEN_q < 32'd4) begin
                        new_request.burst_length = LEN_q[3:0] - 4'd1;
                        LEN_n = 32'd0;
                    end
                end

                // send out read request signal
                if (REQUEST_QUEUE[read_ptr_q].status == READING) begin
                    READ_REQUEST = 1'b1;
                    READ_ADDRESS = REQUEST_QUEUE[read_ptr_q].read_addr;
                    READ_LEN     = REQUEST_QUEUE[read_ptr_q].burst_length;
                end

                // send write request signal
                if (REQUEST_QUEUE[write_ptr_q].status == WRITING) begin
                    WRITE_REQUEST = 1'b1;
                    WRITE_ADDRESS = REQUEST_QUEUE[write_ptr_q].write_addr;
                    WRITE_LEN     = REQUEST_QUEUE[write_ptr_q].burst_length;
                    WRITE_LAST    = (write_counter_q == REQUEST_QUEUE[write_ptr_q].burst_length[1:0]);
                    
                    unique case (write_counter_q)
                        2'd0 : WRITE_DATA = REQUEST_QUEUE[write_ptr_q].data0;
                        2'd1 : WRITE_DATA = REQUEST_QUEUE[write_ptr_q].data1;
                        2'd2 : WRITE_DATA = REQUEST_QUEUE[write_ptr_q].data2;
                        2'd3 : WRITE_DATA = REQUEST_QUEUE[write_ptr_q].data3;
                    endcase
                end

                // transition to FINISH state
                if ((LEN_q == 32'd0) && queue_size_q == 2'd0) begin
                    DMA_STATE_n = FINISH;
                end
            end

            // DMA completes the data transfer, send a DMA interrupt
            // if DMAEN signal is set to low, turn off interrupt
            FINISH : begin
                DMA_interrupt_o = 1'b1;

                if (valid_i & address_i == EN_ADDR) begin
                    DMA_STATE_n = IDLE;
                end
            end

            default : DMA_STATE_n = IDLE;
        endcase
    end

    // --------------------------------------------
    //                Request Queue                
    // --------------------------------------------
    always_ff @(posedge clk) begin
        if (rst) begin
            foreach (REQUEST_QUEUE[i]) begin
                REQUEST_QUEUE[i] <= DMA_REQUEST_t'(0);
            end

            top_ptr_q       <= 1'b0;
            read_ptr_q      <= 1'b0;
            write_ptr_q     <= 1'b0;
            queue_size_q    <= 2'd0;
            read_counter_q  <= 2'd0;
            write_counter_q <= 2'd0;

        end else begin

            foreach (REQUEST_QUEUE[i]) begin
                REQUEST_QUEUE[i] <= REQUEST_QUEUE[i];
            end

            REQUEST_QUEUE[write_ptr_q] <= write_entry;
            REQUEST_QUEUE[read_ptr_q ] <= read_entry;
            
            if ((write_ptr_q == read_ptr_q) & (REQUEST_QUEUE[read_ptr_q].status == READING)) begin
                REQUEST_QUEUE[read_ptr_q ] <= read_entry;
            end else begin
                REQUEST_QUEUE[write_ptr_q] <= write_entry;
            end

            // new request has higher priority
            if(request_valid) begin
                REQUEST_QUEUE[top_ptr_q] <= new_request;
            end

            top_ptr_q       <= top_ptr_n;
            read_ptr_q      <= read_ptr_n;
            write_ptr_q     <= write_ptr_n;
            read_counter_q  <= read_counter_n;
            write_counter_q <= write_counter_n;
            queue_size_q    <= queue_size_n;
        end
    end

    always_comb begin
        top_ptr_n       = top_ptr_q;
        read_ptr_n      = read_ptr_q;
        write_ptr_n     = write_ptr_q;
        read_counter_n  = read_counter_q;
        write_counter_n = write_counter_q;
        queue_size_n    = queue_size_q;
        read_entry      = REQUEST_QUEUE[read_ptr_q ];
        write_entry     = REQUEST_QUEUE[write_ptr_q];

        // update top pointer
        if (request_valid) top_ptr_n = top_ptr_q + 1'd1;

        // handling imcoming data
        if (READ_VALID) begin
            read_counter_n = read_counter_q + 2'd1;

            // Store the data
            unique case (read_counter_q)
                2'd0 : read_entry.data0 = READ_DATA;
                2'd1 : read_entry.data1 = READ_DATA;
                2'd2 : read_entry.data2 = READ_DATA;
                2'd3 : read_entry.data3 = READ_DATA;
            endcase
        end

        // if all data comes back, set status to finish
        if (READ_FINISH) begin
            read_counter_n    = 2'd0;
            read_entry.status = READ_FINISHED;
            read_ptr_n        = read_ptr_q + 1'd1;
        end

        // generate a write request
        // only can perform writing when all data comes back
        if (REQUEST_QUEUE[write_ptr_q].status == READ_FINISHED) begin
            write_entry.status = WRITING;
        end

        // handling finish/valid write request
        if (WRITE_FINISH) begin
            write_entry.status = VALID;
            write_ptr_n        = write_ptr_q + 1'd1;
            write_counter_n    = 2'd0;
        end else if (WRITE_VALID) begin
            write_counter_n    = write_counter_q + 2'd1;
            if(WRITE_LAST) write_entry.status = WAIT_RESP;
        end

        // upadte queue count
        unique case ({request_valid, WRITE_FINISH})
            2'b11   : queue_size_n = queue_size_q;
            2'b10   : queue_size_n = queue_size_q + 2'd1;
            2'b01   : queue_size_n = queue_size_q - 2'd1;
            default : queue_size_n = queue_size_q;
        endcase
    end

endmodule