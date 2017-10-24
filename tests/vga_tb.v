module test;

  reg clk = 0;
  wire hsync;
  wire vsync;
  reg [7:0] pixels = 8'b00111100;
  reg reset = 1;

  /* Make a reset that pulses once. */
  initial begin
     $dumpfile("test.vcd");
     $dumpvars(0, test);
     # 1 reset <= 0;
     wait(vga_test.vcounter == 30); // border ends after 10 pixels
     # 1000;
     $finish;
  end

  vga vga_test(.reset(reset), .pixels(pixels), .clk(clk));

  /* Make a regular pulsing clock. */
  always #1 clk = !clk;

endmodule // test
