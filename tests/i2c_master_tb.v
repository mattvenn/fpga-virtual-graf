`default_nettype none
module test;

  /* Make a reset that pulses once. */
  reg reset = 1;
  reg start = 0;
  reg [4:0] packets = 2;
  reg rw = 0; // write
  reg [7:0] data = 8'hA0;
  reg [6:0] i2c_addr = 7'h21;
  wire data_req;

  wire i2c_ready;
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
     # 4 start = 1;
     # 8 start = 0;
     wait (data_req == 1);
     data <= 8'hF0;
     wait (data_req == 1);
     data <= 8'h0F;
     wait (i2c_ready == 1);

     rw <= 1;
     packets <= 4;
     # 4 start = 1;
     # 8 start = 0;
     wait (i2c_ready == 1);
     # 20

     $finish;
  end

  /* Make a regular pulsing clock. */
  reg clk = 0;
  always #1 clk = !clk;


  i2c_master i2c(.clk (clk),  .addr(i2c_addr), .data(data), .reset (reset), .packets(packets), .rw(rw), .start(start), .ready(i2c_ready), .data_req(data_req));

endmodule // test

