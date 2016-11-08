/* probably needs to use a loop in the state to deal with all the config (6 paris of bytes)
*/
`default_nettype none
module camera(
    input wire clk,
    input wire reset,
    output reg [8:0] pos
);
    reg [8:0] state = STATE_START;
    reg i2c_start = 0;
    reg [4:0] packets;
    wire i2c_ready;
    reg [12*8-1:0] flat_i2c_data;
    reg rw = 1; // read
    reg [6:0] i2c_addr = 7'h58;

    localparam STATE_START = 0;
    localparam STATE_CONF_1 = 1;
    localparam STATE_WAIT_1 = 2;
    localparam STATE_CONF_2 = 3;
    localparam STATE_WAIT_2 = 4;
    localparam STATE_CONF_3 = 5;
    localparam STATE_WAIT_3 = 6;
    localparam STATE_STOP = 7;

    i2c_master i2c(.clk (clk),  .addr(i2c_addr), .data(flat_i2c_data), .reset (reset), .packets(packets), .rw(rw), .start(i2c_start), .ready(i2c_ready));

    always@(posedge clk) begin
        case(state)
            STATE_START: begin
                if(i2c_ready) begin
                    state <= STATE_CONF_1;
                    flat_i2c_data <= 32'h3001;
                    packets <= 2;
                    rw <= 0;
                end
            end
            STATE_CONF_1: begin
                i2c_start <= 1;
                if(i2c_ready == 0) state = STATE_WAIT_1;
            end
            STATE_WAIT_1: begin
                i2c_start <= 0;
                flat_i2c_data <= 32'h3008;
                if(i2c_ready) state <= STATE_CONF_2;
            end
            STATE_CONF_2: begin
                i2c_start <= 1;
                if(i2c_ready == 0) state = STATE_WAIT_2;
            end
            STATE_WAIT_2: begin
                i2c_start <= 0;
                flat_i2c_data <= 32'h0690;
                if(i2c_ready) state <= STATE_CONF_3;
            end
            STATE_CONF_3: begin
                i2c_start <= 1;
                if(i2c_ready == 0) state = STATE_WAIT_3;
            end
            STATE_WAIT_3: begin
                i2c_start <= 0;
                if(i2c_ready) state <= STATE_STOP;
            end
            STATE_STOP: begin
                state <= STATE_STOP;
            end
        endcase

    end
endmodule
