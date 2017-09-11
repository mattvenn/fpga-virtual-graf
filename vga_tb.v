module test;

  reg clk = 0;
  wire hsync;
  wire vsync;
  reg pixel = 0;
  reg reset = 1;

  /* Make a reset that pulses once. */
  initial begin
     $dumpfile("test.vcd");
     $dumpvars(0, test);
     # 1 reset <= 0;
     # 1000000 pixel <= 1;
     # 1000000;
     $finish;
  end

  vga vga_test(.clk(clk), .reset(reset), .hsync(hsync), .vsync(vsync), .pixel(pixel));

  /* Make a regular pulsing clock. */
  always #1 clk = !clk;

endmodule // test
