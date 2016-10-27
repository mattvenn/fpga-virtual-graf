module top (
	input  clk,
	output LED1,
	output LED2,
	output LED3,
	output LED4,
	output LED5,
    output pixartclk,
    output i2c_sda,
    output i2c_scl,
    output i2c_debug
);


    i2c_master i2c(.clk (i2c_clk), .reset (reset), .i2c_sda (i2c_sda), .i2c_scl (i2c_scl));

    SB_PLL40_CORE #(
        .FEEDBACK_PATH("SIMPLE"),
        .PLLOUT_SELECT("GENCLK"),
        .DIVR(4'b0000),
        .DIVF(7'b1000010),
        .DIVQ(3'b101),
        .FILTER_RANGE(3'b001)
    ) uut (
        .LOCK(lock),
        .RESETB(1'b1),
        .BYPASS(1'b0),
        .REFERENCECLK(clk),
        .PLLOUTCORE(pixartclk)
    );

    reg reset = 0;
    reg firstreset = 0;
    reg i2c_clk = 0;

	localparam BITS = 5;
	localparam LOG2DELAY = 5;

	reg [BITS+LOG2DELAY-1:0] counter = 0;
	reg [BITS-1:0] outcnt;

	always@(posedge clk) begin
		counter <= counter + 1;
		outcnt <= counter >> LOG2DELAY;
        if(counter == 0) begin
            i2c_clk = ~ i2c_clk;
        end
        if(outcnt == 1) begin
            if(reset == 0 && firstreset == 0) begin
                reset = 1;
                firstreset = 1;
                end
            else
                reset = 0;
        end

	end

    assign { i2c_debug } = reset;


endmodule
module i2c_master(
    input wire clk,
    input wire reset,
    output reg i2c_sda,
    output reg i2c_scl,
);

    localparam STATE_IDLE = 0;
    localparam STATE_START = 1;
    localparam STATE_ADDR = 2;
    localparam STATE_RW = 3;
    localparam STATE_WACK = 4;
    localparam STATE_DATA = 5;
    localparam STATE_STOP = 6;
//    localparam STATE_WACK2 = 7; // if this is uncommented, it breaks the case statement

    reg [8:0] state;
    reg [6:0] addr;
    reg [7:0] count;
    reg [7:0] data;


    assign { i2c_scl } = clk;

	always@(posedge clk) begin
        if( reset == 1 ) begin
            data <= 8'hAA;
            state <= STATE_IDLE;
            i2c_sda <= 1;
    //        i2c_scl <= 1;
            addr <= 7'h40;
            count <= 8'd0;
        end
        else begin
            case(state)
                STATE_IDLE: begin
                    i2c_sda <= 1;
                    state <= STATE_START;
                end
                STATE_START: begin
                    i2c_sda <= 0;
                    state <= STATE_ADDR;
                    count <= 6;
                end
                STATE_ADDR: begin // send address 7 bits, MSB
                    i2c_sda <= addr[count];
                    if(count == 0) state <= STATE_RW;
                    else count <= count - 1;
                end
                STATE_RW: begin
                    i2c_sda <= 1;
                    state <= STATE_WACK;
                end
                STATE_WACK: begin
                    state <= STATE_DATA;
                    count <= 7;
                end
                STATE_DATA: begin
                    i2c_sda <= data[count];
                    if(count == 0) state <= STATE_STOP;
                    else count <= count - 1;
                end
                STATE_WACK2: begin
                    state <= STATE_STOP;
                end
                STATE_STOP: begin
                    i2c_sda <= 1;
//                    state <= STATE_START;
                end
            endcase
        end
    end
endmodule
