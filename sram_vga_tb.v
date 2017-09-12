module test;

  reg clk = 0;
  reg vga_clk = 0;
  wire hsync;
  wire vsync;
  wire [15:0] pixel_buf;
  reg reset = 1;

    wire [17:0] address;
    wire [15:0] data_read;
    wire [15:0] data_write;
    reg [9:0] x;
    reg [9:0] y;
    reg [15:0] data_pins_in;
    wire read;
    reg erase = 0;
    wire write;
    wire ready;

    wire [10:0] hcounter;
    wire [9:0] vcounter;
    wire [3:0] pb_state;

  initial begin
     $dumpfile("test.vcd");
     $dumpvars(0, test);
     # 1 data_pins_in = 0;
     # 1 reset <= 1;
     # 8 reset <= 0;
     # 4000
     $dumpoff;

     // wait for camera write
     wait(vcounter == 479 && hcounter == 780);
     # 1 x <= 50;
     # 1 y <= 50;
     $dumpon;

     // press the erase button and skip to the end of the displayable screen
     wait(vcounter == 480 && hcounter == 780);
     # 1 erase <= 1;
     $dumpon;
     # 1000
     $finish;
  end
    

    wire [10:0] tester;
    assign tester = hcounter[3:0];
   vga vga_test(.reset(reset), .pixel_buf(pixel_buf), .clk(vga_clk), .hsync(hsync), .vsync(vsync), .blank(blank), .hcounter(hcounter), .vcounter(vcounter));

  sram sram_test(.clk(vga_clk), .address(address), .data_read(data_read), .data_write(data_write), .write(write), .read(read), .reset(reset), .ready(ready), .data_pins_in(data_pins_in), .OE(OE), .CS(CS), .WE(WE), .data_pins_out_en(data_pins_out_en));

    pixel_buffer pb(.clk(vga_clk), .reset(reset), .erase_button(erase), .address(address), .data_read(data_read), .data_write(data_write), .read(read), .write(write), .ready(ready), .pixel_buf(pixel_buf), .hcounter(hcounter), .vcounter(vcounter), .ram_state(pb_state), .x(x), .y(y));

  /* Make a regular pulsing clock. */
  always #1 vga_clk = !vga_clk; // 25 mhz
//  always #1 clk = !clk; //100 mhz

endmodule // test

