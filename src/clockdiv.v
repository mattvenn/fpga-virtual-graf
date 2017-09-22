//- divM.v
//With thanks to Obijuan
//https://github.com/Obijuan/open-fpga-verilog-tutorial/wiki/Cap%C3%ADtulo-15%3A-Divisor-de-frecuencias
module divM(input wire clk_in, output wire clk_out);
    
// default clock divider
parameter M = 5;
    
// number of bits necessary to count up to the divider
localparam N = $clog2(M);
    
reg [N-1:0] divcounter = 0;
    
//-- Contador módulo M
always @(posedge clk_in)
  if (divcounter == M - 1) 
    divcounter <= 0;
  else 
    divcounter <= divcounter + 1;
    
//clock goes high when MSB is high
assign clk_out = divcounter[N-1];
    
endmodule
