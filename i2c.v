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
    output i2c_debug,
    output edge_out,
    input button,
);
    
    reg i2c_clk = 0;

    i2c_master i2c(.clk (button_clk), .reset (edge_out), .i2c_sda (i2c_sda), .i2c_scl (i2c_scl), .out(outcount));
    debounce db1(.clk (button_clk), .button (button), .debounced (edge_out));

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

    reg reset;
    reg firstreset = 0;

    initial begin
        reset = 1;
    end

	reg [8:0] counter = 0;
    reg [4:0] outcount;
	assign {LED1, LED2, LED3, LED4, LED5} = outcount;

	always@(posedge clk) begin
        reset <= 0;
		counter <= counter + 1;
        if(counter == 0)
            button_clk <= ~ button_clk;
	end
/*
        if(outcnt == 1) begin
            if(reset == 0 && firstreset == 0) begin
                reset = 1;
                firstreset = 1;
                end
            else
                reset = 0;
        end
	end
*/

endmodule

module i2c_master(
    input wire clk,
    input wire reset,
    output reg i2c_sda,
    output wire i2c_scl,
    output reg [4:0] out,
);
    localparam STATE_IDLE = 0; // no clock
    localparam STATE_START = 1;// no clock
    localparam STATE_ADDR = 2;
    localparam STATE_RW = 3;
    localparam STATE_WACK = 4;
    localparam STATE_DATA = 5;
    localparam STATE_WACK2 = 6;
    localparam STATE_STOP = 7; // no clock

    reg [8:0] state;
    reg [6:0] addr;
    reg [7:0] count;
    reg [7:0] data;
    reg i2c_scl_enable = 0;

    initial begin
        state = STATE_IDLE;
    end

    assign out = state;

    assign i2c_scl = (i2c_scl_enable == 0) ? 1 : ~clk;
    
    always@(negedge clk) begin
        if( reset == 1 ) begin
            i2c_scl_enable <= 0;
        end else begin
            if ((state == STATE_IDLE) || (state == STATE_START) || (state == STATE_STOP)) begin
                i2c_scl_enable <= 0;;
            end
            else begin
                i2c_scl_enable <= 1;
            end
        end
    end

	always@(posedge clk) begin
        if( reset == 1 ) begin
            data <= data + 1;
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
                    // need to read this data
                    i2c_sda <= 0;
                    count <= 7;
                end
                STATE_DATA: begin
                    i2c_sda <= data[count];
                    if(count == 0) state <= STATE_WACK2;
                    else count <= count - 1;
                end
                STATE_WACK2: begin
                    // need to read this data
                    i2c_sda <= 0;
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
