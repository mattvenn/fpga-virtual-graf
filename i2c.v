`default_nettype none
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
    output edge_out,
    input button,
);
    
    reg slow_clk;
    wire dbutton;
	reg [8:0] counter = 0;
    reg [4:0] outcount;
    reg [3*8-1:0] flat_i2c_data = 48'hABCDEF;
    reg [2:0] packets = 3;
    wire reset = 0;
    wire start = 1;

    debounce db1(.clk (slow_clk), .button (button), .debounced (dbutton));
    i2c_init i2c(.clk (slow_clk),  .reset (reset), .start(dbutton), .i2c_sda(i2c_sda), .i2c_scl(i2c_scl), .packets(packets), .flat_i2c_data(flat_i2c_data));

/*
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
    */

//	assign {LED1, LED2, LED3, LED4, LED5} = outcount; //state;
/*
    assign LED2 = dbutton;
    assign LED3 = i2c_ready;
    assign LED4 = reset;
    */
    assign edge_out = dbutton;
    assign LED1 = start;


	always@(posedge clk) begin
		counter <= counter + 1;
        if(counter > 60) begin
            slow_clk <= ~ slow_clk;
            counter <= 0;
        end
	end

endmodule


