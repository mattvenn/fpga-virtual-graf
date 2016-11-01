`default_nettype none
module test;

  /* Make a reset that pulses once. */
  reg reset = 1;
  reg start = 0;
  initial begin
     $dumpfile("test.vcd");
     $dumpvars(0,test);
     # 2 reset = 0;

     # 2 start = 1;
     # 50
     # 2 start = 0;
     # 50;
     # 2 start = 1;
     # 50;
     # 2 start = 0;
     # 100;
     $finish;
  end

  /* Make a regular pulsing clock. */
  reg clk = 0;
  always #1 clk = !clk;


  i2c_init i2c(.clk (clk),  .reset (reset), .start(start));

endmodule // test
