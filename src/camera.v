/* probably needs to use a loop in the state to deal with all the config (6 paris of bytes)

camera is 1024 x 768

* details on camera data format: http://wiibrew.org/wiki/Wiimote#Data_Formats
* http://procrastineering.blogspot.com.es/2008/09/working-with-pixart-camera-directly.html

*/
`default_nettype none
module camera(
    input wire clk,
    input wire clk_en,
    input wire reset,
    output wire i2c_sda,
    input wire i2c_sda_in,
    output wire i2c_sda_dir,
    output wire i2c_scl,
    output reg[9:0] x,
    output reg[9:0] y
);
    localparam [8*6-1:0] config_data = 48'h300130083333; // 3 pairs of 2 config bytes
    reg [3:0] config_byte = 5;
    reg [2:0] data_byte = 0;
    reg [4:0] packets;
    reg [3:0] state = STATE_START;
    reg i2c_start = 0;
    wire i2c_ready;
    reg [7:0] i2c_data;
    wire [7:0] i2c_data_in;
    reg rw = 1; // read
    localparam i2c_addr = 7'h58;
    wire data_ready;
    wire data_req;
    reg [7:0] delay_count = 0;
    // array makes synthesis much more efficient
    reg [7:0] pos_data [3:0]; // only need first 3 bytes

    localparam STATE_START = 0;
    localparam STATE_START_WAIT = 11;
    localparam STATE_CONF = 1;
    localparam STATE_CONF_WAIT = 2;
    localparam STATE_CONF_DELAY = 3;
    localparam STATE_REQ_DATA_1 = 4;
    localparam STATE_REQ_DATA_2 = 5;
    localparam STATE_REQ_DATA_3 = 6;
    localparam STATE_REQ_DATA_4 = 7;
    localparam STATE_REQ_DATA_5 = 8;
    localparam STATE_PROCESS_DATA = 9;
    localparam STATE_WAIT = 10;

    i2c_master i2c(.clk_en(clk_en), .i2c_sda_dir(i2c_sda_dir), .clk (clk),  .addr(i2c_addr), .data(i2c_data), .reset (reset), .rw(rw), .start(i2c_start), .ready(i2c_ready), .i2c_sda(i2c_sda), .i2c_sda_in(i2c_sda_in), .i2c_scl(i2c_scl), .data_out(i2c_data_in), .packets(packets), .data_ready(data_ready), .data_req(data_req));

    always@(posedge clk) begin
        if( reset == 1 ) begin
            state <= STATE_START;
        end
        else if ( clk_en )begin
        case(state)
            STATE_START: begin
                if(i2c_ready) begin
                    state <= STATE_START_WAIT;
                    packets <= 2;
                    rw <= 0;
                    delay_count <= 0;
                end
            end
            STATE_START_WAIT: begin
                delay_count <= delay_count + 1;
                if(delay_count > 200)
                    state <= STATE_CONF;
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
                data_byte = 0;
                state <= STATE_REQ_DATA_4;
            end
            STATE_REQ_DATA_4: begin
                i2c_start <= 0;
                if(i2c_ready) state <= STATE_REQ_DATA_5;
            end
            STATE_REQ_DATA_5: begin
                if(data_ready) begin
                    if(data_byte <= 3) begin
                        pos_data[data_byte+1] <= i2c_data_in;
                        data_byte <= data_byte + 1;
                    end
                end
                // after data transfer complete, move on to process data
                if(i2c_ready) state <= STATE_PROCESS_DATA;
            end
            STATE_PROCESS_DATA: begin
                // update the camera position
                //http://wiibrew.org/wiki/Wiimote#Data_Formats
                // + has precedence over <<
                x <= pos_data[2] + ((pos_data[4] & 8'b00110000) <<4); 
                y <= pos_data[3] + ((pos_data[4] & 8'b11000000) <<2);
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
    end

endmodule

