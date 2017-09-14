`timescale 10 ns / 1 ns
module test;

  reg clk = 0;
  reg reset = 0;

  reg [7:0] x0 = 0;
  reg [7:0] y0 = 0;

  reg [7:0] x1 = 50;
  reg [7:0] y1 = 50;

  wire done;
  reg start = 0;

  initial begin
     $dumpfile("test.vcd");
     $dumpvars(0,test);
     $dumpon;
     # 1 reset = 1;
     # 2 reset = 0;
     # 1 start <= 1;
     # 1 start <= 0;
     # 1
     wait(done == 1);
     # 5
     $finish;
  end

  bresenham line (.clk(clk), .reset(reset), .x0(x0), .y0(y0), .x1(x1), .y1(y1), .done(done), .start(start));

  always #1 clk = !clk;

endmodule
