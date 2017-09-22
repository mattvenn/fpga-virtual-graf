`default_nettype none
module test;

  /* Make a reset that pulses once. */
  initial begin

     $dumpfile("test.vcd");
     $dumpvars(0,test);
     # 2000;
     $finish;
  end

  /* Make a regular pulsing clock. */
  reg clk = 0;
  wire clk_out;
  always #1 clk = !clk;

  divM #(.M(500)) clockdiv(.clk_in(clk), .clk_out(clk_out));

endmodule // test


