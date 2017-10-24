module test;

  reg clk = 0;
  reg reset = 1;
  reg in = 0;


  /* Make a reset that pulses once. */
  initial begin
     $dumpfile("test.vcd");
     $dumpvars(0, test);
     # 1 reset <= 0;
     # 5 in <= 1;
     # 5 in <= 0;
     # 6;
     # 5 in <= 0;
     # 5 in <= 1;
     # 5;
     $finish;
  end

  pulse pulse_test(.reset(reset), .clk(clk), .in(in));

  /* Make a regular pulsing clock. */
  always #1 clk = !clk;

endmodule // test
