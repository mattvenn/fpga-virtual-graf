module test;

	wire LED1;
	wire LED2;
	wire LED3;
	wire LED4;
	wire LED5;

    wire PIO0_02;
    wire PIO0_03;
    wire PIO0_04;
    wire PIO0_05;
    wire PIO0_06;
    wire PIO0_07;
    wire PIO0_08;
    wire PIO0_09;

  reg clk = 0;
  wire i2c_sda;
  wire i2c_scl;
  reg i2c_start = 0;
  reg reset = 0;
  reg button = 0;
  wire [8:0] pos;
  reg deb1 = 0;
  wire debounced;

  wire[10:0] x;
  wire[10:0] y;

/*    assign PIO0_02 = x[9];
    assign PIO0_03 = x[8];
    assign PIO0_04 = x[7];
    assign PIO0_05 = x[6];
    assign PIO0_06 = x[5];
    assign PIO0_07 = x[4];
    assign PIO0_08 = x[3];
    assign PIO0_09 = x[2];
    */

  debounce db1(.clk (clk), .button (button), .debounced (debounced));

  camera cam(.clk (clk), .reset (reset), .i2c_scl(i2c_scl), .i2c_sda(i2c_sda), .start(i2c_start) ); 

   xy_leds leds(.x(x), .y(y), .LED1(LED1), .LED2(LED2),.LED3(LED3),.LED4(LED4),.LED5(LED5));

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
