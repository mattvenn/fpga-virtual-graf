`default_nettype none
module bresenham (
    input wire clk,
    input wire reset,
    input wire start,
    input wire [7:0] x0,
    input wire [7:0] y0,
    input wire [7:0] x1,
    input wire [7:0] y1,
    output reg plot,
    output reg [7:0] x,
    output reg [7:0] y,
    output reg done);

    reg [2:0] state;
    reg signed [7:0] dx;
    reg signed [7:0] dy;
    reg signed [7:0] sx;
    reg signed [7:0] sy;
    reg signed [7:0] err;
    reg signed [7:0] err2;

    reg [7:0] counter;

    localparam STATE_IDLE = 0;
    localparam STATE_PLOT = 1;

    always @(posedge clk) begin
        if(reset) begin
            counter <= 0;
            done <= 0;
            plot <= 0;
            state <= STATE_IDLE;
        end

        case(state)
            STATE_IDLE: begin
                done <= 0;
                if(start) begin
                    dx = x0 - x1; // blocking
                    dy = y0 - y1;
                    if(dx < 0) dx = -dx;
                    if(dy < 0) dy = -dy;
                    sx = x0 < x1 ? 1 : -1;
                    sy = y0 < y1 ? 1 : -1; 
                    err = dx - dy;
                    x <= x0;
                    y <= y0;
                    plot <= 1;
                    state <= STATE_PLOT;
                end
            end
            STATE_PLOT: begin
                counter <= counter + 1;
                if(x == x1 && y == y1 ) begin
                    done <= 1;
                    state <= STATE_IDLE;
                end else begin
                    err2 = err << 2;
                    if(err2 > -dy) begin
                        err = err - dy;
                        x <= x + sx;
                    end 
                    if (err2 < dx) begin
                        err = err + dx;
                        y <= y + sy;
                    end
                end
            end
            default:
                state <= STATE_IDLE;
        endcase
    end

endmodule
