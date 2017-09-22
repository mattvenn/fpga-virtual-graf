`default_nettype none
module test;

  /* Make a reset that pulses once. */
  reg reset = 1;
  reg [9:0] x = 0;
  reg [9:0] y = 0;

  integer i, j;

  initial begin

     $dumpfile("test.vcd");
     $dumpvars(0,test);
     # 2 reset = 0;

         for (i=0; i < 1024; i=i+1) begin
            # 2;
            x <= i;
         end
     # 2 x <= 1023;

     for (j=0; j < 768; j=j+1) begin
         # 2;
         y <= j;
     end
     y <= 767;
     # 2
     y <= 1023;
     # 2
     $finish;
  end

  /* Make a regular pulsing clock. */
  reg clk = 0;
  always #1 clk = !clk;

  map_cam mc(.clk(clk), .reset(reset), .x_in(x), .y_in(y));

endmodule // test


