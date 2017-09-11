module test;

  reg clk = 0;
  reg [1:0] BUTTON = 2'b11;
  reg vga_clk = 0;
  wire hsync;
  wire vsync;
  wire pixel;
  reg reset = 1;
    reg[9:0] x = 0;
    reg[9:0] y = 0;

    reg [17:0] address;
    wire [15:0] data_read;
    reg [15:0] last_read;
    reg [15:0] data_write;
    reg [15:0] data_pins_in;
    reg read;
    reg write;
    wire ready;

    wire [10:0] hcounter;
    wire [9:0] vcounter;

  /* Make a reset that pulses once. */
  initial begin
     $dumpfile("test.vcd");
     $dumpvars(0, test);
     # 1 data_pins_in = 0;
     
     # 8 reset <= 0;
     wait(vcounter == 1);
     x <= 50;
     y <= 1;
     wait(vcounter == 2);
     $finish;
  end

   vga vga_test(.reset(reset), .pixel(pixel), .clk(vga_clk), .hsync(hsync), .vsync(vsync), .blank(blank), .hcounter(hcounter), .vcounter(vcounter));

   sram sram_test(.clk(clk), .address(address), .data_read(data_read), .data_write(data_write), .write(write), .read(read), .reset(reset), .ready(ready),
    .data_pins_in(data_pins_in));

  /* Make a regular pulsing clock. */
  always #4 vga_clk = !vga_clk; // 25 mhz
  always #1 clk = !clk; //100 mhz

    reg [3:0] ram_state = 0;
    reg [639:0] line_buffer = 0;
    assign pixel = line_buffer[639 - vga_x]; // flip it as line buffer is read in backwards

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
    localparam STATE_CAM_READ = 4;
    localparam STATE_CAM_READ_WAIT = 5;
    localparam STATE_CAM_WRITE = 6;
    localparam STATE_CAM_WRITE_WAIT = 7;
    localparam STATE_ERASE= 8;
    localparam STATE_ERASE_WAIT = 9;

    always @(posedge clk) begin
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

endmodule // test

