`default_nettype none
module xy_leds(
    input wire [10:0] x,
    input wire [10:0] y,
    output wire [4:0] leds
);

    localparam MID_X = 500;
    localparam MID_Y = 500;

    localparam CENT_D = 250;

    /*
    1

 4  0  2
    
    3
    */

    assign leds[0] = ((x < (MID_X + CENT_D)) && (x > (MID_X - CENT_D)) && (y < (MID_Y + CENT_D)) && (y > (MID_Y - CENT_D))) ? 1 : 0;

    assign leds[2] = (x > (MID_X + CENT_D)) ? 1 : 0;
    assign leds[4] = (x < (MID_X - CENT_D)) ? 1 : 0;

    assign leds[1] = (y > (MID_Y + CENT_D)) ? 1 : 0;
    assign leds[3] = (y < (MID_Y - CENT_D)) ? 1 : 0;

endmodule
