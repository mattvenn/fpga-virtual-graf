`default_nettype none
module test;

  /* Make a reset that pulses once. */
  reg reset = 1;
  wire[8:0] pos;

  initial begin

     $dumpfile("test.vcd");
     $dumpvars(0,test);
     # 2 reset = 0;
     # 400;
     $finish;
  end

  /* Make a regular pulsing clock. */
  reg clk = 0;
  always #1 clk = !clk;


  camera cam(.clk (clk), .pos(pos), .reset (reset)); 

endmodule // test

