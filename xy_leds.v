`default_nettype none
module xy_leds(
    input wire [9:0] x,
    input wire [9:0] y,
    output wire LED1,
    output wire LED2,
    output wire LED3,
    output wire LED4,
    output wire LED5
);

    localparam MID_X = 1024 / 2 ;
    localparam MID_Y = 768 / 2;

    localparam CENT_D = 250;
    wire data_ok;
    assign data_ok = y < 1023; // y is 1023 if no blob found

    /*
    4

 3  5  1
    
    2
    */

    assign LED5 = (x < (MID_X + CENT_D)) && (x > (MID_X - CENT_D)) ? data_ok : 0;
            // && (y < (MID_Y + CENT_D)) && (y > (MID_Y - CENT_D))) ? data_ok : 0;

    assign LED1 = (x < (MID_X - CENT_D)) ? data_ok : 0;
    assign LED3 = (x > (MID_X + CENT_D)) ? data_ok : 0;

    assign LED4 = (y > (MID_Y + CENT_D)) ? data_ok : 0;
    assign LED2 = (y < (MID_Y - CENT_D)) ? data_ok : 0;

endmodule