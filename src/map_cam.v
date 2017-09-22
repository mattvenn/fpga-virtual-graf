module map_cam(
    input wire reset,
    input wire clk,
    input wire [9:0]x_in, // range 1024
    input wire [9:0]y_in, // 768
    output reg valid,
    output reg [9:0]x_out, // 640
    output reg [8:0]y_out // 480
    );

    reg [13:0] x_temp;
    reg [13:0] y_temp;
    

    always @(posedge clk) begin
        if(reset)
            valid <= 0;
        else begin
            x_temp = x_in * 10; // blocking
            y_temp = y_in * 10;
            x_out = x_temp >> 4;
            y_out = y_temp >> 4;
        end

        if(y_in == 1023)
            valid <= 0;
        else
            valid <= 1;
    end
endmodule
