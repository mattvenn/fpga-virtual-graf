`default_nettype none
module i2c_init(
    input wire clk,
    input wire reset,
    input wire start,
    output wire i2c_sda,
    output wire i2c_scl
);
    reg [8:0] state = STATE_IDLE;
    reg [6:0] i2c_addr = 7'h21;
    reg [7:0] i2c_data;
    reg i2c_start = 0;
    wire i2c_ready;

    localparam STATE_IDLE = 0;
    localparam STATE_PK1 = 1;
    localparam STATE_WAIT1 = 2;
    localparam STATE_PK2 = 3;
    localparam STATE_WAIT2 = 4;
    localparam STATE_STOP = 5;

  i2c_master i2c(.clk (clk),  .addr(i2c_addr), .data(i2c_data), .reset (reset), .i2c_sda (i2c_sda), .i2c_scl (i2c_scl), .ready(i2c_ready), .start(i2c_start));

    always@(posedge clk) begin
        case(state)
            STATE_IDLE: begin
                if(start) begin
                    state <= STATE_PK1;
                end
            end
            STATE_PK1: begin
                i2c_data <= 8'hAA;
                i2c_start <= 1;
                if(! i2c_ready)
                    state = STATE_WAIT1;
            end
            STATE_WAIT1: begin
                i2c_start <= 0;
                if(i2c_ready) 
                    state = STATE_PK2;
            end
            STATE_PK2: begin
                i2c_data = 8'hBB;
                i2c_start <= 1;
                if(! i2c_ready)
                    state = STATE_WAIT2;
            end
            STATE_WAIT2: begin
                i2c_start <= 0;
                if(i2c_ready) 
                    state = STATE_STOP;
            end
            STATE_STOP: begin
                // wait till trigger is finished
                if(start == 0)
                    state <= STATE_IDLE;
            end
        endcase

    end
endmodule
