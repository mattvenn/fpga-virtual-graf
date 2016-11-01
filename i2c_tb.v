module test;

  /* Make a reset that pulses once. */
  reg reset = 1;
  reg start = 0;
  initial begin
     $dumpfile("test.vcd");
     $dumpvars(0,test);
     # 3 reset = 0;
     # 1 i2c_data = 8'hBB;
     wait (i2c_ready == 1);
     # 2 start = 1;
     wait (i2c_ready == 0);
     # 1 start = 0;

     wait (i2c_ready == 1);
     # 1 i2c_data = 8'hAB;
     # 1 start = 1;
     wait (i2c_ready == 0);
     # 1 start = 0;
     wait (i2c_ready == 1);
     $finish;
  end

  /* Make a regular pulsing clock. */
  reg clk = 0;
  always #1 clk = !clk;

  reg  [6:0]i2c_addr = 7'h20;
  reg  [7:0]i2c_data;
  wire i2c_sda;
  wire i2c_scl;
  wire i2c_ready;

  i2c_master i2c(.clk (clk),  .addr(i2c_addr), .data(i2c_data), .reset (reset), .i2c_sda (i2c_sda), .i2c_scl (i2c_scl), .ready(i2c_ready), .start(start));

/*  initial
     $monitor("At time %t, value = %h (%0d)",
              $time, value, value);
              */
endmodule // test
