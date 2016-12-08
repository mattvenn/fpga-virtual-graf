`default_nettype none
module test;

  reg reset = 0;
  wire i2c_sda;
  wire i2c_scl;
  reg start = 0;

  initial begin
     $dumpfile("test.vcd");
     $dumpvars(0,test);
     # 2 reset = 0;
     # 4 start = 1;
     # 2 start = 0;
     # 4000;
     $finish;
  end

  // clock
  reg clk = 0;
  always #1 clk = !clk;

  camera cam(.clk (clk), .reset (reset), .i2c_scl(i2c_scl), 
        .i2c_sda(i2c_sda), .start(start) ); 

endmodule // test
