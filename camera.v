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
//    output reg[10:0] x,
//    output reg[10:0] y,
    output reg[7:0] debug
);
    reg [8*6-1:0] config_data = 48'h300130083333; // 3 pairs of 2 config bytes
    reg [3:0] config_byte = 5;
    reg [4:0] packets;
    reg [8:0] state = STATE_START;
    reg i2c_start = 0;
    wire i2c_ready;
    reg [7:0] i2c_data;
    reg rw = 1; // read
    reg [6:0] i2c_addr = 7'h58;
    reg [4:0] data_reads = 0;
    wire data_ready;
    wire data_req;
    reg [6:0] delay_count = 0;
    wire [7:0] pos_data;
    reg[7:0] s;

    localparam STATE_START = 0;
    localparam STATE_CONF = 1;
    localparam STATE_CONF_WAIT = 3;
    localparam STATE_CONF_DELAY = 4;
    localparam STATE_WAIT_3 = 6;
    localparam STATE_REQ_DATA = 7;
    localparam STATE_REQ_WAIT = 8;
    localparam STATE_READ = 9;
    localparam STATE_READ_WAIT = 10;
    localparam STATE_STOP = 11;
    localparam STATE_DELAY = 12;
    localparam STATE_DATA_READY = 13;
    localparam STATE_PROCESS_DATA = 14;

    i2c_master i2c(.clk (clk),  .addr(i2c_addr), .data(i2c_data), .reset (reset), .rw(rw), .start(i2c_start), .ready(i2c_ready), .i2c_sda(i2c_sda), .i2c_sda_in(i2c_sda_in), .i2c_scl(i2c_scl), .data_out(pos_data), .packets(packets), .data_ready(data_ready), .data_req(data_req));

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
                    if(config_byte == 15) state <= STATE_WAIT_3;
                end
            end
            STATE_WAIT_3: begin
                i2c_start <= 0;
                // request data 
                i2c_data <= 8'h36;
                packets <= 1;
                rw <= 0;
                delay_count <= 0;
                if(i2c_ready) state <= STATE_PROCESS_DATA;
            end
            STATE_PROCESS_DATA: begin
                // update the camera position
                s <= pos_data[13*8:12*8];
                state <= STATE_DATA_READY;
            end
            STATE_DATA_READY: begin
                //x <= pos_data[15*8:14*8]  + (s & 8'h30) <<4;
                //y <= pos_data[14*8:13*8]  + (s & 8'hC0) <<2;
                state <= STATE_DELAY;
            end
            STATE_DELAY: begin
                delay_count <= delay_count + 1;
                if(delay_count > 100) state <= STATE_REQ_DATA;
            end
            STATE_REQ_DATA: begin
                i2c_start <= 1;
                if(i2c_ready == 0) state <= STATE_REQ_WAIT;
            end
            STATE_REQ_WAIT: begin
                // read the data
                i2c_start <= 0;
                //i2c_data <= 0;
                packets <= 16;
                rw <= 1;
                if(i2c_ready) state <= STATE_READ;
            end
            STATE_READ: begin
                i2c_start <= 1;
                if(data_ready)
                    debug <= pos_data;
                    
                if(i2c_ready) state <= STATE_READ_WAIT;
            end
            STATE_READ_WAIT: begin
                
                state <= STATE_WAIT_3;
                i2c_start <= 0;
            end
            STATE_STOP: begin
                i2c_start <= 0;
                if(i2c_ready) state <= STATE_START;
            end
        endcase

    end
endmodule
