module test;

  reg clk = 0;
  wire i2c_sda;
  wire i2c_scl;
  reg i2c_start = 0;
  reg reset = 1;
  reg button = 0;
  wire [8:0] pos;
  reg deb1 = 0;
  wire debounced;

  debounce db1(.clk (clk), .button (button), .debounced (debounced));

  camera cam(.clk (clk), .pos(pos), .reset (reset), .i2c_scl(i2c_scl), .i2c_sda(i2c_sda), .start(i2c_start)); 

  /* Make a reset that pulses once. */
  initial begin
     $dumpfile("test.vcd");
     $dumpvars(0,test);
     # 3 reset = 0;
     //wait (i2c_ready == 1);
     # 20 button = 0;
     # 21 button = 1;
     # 20 button = 0;
     # 1600;
     $finish;
  end

  always@(posedge clk) begin
      deb1 <= debounced;
      if(debounced & ~ deb1)
        i2c_start <= 1;
      else
        i2c_start <= 0;
  end

  /* Make a regular pulsing clock. */
  always #1 clk = !clk;

endmodule // test
