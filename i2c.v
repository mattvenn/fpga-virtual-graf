`default_nettype none
module top (
	input  clk,
	output [0:3] LED,
    input [0:1] BUTTON,
    output pixartclk,
    output pixart_reset,
    inout i2c_sda,
    output i2c_scl,
    output i2c_sda_dir,
    input button,
    output [17:0] ADR,
    inout [15:0] DAT,
    output RAMOE,
    output RAMWE,
    output RAMCS,
    output [31:0] PMOD
);
    

    reg cam_clk;
    reg i2c_start = 1;
    wire debounced;
    reg deb1;
	reg [8:0] counter = 0;

    reg[9:0] x;
    reg[9:0] y;

    wire reset = 0;
    assign pixart_reset = 1;
    assign pixartclk = vga_clk;

    wire i2c_sda_out;
    wire i2c_sda_in;

    clk_divn #(.WIDTH(16), .N(500)) clockdiv_cam(.clk(clk), .clk_out(cam_clk));

    camera cam(.i2c_sda_dir(i2c_sda_dir), .clk (cam_clk), .reset (reset), .i2c_scl(i2c_scl), .i2c_sda_in(i2c_sda_in), .i2c_sda(i2c_sda_out), .start(i2c_start), .x(x), .y(y)); //, .debug(PIO0)); 

   xy_leds leds(.x(x), .y(y), .LED1(LED[0]), .LED2(LED[1]),.LED3(LED[2]),.LED4(LED[3]));

    SB_IO #(
         .PIN_TYPE(6'b 1010_01),
      ) i2c_sda_pin (
        .PACKAGE_PIN(i2c_sda),
        .OUTPUT_ENABLE(i2c_sda_dir),
        .D_OUT_0(i2c_sda_out),
        .D_IN_0(i2c_sda_in),
    );
    SB_IO #(
        .PIN_TYPE(6'b 1010_01),
    ) sram_data_pins [15:0] (
        .PACKAGE_PIN(DAT),
        .OUTPUT_ENABLE(data_pins_out_en),
        .D_OUT_0(data_pins_out),
        .D_IN_0(data_pins_in),
    );

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

    clk_divn clockdiv(.clk(clkx5), .clk_out(vga_clk));
    vga vga_test(.pixel(pixel), .clk(vga_clk), .hsync(hsync), .vsync(vsync), .blank(blank), .red(red), .green(green), .blue(blue), .hcounter(hcounter), .vcounter(vcounter));

    dvid dvid_test(.clk(vga_clk), .clkx5(clkx5), .hsync(hsync), .vsync(vsync), .blank(blank), .red(red), .green(green), .blue(blue), .hdmi_p(PMOD[0:3]), .hdmi_n(PMOD[4:7]));

    assign PMOD[16] = hsync;    // 3
    assign PMOD[17] = vsync;    // 2
    assign PMOD[18] = blank;    // 1
    assign PMOD[19] = vga_clk;  // 0
    

    reg [17:0] address;
    wire [15:0] data_read;
    reg [15:0] data_write;
    reg read;
    reg write;
    reg ready;

    wire [15:0] data_pins_in;
    wire [15:0] data_pins_out;
    wire data_pins_out_en;

    reg [3:0] ram_state = 0;
    reg [639:0] line_buffer;

    wire pixel;
    assign pixel = line_buffer[vga_x];

    wire [10:0] hcounter;
    wire [9:0] vcounter;

    wire [9:0] vga_x;
    wire [8:0] vga_y;

    assign vga_x = hcounter < 640 ? hcounter : 0;
    assign vga_y = vcounter < 480 ? vcounter : 0;

    reg [5:0] line_buffer_index; // offset into memory for each block of 16 pixels

    // SRAM buffer state machine
    localparam STATE_IDLE = 0;
    localparam STATE_READ = 1;
    localparam STATE_READ_WAIT = 2;
    localparam STATE_BUFF_WRITE = 3;
    localparam STATE_WRITE = 4;
    localparam STATE_WRITE_WAIT = 5;
    localparam STATE_ERASE = 6;
    localparam STATE_ERASE_WAIT = 7;

    always @(posedge clk) begin
        
        // fill up the bram from the sram at the end of the line
        case(ram_state)
            STATE_IDLE: begin
                ram_state <= STATE_IDLE;
                read <= 0;
                write <= 0;
                line_buffer_index <= 0;
                address <= 0;
                if(vga_x == 640 && vga_y < 480)     // at the end of the visible line
                    ram_state <= STATE_READ;        // read the next line of buffer from sram into bram
                else if(vga_x == 0 && vga_y == 480) // end of the visible screen
                    ram_state <= STATE_WRITE;       // write the next camera value to sram
                else if(vga_x == 0 && vga_y == 481 && ~BUTTON[0]) // end of the visible screen & button
                    ram_state <= STATE_ERASE;       // erase the sram
            end
            STATE_READ: begin
               line_buffer_index <= line_buffer_index + 1;
               address = line_buffer_index + vga_y * 40;
               ram_state <= STATE_READ_WAIT;
               read <= 1;
            end
            STATE_READ_WAIT: begin
               if(ready)
                ram_state <= STATE_BUFF_WRITE;
            end
            STATE_BUFF_WRITE: begin
               read <= 0;
               line_buffer <= {line_buffer[639-16:0], data_read};
               if(line_buffer_index == 40)
                    ram_state <= STATE_IDLE;
               else
                    ram_state <= STATE_READ;
            end
            // should have 1.4ms for this to complete
            STATE_WRITE: begin
                write <= 1;
                // TODO this has to read the page first, then add the pixel to it instead of writing the whole page
                // divide x by 16 - using a divide broke timing requirements
                address <= ( x >> 4 ) + y * 40;
                data_write <= 16'hffff;
                ram_state <= STATE_WRITE_WAIT;
            end
            STATE_WRITE_WAIT: begin
                if(ready) begin
                    ram_state <= STATE_IDLE;
                end
            end
            STATE_ERASE: begin
                write <= 1;
                data_write <= 16'h0000;
                address <= address + 1;
                ram_state <= STATE_ERASE_WAIT;
            end
            STATE_ERASE_WAIT: begin
                if(ready) begin
                    if(address > 19200)
                        ram_state <= STATE_IDLE;
                    else
                        ram_state <= STATE_ERASE;
                end
            end
        endcase
    end

    sram sram_test(.clk(clk), .address(address), .data_read(data_read), .data_write(data_write), .write(write), .read(read), .reset(reset), .ready(ready), 
        .data_pins_in(data_pins_in), 
        .data_pins_out(data_pins_out), 
        .data_pins_out_en(data_pins_out_en),
        .address_pins(ADR), 
        .OE(RAMOE), .WE(RAMWE), .CS(RAMCS)
        );

endmodule
