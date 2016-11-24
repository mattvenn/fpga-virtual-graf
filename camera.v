/* probably needs to use a loop in the state to deal with all the config (6 paris of bytes)
*/
`default_nettype none
module camera(
    input wire clk,
    input wire reset,
    input wire start,
    output wire i2c_sda,
    output wire i2c_scl,
    output reg [8:0] pos,
    output reg cam_reset 
);
    reg [8:0] state = STATE_START;
    reg i2c_start = 0;
    reg [4:0] packets;
    wire i2c_ready;
    reg [16*8-1:0] flat_i2c_data;
    reg rw = 1; // read
    reg [6:0] i2c_addr = 7'h58;
    reg [4:0] data_reads = 0;
    reg [6:0] delay_count = 0;

    localparam STATE_START = 0;
    localparam STATE_CONF_1 = 1;
    localparam STATE_WAIT_1 = 2;
    localparam STATE_CONF_2 = 3;
    localparam STATE_WAIT_2 = 4;
    localparam STATE_CONF_3 = 5;
    localparam STATE_WAIT_3 = 6;
    localparam STATE_REQ_DATA = 7;
    localparam STATE_REQ_WAIT = 8;
    localparam STATE_READ = 9;
    localparam STATE_READ_WAIT = 10;
    localparam STATE_STOP = 11;
    localparam STATE_DELAY = 12;

    i2c_master i2c(.clk (clk),  .addr(i2c_addr), .data(flat_i2c_data), .reset (reset), .packets(packets), .rw(rw), .start(i2c_start), .ready(i2c_ready), .i2c_sda(i2c_sda), .i2c_scl(i2c_scl));

    always@(posedge clk) begin
        case(state)
            STATE_START: begin
                if(i2c_ready && start) begin
                    cam_reset <= 0;
                    state <= STATE_CONF_1;
                    //state <= STATE_CONF_1;
                    flat_i2c_data <= 32'h3001;
                    packets <= 2;
                    rw <= 0;
                    data_reads <= 0;
                end
            end
            STATE_CONF_1: begin
                cam_reset <= 1;
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
                flat_i2c_data <= 32'h3333;
                if(i2c_ready) state <= STATE_CONF_3;
            end
            STATE_CONF_3: begin
                i2c_start <= 1;
                if(i2c_ready == 0) state = STATE_WAIT_3;
            end
            STATE_WAIT_3: begin
                i2c_start <= 0;
                // ask for data 
                flat_i2c_data <= 16'h36;
                packets <= 1;
                rw <= 0;
                delay_count <= 0;
                if(i2c_ready) state <= STATE_DELAY;
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
                flat_i2c_data <= 0;
                packets <= 16;
                rw <= 1;
                if(i2c_ready) state <= STATE_READ;
            end
            STATE_READ: begin
                i2c_start <= 1;
                data_reads <= data_reads + 1;
                if(i2c_ready) state <= STATE_READ_WAIT;
            end
            STATE_READ_WAIT: begin
                //if(data_reads >= 2) state <= STATE_STOP;
                //else state <= STATE_WAIT_3;
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
