module test;

  reg clk = 0;
  reg vga_clk = 0;
  wire hsync;
  wire vsync;
  wire [7:0] pixels;
  reg reset = 1;

    reg [17:0] address;
    wire [15:0] data_read;
    wire [15:0] data_write;
    wire lower_blank;
    reg [9:0] cam_x;
    reg [9:0] cam_y;
    reg [15:0] data_pins_in;
    reg read;
    reg erase = 0;
    wire write;
    wire ready;

    wire [10:0] hcounter;
    wire [9:0] vcounter;
    wire [1:0] pb_state;

  reg start = 0;

  initial begin
     $dumpfile("test.vcd");
     $dumpvars(0, test);
     # 1 data_pins_in = 0;
     # 1 reset <= 1;
     # 8 reset <= 0;

     $dumpoff;
     // wait for screen blank
     //# 1 erase <= 1;
     wait(vcounter == 479 && hcounter == 790);
     $dumpon;
     # 1 cam_x <= 639;
     # 1 cam_y <= 479;
     wait(wb.done == 1);
     # 5000
     $finish;
  end
    

    wire [10:0] tester;
    assign tester = hcounter[3:0];
   vga vga_test(.reset(reset), .pixels(pixels), .clk(vga_clk), .hsync(hsync), .vsync(vsync), .blank(blank), .hcounter(hcounter), .vcounter(vcounter), .lower_blank(lower_blank));

  sram sram_test(.clk(vga_clk), .address(address), .data_read(data_read), .data_write(data_write), .write(write), .read(read), .reset(reset), .ready(ready), .data_pins_in(data_pins_in), .OE(OE), .CS(CS), .WE(WE), .data_pins_out_en(data_pins_out_en));

   pixel_buffer pb(.clk(vga_clk), .reset(reset), .address(pb_address), .data_read(data_read), .read(pb_read), .ready(ready), .pixels(pixels), .hcounter(hcounter), .vcounter(vcounter)); 

   write_buffer wb(.clk(vga_clk), .reset(reset), .address(wb_address), .data_read(data_read), .ram_read(wb_read), .ram_ready(ready), .data_write(data_write), .ram_write(write), .erase(erase), .cam_x(cam_x), .cam_y(cam_y), .start(start_write), .clk_en(write_buf_clk_en));

    reg start_write;
    reg write_buf_clk_en;
    wire wb_read, pb_read;
    wire [17:0] pb_address;
    wire [17:0] wb_address;
    always @(posedge vga_clk) 
        start_write <= vcounter == 480 && hcounter == 0;

    // mux
    always @(posedge vga_clk) begin
        if( vcounter > 479 ) begin
            read <= wb_read;
            address <= wb_address;
            write_buf_clk_en <= 1;
        end else begin
            read <= pb_read;
            address <= pb_address;
            write_buf_clk_en <= 0;
        end
    end

  /* Make a regular pulsing clock. */
  always #1 vga_clk = !vga_clk; // 25 mhz
//  always #1 clk = !clk; //100 mhz

endmodule // test

