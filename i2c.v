`default_nettype none
module top (
	input  clk,
	output LED1,
	output LED2,
	output LED3,
	output LED4,
	output LED5,
    output pixartclk,
    inout i2c_sda,
    output i2c_scl,
    output cam_reset,
    input button,
    output PIO0_02,
    output PIO0_03,
    output PIO0_04,
    output PIO0_05,
    output PIO0_06,
    output PIO0_07,
    output PIO0_08,
    output PIO0_09
);
    
    reg slow_clk;
    reg i2c_start = 0;
    wire debounced;
    reg deb1;
	reg [8:0] counter = 0;

    reg[10:0] x;
    reg[10:0] y;

    assign PIO0_02 = x[9];
    assign PIO0_03 = slow_clk;
    assign PIO0_04 = x[7];
    assign PIO0_05 = x[6];
    assign PIO0_06 = x[5];
    assign PIO0_07 = x[4];
    assign PIO0_08 = x[3];
    assign PIO0_09 = x[2];

    wire reset = 0;

    debounce db1(.clk (slow_clk), .button (button), .debounced (debounced));

    camera cam(.clk (slow_clk), .reset (reset), .i2c_scl(i2c_scl), .i2c_sda(i2c_sda), .start(i2c_start), .cam_reset(cam_reset), .x(x), .y(y) ); 

   xy_leds leds(.x(x), .y(y), .LED1(LED1), .LED2(LED2),.LED3(LED3),.LED4(LED4),.LED5(LED5));
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

//    assign LED1 = debounced;
//    assign LED3 = i2c_start;

  // make a pulse from the button to trigger the i2c comms
  // think there are issues with the clock freqs, slw clock is much slower so can miss a pulse
  always@(posedge slow_clk) begin
      deb1 <= debounced;
      if(debounced & ~ deb1)
        i2c_start <= 1;
      else
        i2c_start <= 0;
  end
    
    // generate the slow clock for the i2c bus & button debounce
	always@(posedge clk) begin
		counter <= counter + 1;
        if(counter > 60) begin
            slow_clk <= ~ slow_clk;
            counter <= 0;
        end
	end

endmodule
