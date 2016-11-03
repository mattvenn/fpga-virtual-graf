`default_nettype none
module test;

  /* Make a reset that pulses once. */
  reg reset = 1;
  reg start = 0;
  reg [2:0] packets = 3;
  reg [7:0] i2c_data[0:2];
  //reg [3*8-1:0] flat_i2c_data;
  reg [3*8-1:0] flat_i2c_data = 48'hABCDEF;
  integer i;
  initial begin
     /*
     $readmemh("i2cdata.txt", i2c_data);
     for (i=0; i < 3; i=i+1) begin
        $display("%d:%h",i,i2c_data[i]);
        flat_i2c_data[i*8 +: 8] = i2c_data[i];
     end
     */

     $dumpfile("test.vcd");
     $dumpvars(0,test);
     # 2 reset = 0;
     # 2 start = 1;
     # 200;
     $finish;
  end

  /* Make a regular pulsing clock. */
  reg clk = 0;
  always #1 clk = !clk;


  i2c_init i2c(.clk (clk),  .reset (reset), .start(start), .packets(packets), .flat_i2c_data(flat_i2c_data));

endmodule // test
