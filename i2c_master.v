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
    output reg [7:0] data_out
);
    localparam STATE_IDLE = 0; // no clock
    localparam STATE_START = 1;// no clock
    localparam STATE_ADDR = 2;
    localparam STATE_RW = 3;
    localparam STATE_WACK_1 = 4;
    localparam STATE_DATA_READ = 5;
    localparam STATE_DATA_REQ = 9;
    localparam STATE_DATA_WRITE = 6;
    localparam STATE_WACK_2 = 7;
    localparam STATE_STOP = 8; // no clock

    reg [8:0] state;
    reg [7:0] count;
    reg i2c_sda_tri;
    reg i2c_scl_enable = 0;

    reg [6:0] saved_addr;
    reg [7:0] saved_data; // 16 bytes of data max
    reg [4:0] saved_packets;
    reg saved_rw;

    initial begin
        state = STATE_IDLE;
        data_req = 0;
    end
    assign ready = (reset == 0) && (state == STATE_STOP || state == STATE_IDLE) ? 1 : 0;
    assign i2c_scl = (i2c_scl_enable == 0) ? 1 : ~clk;
    assign i2c_sda = (i2c_sda_tri == 1) ? 'bz : 0;
    
    always@(negedge clk) begin
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

	always@(posedge clk) begin
        if( reset == 1 ) begin
            state <= STATE_IDLE;
            data_ready <= 0;
            data_req <= 0;
            i2c_sda_tri <= 'b1;
        end
        else begin
            case(state)
                STATE_IDLE: begin
                    i2c_sda_tri <= 1;
                    if (start) begin
                        saved_addr <= addr;
                        saved_rw <= rw;
                        saved_packets <= packets;
                        state <= STATE_START;
                    end
                    else state <= STATE_IDLE;
                end
                STATE_START: begin
                    i2c_sda_tri <= 0;
                    state <= STATE_ADDR;
                    count <= 6;
                end
                STATE_ADDR: begin // send saved_address 7 bits, MSB
                    // clock in the data to send
                    i2c_sda_tri <= saved_addr[count];
                    if(count == 0) state <= STATE_RW;
                    else count <= count - 1;
                end
                STATE_RW: begin
                    i2c_sda_tri <= saved_rw;
                    state <= STATE_WACK_1;
                end
                STATE_WACK_1: begin
                    // grab the first data byte
                    if(saved_rw) state <= STATE_DATA_READ;
                    else begin
                        state <= STATE_DATA_REQ;
                        data_req <= 1;
                    end    
                    // check it goes low?
                    i2c_sda_tri <= 1;
                    count <= 7;
                end
                STATE_DATA_REQ: begin
                    data_req <= 0;
                    if( data_req == 0) begin
                        saved_data <= data;
                        state <= STATE_DATA_WRITE;
                    end
                end
                STATE_DATA_WRITE: begin
                    i2c_sda_tri <= saved_data[count];
                    if(count == 0) begin
                        state <= STATE_WACK_2;
                        count <= 7;
                        saved_packets <= saved_packets - 1;
                    end
                    else count <= count - 1;
                end
                STATE_DATA_READ: begin
                    data_ready <= 0;
                    i2c_sda_tri <= 1;
                    // seems to be skipping MSB of all but 1st packets
                    // because we are clocked on pos edge, and nack is still low
                    // not sure how to solve this as the i2c clock is negative of the clock driving the state machine
                    // plus assigning to a pin seems to take a clock, but reading happens immediately.
                    saved_data[count] <= i2c_sda_in;
                    if(count == 0) begin
                        state <= STATE_WACK_2;
                        count <= 7;
                        saved_packets <= saved_packets - 1;
                    end 
                    else count <= count - 1;
                end
                STATE_WACK_2: begin
                    if(saved_rw) begin
                        // if we're reading, we have to do the ack
                        i2c_sda_tri <= 0;
                        // and put the data onto the out register
                        if(saved_rw) data_out <= saved_data;
                        // set the data ready pin
                        data_ready <= 1;
                    end

                    // otherwise the client should ack: check it goes low?
                    else begin
                        i2c_sda_tri <= 1;
                    end
                    if(saved_packets == 0) begin
                        state <= STATE_STOP;
                    end
                    else begin
                        count <= 7;
                        if(saved_rw) state <= STATE_DATA_READ;
                        else begin
                            state <= STATE_DATA_REQ;
                            data_req <= 1;
                        end
                    end
                end
                STATE_STOP: begin
                    i2c_sda_tri <= 0;
                    state <= STATE_IDLE;
                end
            endcase
        end
    end
endmodule
