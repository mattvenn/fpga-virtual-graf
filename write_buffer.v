module write_buffer(
    input wire clk,
    input wire clk_en,
    input wire reset,
    input wire erase,
    input wire start,

    output reg [17:0] address,
    input wire [15:0] data_read,
    output reg [15:0] data_write,
    input wire ram_ready,
    output reg ram_read,
    output reg ram_write,

    input wire [9:0] cam_x,
    input wire [9:0] cam_y,
    input wire cam_valid
);

    reg line_start = 0;
    reg line_clk_en = 0;
    wire line_plot;
    wire line_done;

    // these are outputs from line drawing alg
    wire [9:0] x;
    wire [9:0] y;

    // beginning and ends of the line
    reg [9:0] x0;
    reg [9:0] y0;
    reg [9:0] x1;
    reg [9:0] y1;

    reg [4:0] state = STATE_START;

    localparam STATE_START = 0;
    localparam STATE_ERASE = 1;
    localparam STATE_START_LINE = 2;
    localparam STATE_WAIT_LINE = 3;
    localparam STATE_ERASE_WAIT = 4;
    localparam STATE_READ_SRAM = 5;
    localparam STATE_READ_SRAM_WAIT = 6;
    localparam STATE_WRITE_SRAM = 7;
    localparam STATE_WRITE_SRAM_WAIT = 8;
    

    bresenham line (.clk(clk), .clk_en(line_clk_en), .reset(reset), .y(y), .x(x), .x0(x0), .y0(y0), .x1(x1), .y1(y1), .done(line_done), .start(line_start), .plot(line_plot));

    reg last_invalid = 0;

    always @(posedge clk) begin
        if(reset) begin
            address <= 0;
            state <= STATE_START;
            line_start <= 0;
            line_clk_en <= 0;
            ram_write <= 0;
            ram_read <= 0;
            x0 <= 0;
            y0 <= 0;
            x1 <= 0;
            y1 <= 0;
            last_invalid <= 0;

        end else if (clk_en) case(state)
            STATE_START: begin
                ram_write <= 0;
                address <= 0;
                if(start) begin
                    if(erase) state <= STATE_ERASE;
                    else if (cam_valid) begin // cam valid
                        //register the line variables so they can't change while drawing the line
                        x0 <= x1;
                        y0 <= y1;
                        x1 <= cam_x;
                        y1 <= cam_y;
                        last_invalid <= 0;

                        // only start drawing the line if the last camera value wasn't invalid
                        if(!last_invalid)
                            state <= STATE_START_LINE;

                    end else
                        last_invalid <= 1;
                end
            end

            // untested in this setting
            STATE_ERASE: begin
                data_write <= 16'h0000;
                if(ram_ready) begin
                    state <= STATE_ERASE_WAIT;
                    ram_write <= 1;
                    address <= address + 1;
                end
            end
            STATE_ERASE_WAIT: begin
                ram_write <= 0;
                if(address > 38400) begin
                    state <= STATE_START;
                end else
                    state <= STATE_ERASE;
            end

            STATE_START_LINE: begin // start line drawing
                line_clk_en <= 1;
                line_start <= 1;
                if(line_plot) state <= STATE_WAIT_LINE;
            end

            STATE_WAIT_LINE: begin 
                line_start <= 0;
                line_clk_en <= 0; // stop line algorithm while write to SRAM
                if(ram_ready) state <= STATE_READ_SRAM;
            end
            
            STATE_READ_SRAM: begin // read what's there first
                // x >> 3 divides x by 8 - using a / broke timing requirements
                address <= ( x >> 3 ) + y * 80;
                ram_read <= 1;
                if(!ram_ready) 
                    state <= STATE_READ_SRAM_WAIT;
            end

            STATE_READ_SRAM_WAIT: begin
                ram_read <= 0;
                if(ram_ready)
                    state <= STATE_WRITE_SRAM;
            end

            STATE_WRITE_SRAM: begin // so we can add the new point
                ram_read <= 0;
                ram_write <= 1;
                data_write <= data_read[7:0] | (1 << x[2:0]);
                if(!ram_ready) 
                    state <= STATE_WRITE_SRAM_WAIT;
            end

            STATE_WRITE_SRAM_WAIT: begin
                ram_write <= 0;
                if(line_done) begin
                    state <= STATE_START;
                end else if(ram_ready) begin
                    line_clk_en <= 1; // let line algorithm take another step
                    state <= STATE_WAIT_LINE;
                end
            end

            default: state <= STATE_START;

        endcase
    end

endmodule
