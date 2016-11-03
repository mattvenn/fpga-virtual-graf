`default_nettype none
module i2c_init(
    input wire clk,
    input wire reset,
    input wire start,
    input wire [3*8-1:0] flat_i2c_data,
    input wire [2:0] packets,
    output wire i2c_sda,
    output wire i2c_scl
);
    reg [8:0] state = STATE_IDLE;
    reg [6:0] i2c_addr = 7'h21;
    reg [7:0] i2c_data;
    reg i2c_start = 0;
    reg [2:0] packet_count = 0;
    wire i2c_ready;

    localparam STATE_IDLE = 0;
    localparam STATE_SEND = 1;
    localparam STATE_WAIT = 2;
    localparam STATE_STOP = 3;

  i2c_master i2c(.clk (clk),  .addr(i2c_addr), .data(i2c_data), .reset (reset), .i2c_sda (i2c_sda), .i2c_scl (i2c_scl), .ready(i2c_ready), .start(i2c_start));

    always@(posedge clk) begin
        case(state)
            STATE_IDLE: begin
                if(start) begin
                    state <= STATE_SEND;
                end
            end
            STATE_SEND: begin
                i2c_data <= flat_i2c_data[packet_count*8 +: 8];
                i2c_start <= 1;
                if(! i2c_ready)
                    state = STATE_WAIT;
            end
            STATE_WAIT: begin
                i2c_start <= 0;
                if(i2c_ready) begin
                    packet_count <= packet_count + 1;
                    if(packet_count == packets - 1)
                        state = STATE_STOP;
                    else
                        state = STATE_SEND;
                end
            end
            STATE_STOP: begin
                // wait till trigger is finished
                if(start == 0)
                    state <= STATE_IDLE;
            end
        endcase

    end
endmodule
