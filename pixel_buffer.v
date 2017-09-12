`default_nettype none
module pixel_buffer(
    input wire clk,
    input wire reset,
    input wire erase_button,
    input wire ready,

    output reg [17:0] address,
    input wire [15:0] data_read,
    output reg [15:0] data_write,
    output reg read,
    output reg write,

    input wire [9:0] x,
    input wire [9:0] y,

    output reg [7:0] pixel_buf,
    input wire [10:0] hcounter,
    input wire [9:0] vcounter,
    output reg [3:0] ram_state
);

    reg [5:0] line_buffer_index; // offset into memory for each block of 16 pixels

    // SRAM buffer state machine            // 7654 on the pmod tek adapter
    localparam STATE_IDLE = 0;              // 0000
    localparam STATE_READ = 1;              // 0001
    localparam STATE_READ_WAIT = 2;         // 0010
    localparam STATE_BUFF_WRITE = 3;        // 0011
    localparam STATE_CAM_READ = 4;          // 0100
    localparam STATE_CAM_READ_WAIT = 5;     // 0101
    localparam STATE_CAM_WRITE = 6;         // 0110
    localparam STATE_CAM_WRITE_WAIT = 7;    // 0111
    localparam STATE_ERASE= 8;              // 1000
    localparam STATE_ERASE_WAIT = 9;        // 1001


    always @(posedge clk) begin
        if( reset == 1 ) begin
            ram_state <= STATE_IDLE;
        end
        else begin
        case(ram_state)
            STATE_IDLE: begin
                ram_state <= STATE_IDLE;
                read <= 0;
                write <= 0;
                address <= 0;

                if(hcounter == 0)
                    line_buffer_index <= 0;
                    
                if(hcounter[2:0] == 4'b000 && vcounter < 480 && hcounter < 640)     // at the end of the visible line
                    ram_state <= STATE_READ;        // read the next line of buffer from sram into bram
                else if(hcounter == 0 && vcounter == 480) // end of the visible screen
                    ram_state <= STATE_CAM_WRITE;       // write the next camera value to sram
                else if(hcounter == 0 && vcounter == 481 && erase_button) // end of the visible screen & button
                    ram_state <= STATE_ERASE;       // erase the sram
            end
            // reading into buffer takes 2.5us
            STATE_READ: begin
               if(ready) begin
                   line_buffer_index <= line_buffer_index + 1;
                   address <= line_buffer_index + vcounter * 80;
                   ram_state <= STATE_READ_WAIT;
               end
            end
            STATE_READ_WAIT: begin
               ram_state <= STATE_BUFF_WRITE;
               read <= 1;
            end
            STATE_BUFF_WRITE: begin
               read <= 0;
               pixel_buf <= data_read[7:0]; // just lower byte
               ram_state <= STATE_IDLE;
            end
            /*
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
            */
            STATE_CAM_WRITE: begin
                if(ready) begin
                    ram_state <= STATE_CAM_WRITE_WAIT;
                    address <= ( x >> 3 ) + y * 80;
                    data_write <= 16'hffff;
                    write <= 1;
                end
            end
            STATE_CAM_WRITE_WAIT: begin
                write <= 0;
                // TODO this has to read the page first, then add the pixel to it instead of writing the whole page
                // divide x by 16 - using a divide broke timing requirements
                //data_write <= last_read | (x - 16 * (x >> 4));
                ram_state <= STATE_IDLE;
            end
            STATE_ERASE: begin
                data_write <= 16'h0000;
                if(ready) begin
                    ram_state <= STATE_ERASE_WAIT;
                    write <= 1;
                    address <= address + 1;
                end
            end
            STATE_ERASE_WAIT: begin
                write <= 0;
                if(address > 38400)
                    ram_state <= STATE_IDLE;
                else
                    ram_state <= STATE_ERASE;
            end
        endcase
        end
    end


endmodule
