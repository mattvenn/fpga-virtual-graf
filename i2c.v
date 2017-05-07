`default_nettype none
module top (
	input  clk,
	output [0:3] LED,
    output pixartclk,
    output pixart_reset,
    output i2c_sda,
    input i2c_sda_in,
    output i2c_scl,
    input button,
    output [31:0] PMOD
);
    
    reg cam_clk;
    reg i2c_start = 1;
    wire debounced;
    reg deb1;
	reg [8:0] counter = 0;

    reg[9:0] x;
    reg[9:0] y;

    wire reset = 0;
    assign pixart_reset = 1;

    clk_divn #(.WIDTH(16), .N(500)) clockdiv_cam(.clk(clk), .clk_out(cam_clk));
    camera cam(.clk (cam_clk), .reset (reset), .i2c_scl(i2c_scl), .i2c_sda_in(i2c_sda_in), .i2c_sda(i2c_sda), .start(i2c_start), .x(x), .y(y)); //, .debug(PIO0)); 

   xy_leds leds(.x(x), .y(y), .LED1(LED[0]), .LED2(LED[1]),.LED3(LED[2]),.LED4(LED[3]));

    //PLL details http://www.latticesemi.com/view_document?document_id=47778
    SB_PLL40_CORE #(
        .FEEDBACK_PATH("SIMPLE"),
        .PLLOUT_SELECT("GENCLK"),
        .DIVR(4'b1001),
        .DIVF(7'b1100100),
        .DIVQ(3'b011),
        .FILTER_RANGE(3'b001)
    ) uut (
//        .LOCK(lock),
        .RESETB(1'b1),
        .BYPASS(1'b0),
        .REFERENCECLK(clk),
        .PLLOUTCORE(clkx5)
    );

  wire clkx5;
  wire hsync;
  wire vsync;
  wire blank;
  wire [2:0] red;
  wire [2:0] green;
  wire [2:0] blue;
    wire vga_clk;

    clk_divn clockdiv(.clk(clkx5), .clk_out(vga_clk));
    vga vga_test(.x(x), .y(y), .clk(vga_clk), .hsync(hsync), .vsync(vsync), .blank(blank), .red(red), .green(green), .blue(blue));

    dvid dvid_test(.clk(vga_clk), .clkx5(clkx5), .hsync(hsync), .vsync(vsync), .blank(blank), .red(red), .green(green), .blue(blue), .hdmi_p(PMOD[0:3]), .hdmi_n(PMOD[4:7]));

/*
    assign PMOD[0] = hsync;
    assign PMOD[1] = vsync;
    assign PMOD[2] = blank;
    assign PMOD[3] = vga_clk;
    assign PMOD[4] = clkx5;
    assign PMOD[5] = clk;
    assign PMOD[6] = slow_clk;
    */

endmodule
