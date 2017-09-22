`default_nettype none
module xy_leds(
    input wire [9:0] x,
    input wire [9:0] y,
    input wire reset,
    output wire LED1,
    output wire LED2,
    output wire LED3,
    output wire LED4
);

    localparam MID_X = 1024 / 2 ;
    localparam MID_Y = 768 / 2;

    wire data_ok;
    assign data_ok = (y < 1023) && ~reset; // y is 1023 if no blob found

    /*
    4

 3  5  1
    
    2
    */

    assign LED1 = (x < MID_X ) ? data_ok : 0;
    assign LED2 = (x > MID_X ) ? data_ok : 0;

    assign LED3 = (y > MID_Y ) ? data_ok : 0;
    assign LED4 = (y < MID_Y ) ? data_ok : 0;

endmodule
