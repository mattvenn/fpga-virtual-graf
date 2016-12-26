/* probably needs to use a loop in the state to deal with all the config (6 paris of bytes)
*/
`default_nettype none
module camera(
    input wire clk,
    input wire reset,
    input wire start,
    output wire i2c_sda,
    input wire i2c_sda_in,
    output wire i2c_scl,
    output reg[9:0] x,
    output reg[9:0] y,
    output reg[7:0] debug
);
    reg [8*6-1:0] config_data = 48'h300130083333; // 3 pairs of 2 config bytes
    reg [3:0] config_byte = 5;
    reg [4:0] data_byte = 0;
    reg [4:0] packets;
    reg [8:0] state = STATE_START;
    reg i2c_start = 0;
    wire i2c_ready;
    reg [7:0] i2c_data;
    wire [7:0] i2c_data_in;
    reg rw = 1; // read
    reg [6:0] i2c_addr = 7'h58;
    wire data_ready;
    wire data_req;
    reg [6:0] delay_count = 0;
    reg [16*8-1:0] pos_data;
    reg[9:0] s;

    localparam STATE_START = 0;
    localparam STATE_CONF = 1;
    localparam STATE_CONF_WAIT = 2;
    localparam STATE_CONF_DELAY = 3;
    localparam STATE_REQ_DATA_1 = 4;
    localparam STATE_REQ_DATA_2 = 5;
    localparam STATE_REQ_DATA_3 = 6;
    localparam STATE_REQ_DATA_4 = 7;
    localparam STATE_REQ_DATA_5 = 8;
    localparam STATE_PROCESS_DATA_1 = 9;
    localparam STATE_PROCESS_DATA_2 = 10;
    localparam STATE_WAIT = 11;

    i2c_master i2c(.clk (clk),  .addr(i2c_addr), .data(i2c_data), .reset (reset), .rw(rw), .start(i2c_start), .ready(i2c_ready), .i2c_sda(i2c_sda), .i2c_sda_in(i2c_sda_in), .i2c_scl(i2c_scl), .data_out(i2c_data_in), .packets(packets), .data_ready(data_ready), .data_req(data_req));

    always@(posedge clk) begin
        case(state)
            STATE_START: begin
                if(i2c_ready && start) begin
                    state <= STATE_CONF;
                    packets <= 2;
                    rw <= 0;
                end
            end
            STATE_CONF: begin
                i2c_start <= 1;
                if(i2c_ready == 0) begin
                    state = STATE_CONF_WAIT;
                end
            end
            STATE_CONF_WAIT: begin
                i2c_start <= 0;
                if(data_req) begin
                    config_byte <= config_byte - 1;
                    i2c_data <= config_data[(config_byte+1)*8-1 -: 8];
                end 
                if(i2c_ready) state <= STATE_CONF_DELAY;
                delay_count <= 0;
            end
            STATE_CONF_DELAY: begin
                delay_count <= delay_count + 1;
                if(delay_count > 100) begin
                    state <= STATE_CONF;
                    if(config_byte == 15) state <= STATE_REQ_DATA_1;
                end
            end
            STATE_REQ_DATA_1: begin
                i2c_start <= 1;
                // request data 
                i2c_data <= 8'h36;
                packets <= 1;
                rw <= 0;
                delay_count <= 0;
                state <= STATE_REQ_DATA_2;
            end
            STATE_REQ_DATA_2: begin
                i2c_start <= 0;
                if(i2c_start == 0 && i2c_ready)
                    state <= STATE_REQ_DATA_3;
            end
            STATE_REQ_DATA_3: begin
                packets <= 16;
                rw <= 1;
                i2c_start <= 1;
                data_byte = 15;
                state <= STATE_REQ_DATA_4;
            end
            STATE_REQ_DATA_4: begin
                i2c_start <= 0;
                if(i2c_ready) state <= STATE_REQ_DATA_5;
            end
            STATE_REQ_DATA_5: begin
                if(data_ready) begin
                    pos_data[(data_byte+1)*8-1 -: 8] <= i2c_data_in;
                    data_byte <= data_byte - 1;
                end
                if(i2c_ready) state <= STATE_PROCESS_DATA_1;
            end
            STATE_PROCESS_DATA_1: begin
                // update the camera position
                //http://wiibrew.org/wiki/Wiimote#Data_Formats
                s <= pos_data[13*8:12*8];
                state <= STATE_PROCESS_DATA_2;
            end
            STATE_PROCESS_DATA_2: begin
                x <= pos_data[15*8:14*8] + ((s & 8'b00110000) <<4); // + has precedence over <<
                y <= pos_data[14*8:13*8] + ((s & 8'b11000000) <<2);
                state <= STATE_WAIT;
                delay_count <= 0;
            end
            STATE_WAIT: begin
                delay_count <= delay_count + 1;
                if(delay_count > 100)
                    state <= STATE_REQ_DATA_1;
            end
        endcase
    end
endmodule

