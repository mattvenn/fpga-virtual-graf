`default_nettype none
module pulse (
	input wire clk,
	input wire in,
    input wire reset,
    output reg out
    );

    reg last;
    always @(posedge clk) begin
        if(reset)begin
            last <= 0;
            out <= 0;
        end else begin
            last <= in;
            if(last == 0 && in == 1)
                out <= 1;
            else
                out <= 0;
        end     
    end

endmodule
