`default_nettype none
module test;

  /* Make a reset that pulses once. */
  reg reset = 1;
  reg [10:0] x;
  reg [10:0] y;
  integer i;
  integer j;
  initial begin

     $dumpfile("test.vcd");
     $dumpvars(0,test);
     # 2 reset = 0;
     y <= 500;

         for (i=0; i < 1000; i=i+100) begin
            # 1;
            x <= i;
         end

     x <= 500;
     for (j=0; j < 1000; j=j+100) begin
         # 1;
         y <= j;
     end

     $finish;
  end

  /* Make a regular pulsing clock. */
  reg clk = 0;
  always #1 clk = !clk;

  xy_leds leds(.x(x), .y(y));

endmodule // test


