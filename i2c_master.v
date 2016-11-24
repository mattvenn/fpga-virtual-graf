`default_nettype none
module i2c_master(
    input wire clk,
    input wire reset,
    input wire [6:0] addr,
    input wire [16*8-1:0] data, // 16 bytes of data max
    input wire [4:0] packets,
    input wire start,
    input wire rw, // 1 for read, 0 for write
    output wire i2c_sda,
    output wire i2c_scl,
    output wire ready
);
    localparam STATE_IDLE = 0; // no clock
    localparam STATE_START = 1;// no clock
    localparam STATE_ADDR = 2;
    localparam STATE_RW = 3;
    localparam STATE_WACK_1 = 4;
    localparam STATE_DATA_READ = 5;
    localparam STATE_DATA_WRITE = 6;
    localparam STATE_WACK_2 = 7;
    localparam STATE_STOP = 8; // no clock

    reg [8:0] state;
    reg [7:0] count;
    reg i2c_sda_tri;
    reg i2c_scl_enable = 0;

    reg [6:0] saved_addr;
    reg [16*8-1:0] saved_data; // 16 bytes of data max
    reg [4:0] saved_packets;
    reg saved_rw;

    initial begin
        state = STATE_IDLE;
    end

    assign ready = (reset == 0) && (state == STATE_STOP || state == STATE_IDLE) ? 1 : 0;
    assign i2c_scl = (i2c_scl_enable == 0) ? 1 : ~clk;
    assign i2c_sda = (i2c_sda_tri == 1) ? 'bz : 0;
    
    always@(negedge clk) begin
        if( reset == 1 ) begin
            i2c_scl_enable <= 0;
        end else begin
            if ((state == STATE_IDLE) || (state == STATE_START))  begin
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
            i2c_sda_tri <= 'b1;
            count <= 8'd0;
        end
        else begin
            case(state)
                STATE_IDLE: begin
                    i2c_sda_tri <= 1;
                    if (start) begin
                        saved_addr <= addr;
                        saved_data <= data;
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
                    i2c_sda_tri <= saved_addr[count];
                    if(count == 0) state <= STATE_RW;
                    else count <= count - 1;
                end
                STATE_RW: begin
                    i2c_sda_tri <= saved_rw;
                    state <= STATE_WACK_1;
                end
                STATE_WACK_1: begin
                    if(saved_rw) state <= STATE_DATA_READ;
                    else state <= STATE_DATA_WRITE;
                    // check it goes low?
                    i2c_sda_tri <= 1;
                    count <= 7;
                end
                STATE_DATA_WRITE: begin
                    i2c_sda_tri <= saved_data[(saved_packets-1)*8+count];
                    if(count == 0) begin
                        state <= STATE_WACK_2;
                        count <= 7;
                        saved_packets <= saved_packets - 1;
                    end
                    else count <= count - 1;
                end
                STATE_DATA_READ: begin
                    i2c_sda_tri <= 1;
                    saved_data[(saved_packets-1)*8+count] <= i2c_sda_tri;
                    if(count == 0) begin
                        state <= STATE_WACK_2;
                        count <= 7;
                        saved_packets <= saved_packets - 1;
                    end 
                    else count <= count - 1;
                end
                STATE_WACK_2: begin
                    // if we're reading, we have to do the ack
                    if(saved_rw) i2c_sda_tri <= 0;
                    // check it goes low?
                    else i2c_sda_tri <= 1;

                    if(saved_packets == 0)
                        state <= STATE_STOP;
                    else begin
                        if(saved_rw) state <= STATE_DATA_READ;
                        else state <= STATE_DATA_WRITE;
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
