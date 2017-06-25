`default_nettype none
// if all the following are defined, will get the 'fail to place pll' error. If any one is undefined, p-n-r succeeds
`define pll_fail1
`define pll_fail2
`define pll_fail3
module top (
	input  clk,
	output [0:3] LED,
    output pixartclk,
    output pixart_reset,
    output i2c_sda,
    input i2c_sda_in,
    output i2c_scl,
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

    reg[9:0] x = 50;
    reg[9:0] y = 50;

    wire reset = 0;
    assign pixart_reset = 1;

    clk_divn #(.WIDTH(16), .N(500)) clockdiv_cam(.clk(clk), .clk_out(cam_clk));
//    camera cam(.clk (cam_clk), .reset (reset), .i2c_scl(i2c_scl), .i2c_sda_in(i2c_sda_in), .i2c_sda(i2c_sda), .start(i2c_start), .x(x), .y(y)); //, .debug(PIO0)); 

//   xy_leds leds(.x(x), .y(y), .LED1(LED[0]), .LED2(LED[1]),.LED3(LED[2]),.LED4(LED[3]));

    SB_IO #(
        .PIN_TYPE(6'b 1010_01),
    ) sram_data_pins [15:0] (
        .PACKAGE_PIN(DAT),
        .OUTPUT_ENABLE(data_pins_out_en),
        .D_OUT_0(data_pins_out),
        .D_IN_0(data_pins_in),
    );
`ifdef pll_fail3
    //PLL details http://www.latticesemi.com/view_document?document_id=47778
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
    clk_divn clockdiv(.clk(clkx5), .clk_out(vga_clk));
 `ifdef pll_fail1
    vga vga_test(.line(data_read), .clk(vga_clk), .hsync(hsync), .vsync(vsync), .blank(blank), .red(red), .green(green), .blue(blue));
 `endif
 `ifdef pll_fail2
    dvid dvid_test(.clk(vga_clk), .clkx5(clkx5), .hsync(hsync), .vsync(vsync), .blank(blank), .red(red), .green(green), .blue(blue), .hdmi_p(PMOD[0:3]), .hdmi_n(PMOD[4:7]));
`endif
/*
    assign PMOD[16] = hsync;    // 3
    assign PMOD[17] = vsync;    // 2
    assign PMOD[18] = blank;    // 1
    assign PMOD[19] = vga_clk;  // 0
    */
    

    reg [17:0] address;
    wire [15:0] data_read;
    reg [15:0] data_write;
    reg read;
    reg write;
    reg ready;

    wire [15:0] data_pins_in;
    wire [15:0] data_pins_out;
    wire data_pins_out_en;

    reg [2:0] ram_state = 0;


    always @(posedge clk) begin
        
        case(ram_state)
            0: begin
                ram_state <= 0;
                read <= 1;
                address <= 0;
                if(vsync == 0)
                    ram_state <= 1;
            end
            1: begin
               ram_state <= 2;
               read <= 0;
            end
            2: begin
               data_write <= data_write + 1;
        //       data_read <= data_read + 1;
               write <= 1;
               ram_state <= 3;
            end
            3: begin
                write <= 0;
                ram_state <= 0;
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
