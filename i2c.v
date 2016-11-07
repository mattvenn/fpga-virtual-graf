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
    input button
);
    
    reg slow_clk;
    wire debounced;
    reg deb1;
	reg [8:0] counter = 0;

    reg [2*8-1:0] flat_i2c_data = 32'h3001;
    reg [6:0] i2c_addr = 7'h58;
    reg [2:0] packets = 2;
    wire reset = 0;
    reg i2c_start = 0;
    wire i2c_ready;
    wire rw = 0;

    debounce db1(.clk (slow_clk), .button (button), .debounced (debounced));

    i2c_master i2c(.clk (slow_clk),  .addr(i2c_addr), .data(flat_i2c_data), .reset (reset), .packets(packets), .rw(rw), .start(i2c_start), .ready(i2c_ready), .i2c_sda(i2c_sda), .i2c_scl(i2c_scl));

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

    assign LED1 = debounced;
    assign LED2 = i2c_ready;
    assign LED3 = i2c_start;

  // make a pulse from the button to trigger the i2c comms
  always@(posedge clk) begin
      deb1 <= debounced;
      if(debounced & ~ deb1 & i2c_ready)
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
