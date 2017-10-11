`default_nettype none
`define video
`define camera
//`define xyleds
`define statusleds
`define sram
`define pixbuf

module top (
	input  clk,
	output [0:3] LED,
    input [0:1] BUTTON,
    input reset_button,
    input erase_button,
    output status_led,
    output cam_led,
    output pixartclk,
    output pixart_reset,
    inout i2c_sda,
    output i2c_scl,
    `ifdef sram
    output [17:0] ADR,
    inout [15:0] DAT,
    output RAMOE,
    output RAMWE,
    output RAMCS,
    `endif
    output [31:0] PMOD
);
    

    // flashing status light
    always @(posedge clk) begin
        if(reset)
            led_counter <= 0;
        else
            led_counter <= led_counter + 1;
    end

    // led assignments
    `ifdef statusleds
    assign LED[0] = reset;
    assign LED[1] = cam_valid;
    assign LED[2] = led_counter[26]; // flash slowly
    assign cam_led = cam_valid; // cam valid repeat
    assign status_led = led_counter[26]; // system flash repeat
    `endif

    `ifdef xyleds
    xy_leds leds(.reset(reset), .x(x), .y(y), .LED1(LED[0]), .LED2(LED[1]),.LED3(LED[2]),.LED4(LED[3]));
    `endif

    // button wires
    wire erase;
    wire reset;

    assign erase = ~BUTTON[0] | ~erase_button;
    assign reset = ~BUTTON[1] | ~reset_button;

    reg [26:0] led_counter;

    wire cam_valid;
    reg cam_clk;

    // wiimote camera is 1024 x 768
    reg[9:0] x_cam;
    reg[9:0] y_cam;
    reg[9:0] x;
    reg[9:0] y; // could be [8:0]


    // pixart clock is 25MHz, reset low to reset
    assign pixart_reset = !reset;
    assign pixartclk = vga_clk;

    wire i2c_sda_out;
    wire i2c_sda_in;

    // i2c clock enable generator, vga clk is ~25Mhz, so clk enable is 500k, i2c clk will be 250k
    wire i2c_clk_en;
    divM #(.M(50)) clockdiv_cam(.clk_in(vga_clk), .clk_out(cam_clk));
    pulse i2c_clk_en_pulse (.clk(vga_clk), .in(cam_clk), .out(i2c_clk_en));

   `ifdef camera
    camera cam(.i2c_sda_dir(i2c_sda_dir), .clk_en(i2c_clk_en), .clk (vga_clk), .reset (reset), .i2c_scl(i2c_scl), .i2c_sda_in(i2c_sda_in), .i2c_sda(i2c_sda_out), .x(x_cam), .y(y_cam));

    /*
    assign PMOD[24] = i2c_clk_en;
    assign PMOD[26] = i2c_sda_in;
    assign PMOD[27] = i2c_scl;
    assign PMOD[28] = reset;
    assign PMOD[29] = i2c_sda_dir;
    */

    // remap from 1024 x 768 -> 640 x 480
    map_cam mc(.clk(vga_clk), .reset(reset), .x_in(x_cam), .y_in(y_cam), .x_out(x), .y_out(y), .valid(cam_valid));
    
    `endif



   wire i2c_sda_dir;

    SB_IO #(
         .PIN_TYPE(6'b 1010_01),
      ) i2c_sda_pin (
        .PACKAGE_PIN(i2c_sda),
        .OUTPUT_ENABLE(i2c_sda_dir),
        .D_OUT_0(i2c_sda_out),
        .D_IN_0(i2c_sda_in),
    );
    `ifdef sram
    SB_IO #(
        .PIN_TYPE(6'b 1010_01),
    ) sram_data_pins [15:0] (
        .PACKAGE_PIN(DAT),
        .OUTPUT_ENABLE(data_pins_out_en),
        .D_OUT_0(data_pins_out),
        .D_IN_0(data_pins_in),
    );
    `endif

    //PLL details http://www.latticesemi.com/view_document?document_id=47778
    //vga clock freq is 25.2MHz (see vga.v)
    //need 5 times this for dvi output = 126MHz, so this PLL input is 100MHz (blackice clock), output is 126MHz.
    SB_PLL40_CORE #(
        .FEEDBACK_PATH("SIMPLE"),
        .PLLOUT_SELECT("GENCLK"),
        .DIVR(4'b1001),
        .DIVF(7'b1100100),
        .DIVQ(3'b011),
        .FILTER_RANGE(3'b001)
    ) uut (
//        .LOCK(lock),
        .RESETB(1'b1),
        .BYPASS(1'b0),
        .REFERENCECLK(clk),
        .PLLOUTCORE(clkx5)
    );

  wire clkx5;
  wire hsync;
  wire vsync;
  wire blank;
  wire [2:0] red;
  wire [2:0] green;
  wire [2:0] blue;
  wire vga_clk;
    divM #(.M(5)) clockdiv(.clk_in(clkx5), .clk_out(vga_clk)); // vga clock used for global clock

    `ifdef video
    wire [7:0] pixels;
    vga vga_test(.reset(reset), .pixels(pixels), .clk(vga_clk), .hsync(hsync), .vsync(vsync), .blank(blank), .red(red), .green(green), .blue(blue), .hcounter(hcounter), .vcounter(vcounter));

    dvid dvid_test(.clk(vga_clk), .clkx5(clkx5), .hsync(hsync), .vsync(vsync), .blank(blank), .red(red), .green(green), .blue(blue), .hdmi_p(PMOD[0:3]), .hdmi_n(PMOD[4:7]));

    assign PMOD[16] = hsync;    // 0
    assign PMOD[17] = vsync;    // 1
    assign PMOD[18] = blank;    // 2
    assign PMOD[19] = vga_clk;  // 3
    `endif

    `ifdef sram

    reg [17:0] address;
    wire [15:0] data_read;
    reg [15:0] data_write;
    reg read;
    reg write;
    reg ready;

    wire [10:0] hcounter;
    wire [9:0] vcounter;

    wire [15:0] data_pins_in;
    wire [15:0] data_pins_out;
    wire data_pins_out_en;

    sram sram_test(.clk(vga_clk), .address(address), .data_read(data_read), .data_write(data_write), .write(write), .read(read), .reset(reset), .ready(ready), 
        .data_pins_in(data_pins_in), 
        .data_pins_out(data_pins_out), 
        .data_pins_out_en(data_pins_out_en),
        .address_pins(ADR), 
        .OE(RAMOE), .WE(RAMWE), .CS(RAMCS)
        );

    `endif

    `ifdef pixbuf
   // pixel buffer reads video buffer from SRAM during a line
   pixel_buffer pb(.clk(vga_clk), .reset(reset), .address(pb_address), .data_read(data_read), .read(pb_read), .ready(ready), .pixels(pixels), .hcounter(hcounter), .vcounter(vcounter)); 

   // write buffer writes pixels to the SRAM at the end of the screen
   write_buffer wb(.clk(vga_clk), .reset(reset), .address(wb_address), .data_read(data_read), .ram_read(wb_read), .ram_ready(ready), .data_write(data_write), .ram_write(write), .erase(erase), .cam_x(x), .cam_y(y), .cam_valid(cam_valid), .start(start_write), .clk_en(write_buf_clk_en));

    reg start_write;
    reg write_buf_clk_en;
    wire wb_read, pb_read;
    wire [17:0] pb_address;
    wire [17:0] wb_address;
    
    // start signal for capturing camera position and drawing next line
    always @(posedge vga_clk) 
        start_write <= vcounter == 480 && hcounter == 0;

    // mux for SRAM address lines
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
    `endif

endmodule
    
