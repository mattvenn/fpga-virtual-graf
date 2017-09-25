`timescale 10 ns / 1 ns
module test;

  reg clk = 0;
  reg reset = 0;

  reg [9:0] x1 = 640;
  reg [9:0] y1 = 480;

  reg [9:0] x0 = 0;
  reg [9:0] y0 = 0;

  wire done;
  reg start = 0;

  initial begin
     $dumpfile("test.vcd");
     $dumpvars(0,test);
     $dumpon;
     # 2 reset = 1;
     # 2 reset = 0;
     # 2 start <= 1;
     # 2 start <= 0;
     # 1
     wait(done == 1);
     # 5
     $finish;
  end

  bresenham line (.clk(clk), .reset(reset), .x0(x0), .y0(y0), .x1(x1), .y1(y1), .done(done), .start(start), .clk_en(1'b1));

  always #1 clk = !clk;

endmodule
