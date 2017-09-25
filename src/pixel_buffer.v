`default_nettype none
module pixel_buffer(
    input wire clk,
    input wire reset,
    input wire ready,

    output reg [17:0] address,
    input wire [15:0] data_read,
    output reg read,

    output reg [7:0] pixels,
    input wire [10:0] hcounter,
    input wire [9:0] vcounter
);

    reg [1:0] ram_state = STATE_IDLE;
    reg [7:0] line_buffer_index; // offset into memory for each block of 8 pixels

    // SRAM buffer state machine            // 7654 on the pmod tek adapter
    localparam STATE_IDLE = 0;              // 0000
    localparam STATE_READ = 1;              // 0001
    localparam STATE_READ_WAIT = 2;         // 0010

    always @(posedge clk) begin
        if( reset == 1 ) begin
            ram_state <= STATE_IDLE;
        end
        else begin
        case(ram_state)
            STATE_IDLE: begin
                ram_state <= STATE_IDLE;
                read <= 0;
                address <= 0;

                if(hcounter == 0)
                    line_buffer_index <= 0;     // reset counter
                if(hcounter[2:0] == 4'b111) 
                    pixels <= data_read[7:0];   // update the output from the buffer - bit 13 is not working, so only use lower byte
                if(hcounter[2:0] == 4'b000 && vcounter < 480 && hcounter < 640) begin     // at the end of the visible line
                    ram_state <= STATE_READ;    // read the next line of buffer from sram into bram
                end
            end
            STATE_READ: begin
               if(ready) begin
                   line_buffer_index <= line_buffer_index + 1;
                   address <= line_buffer_index + vcounter * 80;
                   ram_state <= STATE_READ_WAIT;
               end
            end
            STATE_READ_WAIT: begin
               ram_state <= STATE_IDLE;
               read <= 1;
            end
            default: ram_state <= STATE_IDLE;
        endcase
        end
    end


endmodule
