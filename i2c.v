`default_nettype none
`define video
`define camera
`define xyleds
`define sram
`define dvid

module top (
	input  clk,
	output [0:3] LED,
    input [0:1] BUTTON,
    output pixartclk,
    output pixart_reset,
    inout i2c_sda,
    output i2c_scl,
    output i2c_sda_dir,
    `ifdef sram
    output [17:0] ADR,
    inout [15:0] DAT,
    output RAMOE,
    output RAMWE,
    output RAMCS,
    `endif
    output [31:0] PMOD
);
    
    // synchronous reset button
    always @(posedge clk) begin
        // button normally high, press makes line go low
        reset <= ~BUTTON[1];
    end

    reg cam_clk;
    reg i2c_start = 1;
    wire debounced;
    reg deb1;
	reg [8:0] counter = 0;

    // wiimote camera is 1024 x 768
    reg[9:0] x;
    reg[9:0] y;

    wire reset;
    assign pixart_reset = 1;
    assign pixartclk = vga_clk;

    wire i2c_sda_out;
    wire i2c_sda_in;

    divM #(.M(500)) clockdiv_cam(.clk_in(clk), .clk_out(cam_clk));

   `ifdef camera
    camera cam(.i2c_sda_dir(i2c_sda_dir), .clk (cam_clk), .reset (reset), .i2c_scl(i2c_scl), .i2c_sda_in(i2c_sda_in), .i2c_sda(i2c_sda_out), .start(i2c_start), .x(x), .y(y)); //, .debug(PIO0)); 
    `endif

   `ifdef xyleds
   xy_leds leds(.reset(reset), .x(x), .y(y), .LED1(LED[0]), .LED2(LED[1]),.LED3(LED[2]),.LED4(LED[3]));
   `endif

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
    `ifdef video
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
    `endif

  wire clkx5;
  wire hsync;
  wire vsync;
  wire blank;
  wire [2:0] red;
  wire [2:0] green;
  wire [2:0] blue;
  wire vga_clk;

    `ifdef video
    divM #(.M(5)) clockdiv(.clk_in(clkx5), .clk_out(vga_clk));
    vga vga_test(.reset(reset), .pixel(pixel), .clk(vga_clk), .hsync(hsync), .vsync(vsync), .blank(blank), .red(red), .green(green), .blue(blue), .hcounter(hcounter), .vcounter(vcounter));

    dvid dvid_test(.clk(vga_clk), .clkx5(clkx5), .hsync(hsync), .vsync(vsync), .blank(blank), .red(red), .green(green), .blue(blue), .hdmi_p(PMOD[0:3]), .hdmi_n(PMOD[4:7]));

    assign PMOD[16] = hsync;    // 0
    assign PMOD[17] = vsync;    // 1
    assign PMOD[18] = blank;    // 2
    assign PMOD[19] = vga_clk;  // 3
    `endif
    
    wire pixel;
    wire [10:0] hcounter;
    wire [9:0] vcounter;

    `ifdef sram
    reg [17:0] address;
    wire [15:0] data_read;
    reg [15:0] last_read;
    reg [15:0] data_write;
    reg read;
    reg write;
    reg ready;

    wire [15:0] data_pins_in;
    wire [15:0] data_pins_out;
    wire data_pins_out_en;

    reg [3:0] ram_state = 0;
    reg [639:0] line_buffer;

    assign pixel = line_buffer[640 - vga_x]; // flip it as line buffer is read in backwards


    wire [9:0] vga_x;
    wire [8:0] vga_y;

    assign vga_x = hcounter <= 640 ? hcounter : 0;
    assign vga_y = vcounter <= 480 ? vcounter : 0;

    reg [5:0] line_buffer_index; // offset into memory for each block of 16 pixels

    // SRAM buffer state machine            // 654 on the pmod tek adapter
    localparam STATE_IDLE = 0;              // 000
    localparam STATE_READ = 1;              // 001
    localparam STATE_READ_WAIT = 2;         // 010
    localparam STATE_BUFF_WRITE = 3;        // 011
    localparam STATE_CAM_READ = 4;          // 100
    localparam STATE_CAM_READ_WAIT = 5;     // 101
    localparam STATE_CAM_WRITE = 6;         // 110
    localparam STATE_CAM_WRITE_WAIT = 7;    // 111
    localparam STATE_ERASE= 8;              // 000
    localparam STATE_ERASE_WAIT = 9;        // 001

    /*
    assign PMOD[20] = ram_state == STATE_READ ? 1 : 0;      // 7 output on the scope
    assign PMOD[21] = ram_state == STATE_IDLE ? 1 : 0;      // 6
    assign PMOD[22] = ram_state == STATE_CAM_WRITE ? 1 : 0; // 5
    assign PMOD[23] = ram_state == STATE_BUFF_WRITE ? 1 : 0;// 4
    */
    assign PMOD[23:21] = ram_state;

    always @(posedge vga_clk) begin
        if( reset == 1 ) begin
            ram_state <= STATE_IDLE;
        end
        else begin
        // fill up the bram from the sram at the end of the line
        case(ram_state)
            STATE_IDLE: begin
                ram_state <= STATE_IDLE;
                read <= 0;
                write <= 0;
                line_buffer_index <= 0;
                address <= 0;
                if(hcounter == 640 && vcounter < 480)     // at the end of the visible line
                    ram_state <= STATE_READ;        // read the next line of buffer from sram into bram
                else if(hcounter == 0 && vcounter == 480) // end of the visible screen
                    ram_state <= STATE_CAM_WRITE;       // write the next camera value to sram
                else if(hcounter == 0 && vcounter == 481 && ~BUTTON[0]) // end of the visible screen & button
                    ram_state <= STATE_ERASE;       // erase the sram
            end
            // reading into buffer takes 2.5us
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
            STATE_CAM_READ: begin
                address <= ( x >> 4 ) + y * 40;
                read <= 1;
                ram_state <= STATE_CAM_READ_WAIT;
                ram_state <= STATE_CAM_WRITE;
            end
            STATE_CAM_READ_WAIT: begin
               if(ready) begin
                    ram_state <= STATE_CAM_WRITE;
                    last_read <= data_read;
                    read <= 0;
                end
            end
            STATE_CAM_WRITE: begin
                write <= 1;
                // TODO this has to read the page first, then add the pixel to it instead of writing the whole page
                // divide x by 16 - using a divide broke timing requirements
                //data_write <= last_read | (x - 16 * (x >> 4));
                address <= ( x >> 4 ) + y * 40;
                data_write <= 16'hffff;
                ram_state <= STATE_CAM_WRITE_WAIT;
            end
            STATE_CAM_WRITE_WAIT: begin
                if(ready) begin
                    //write <= 0;
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
    end

    sram sram_test(.clk(clk), .address(address), .data_read(data_read), .data_write(data_write), .write(write), .read(read), .reset(reset), .ready(ready), 
        .data_pins_in(data_pins_in), 
        .data_pins_out(data_pins_out), 
        .data_pins_out_en(data_pins_out_en),
        .address_pins(ADR), 
        .OE(RAMOE), .WE(RAMWE), .CS(RAMCS)
        );
    `endif
endmodule
