module test;

  reg clk = 0;
  reg [2*8-1:0] flat_i2c_data = 32'h3001;
  reg [6:0] i2c_addr = 7'h58;
  wire i2c_sda;
  wire i2c_scl;
  wire rw = 0;
  wire i2c_ready;
  reg [2:0] packets = 2;
  reg i2c_start = 0;
  reg reset = 1;
  reg button = 0;
  reg deb1 = 0;
  wire debounced;

    i2c_master i2c(.clk (clk),  .addr(i2c_addr), .data(flat_i2c_data), .reset (reset), .packets(packets), .rw(rw), .start(i2c_start), .ready(i2c_ready), .i2c_sda(i2c_sda), .i2c_scl(i2c_scl));

   debounce db1(.clk (clk), .button (button), .debounced (debounced));
   

  /* Make a reset that pulses once. */
  initial begin
     $dumpfile("test.vcd");
     $dumpvars(0,test);
     # 3 reset = 0;
     //wait (i2c_ready == 1);
     # 20 button = 0;
     # 20 button = 1;
     # 20 button = 0;
     # 100;
     # 20 button = 1;
     # 20 button = 0;
     # 100;
     $finish;
  end


  always@(posedge clk) begin
      deb1 <= debounced;
      if(debounced & ~ deb1 & i2c_ready)
        i2c_start <= 1;
      else
        i2c_start <= 0;
  end

  /* Make a regular pulsing clock. */
  always #1 clk = !clk;

endmodule // test
