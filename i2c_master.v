`default_nettype none
module i2c_master(
    input wire clk,
    input wire reset,
    input wire [6:0] addr,
    input wire [7:0] data, 
    input wire [4:0] packets,
    input wire start,
    input wire rw, // 1 for read, 0 for write
    output wire i2c_sda,
    input wire i2c_sda_in,
    output wire i2c_scl,
    output wire ready,
    output reg data_ready, // flag to say data is ready to read
    output reg data_req, // flag to request more data to write
    output reg [7:0] data_out // msb (pin 10) is index 7
);
    localparam STATE_IDLE = 0; // no clock
    localparam STATE_START = 1;// no clock
    localparam STATE_START_BIT = 12;// no clock
    localparam STATE_ADDR = 2;
    localparam STATE_ADDR_BIT = 10;
    localparam STATE_RW = 3;
    localparam STATE_RW_BIT = 11;
    localparam STATE_WACK_1 = 4;
    localparam STATE_WACK_1_BIT = 13;
    localparam STATE_DATA_READ = 5;
    localparam STATE_DATA_READ_BIT = 17;
    localparam STATE_DATA_REQ = 9;
    localparam STATE_DATA_WRITE = 6;
    localparam STATE_DATA_WRITE_BIT = 14;
    localparam STATE_WACK_2 = 7;
    localparam STATE_WACK_2_BIT = 15;
    localparam STATE_STOP = 8; // no clock
    localparam STATE_STOP_BIT_1 = 16; // no clock
    localparam STATE_STOP_BIT_2 = 18; // no clock

    reg [8:0] state;
    reg [7:0] count;
    reg i2c_sda_tri;
    reg i2c_scl_enable = 0;

    reg [6:0] saved_addr;
    reg [7:0] saved_data; // 16 bytes of data max
    reg [4:0] saved_packets;
    reg saved_rw;
    reg i2c_scl_reg;

    initial begin
        state = STATE_IDLE;
        data_req = 0;
        i2c_sda_tri <= 1;
        i2c_scl_reg <= 1;
    end
    assign ready = (reset == 0) && (state == STATE_IDLE) ? 1 : 0;
//    assign i2c_scl = (i2c_scl_enable == 0) ? 1 : ~clk;
    assign i2c_sda = (i2c_sda_tri == 1) ? 'bz : 0;
    assign i2c_scl = i2c_scl_reg;
    
/*    always@(negedge clk) begin
        if( reset == 1 ) begin
            i2c_scl_enable <= 0;
        end else begin
            if ((state == STATE_IDLE) || (state == STATE_START) || (state == STATE_DATA_REQ))  begin
                i2c_scl_enable <= 0;
            end
            else begin
                i2c_scl_enable <= 1;
            end
        end
    end
    */

	always@(posedge clk) begin
        if( reset == 1 ) begin
            state <= STATE_IDLE;
            data_ready <= 0;
            data_req <= 0;
            i2c_sda_tri <= 1;
            i2c_scl_reg <= 1;
        end
        else begin
            case(state)
                STATE_IDLE: begin
                    i2c_sda_tri <= 1;
                    i2c_scl_reg <= 1;
                    if (start) begin
                        saved_addr <= addr;
                        saved_rw <= rw;
                        saved_packets <= packets;
                        state <= STATE_START;
                    end
                    else state <= STATE_IDLE;
                end
                // start condition is sda going low while scl is high
                STATE_START: begin
                    i2c_sda_tri <= 0;
                    state <= STATE_START_BIT;
                    count <= 6;
                end
                STATE_START_BIT: begin
                    i2c_scl_reg <= 0;
                    state <= STATE_ADDR;
                end
                STATE_ADDR: begin // send saved_address 7 bits, MSB
                    // clock in the data to send
                    i2c_scl_reg <= 0;
                    i2c_sda_tri <= saved_addr[count];
                    state <= STATE_ADDR_BIT;
                end
                STATE_ADDR_BIT: begin
                    i2c_scl_reg <= 1;
                    count <= count - 1;
                    if(count == 0) state <= STATE_RW;
                    else state <= STATE_ADDR;
                end
                STATE_RW: begin
                    i2c_scl_reg <= 0;
                    i2c_sda_tri <= saved_rw;
                    state <= STATE_RW_BIT;
                end
                STATE_RW_BIT: begin
                    i2c_scl_reg <= 1;
                    state <= STATE_WACK_1;
                end
                STATE_WACK_1: begin
                    i2c_sda_tri <= 1; // allow slave to ack
                    i2c_scl_reg <= 0;
                    state <= STATE_WACK_1_BIT;
                    data_req <= 1;
                end
                STATE_WACK_1_BIT: begin
                    i2c_scl_reg <= 1;
                    count <= 7;
                    if(saved_rw) begin
                        state <= STATE_DATA_READ;
                    end
                    else begin
                        saved_data <= data;
                        data_req <= 0;
                        if(data_req == 0)
                            state <= STATE_DATA_WRITE;
                    end    
                end
                STATE_DATA_WRITE: begin
                    i2c_scl_reg <= 0;
                    i2c_sda_tri <= saved_data[count];
                    state <= STATE_DATA_WRITE_BIT;
                end
                STATE_DATA_WRITE_BIT: begin
                    i2c_scl_reg <= 1;
                    if(count == 0) begin
                        state <= STATE_WACK_2;
                        saved_packets <= saved_packets - 1;
                    end
                    else state <= STATE_DATA_WRITE;
                    count <= count - 1;
                end
                STATE_DATA_READ: begin
                    i2c_sda_tri <= 1;
                    i2c_scl_reg <= 0;
                    state <= STATE_DATA_READ_BIT;
                end
                STATE_DATA_READ_BIT: begin
                    saved_data[count] <= i2c_sda_in;
                    i2c_scl_reg <= 1;
                    if(count == 0) begin
                        state <= STATE_WACK_2;
                        saved_packets <= saved_packets - 1;
                    end 
                    else state <= STATE_DATA_READ;
                    count <= count - 1;
                end
                STATE_WACK_2: begin
                    i2c_scl_reg <= 0;
                    if(saved_rw) begin // read
                        // if we're reading, we have to do the ack
                        i2c_sda_tri <= 0;
                        // set the data ready pin
                        data_ready <= 1;
                        data_out <= saved_data;
                    end else begin // write
                        // allow slave to do ack
                        if(saved_packets > 0) 
                            data_req <= 1;
                        i2c_sda_tri <= 1;
                    end
                    state <= STATE_WACK_2_BIT;
                end
                STATE_WACK_2_BIT: begin
                    i2c_scl_reg <= 1;
                    count <= 7;
                    data_ready <= 0;
                    data_req <= 0;

                    if(saved_packets == 0) begin
                        state <= STATE_STOP;
                    end
                    else begin
                        if(saved_rw) begin
                            state <= STATE_DATA_READ;
                        end else begin
                            saved_data <= data;
                            if(data_req == 0)
                                state <= STATE_DATA_WRITE;
                        end
                    end
                end
                // stop is sda low to high while clock is high
                STATE_STOP: begin
                    i2c_scl_reg <= 0;
                    i2c_sda_tri <= 0;
                    state <= STATE_STOP_BIT_1;
                end
                STATE_STOP_BIT_1: begin
                    i2c_scl_reg <= 1;
                    state <= STATE_STOP_BIT_2;
                end
                STATE_STOP_BIT_2: begin
                    i2c_sda_tri <= 1;
                    state <= STATE_IDLE;
                end
            endcase
        end
    end
endmodule
