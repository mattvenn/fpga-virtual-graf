/*
mystorm blackice has 0.5MByte SRAM on the back of the board
From datasheet: ISSI IS62WV25616DALL and IS62/65WV25616DBLL are high-speed, low power, 4M bit SRAMs organized as 256K words by 16 bits. 

a problem with the blackice board is that the PLL lines interfere with the SRAM data lines.

https://github.com/cseed/arachne-pnr/issues/64#issuecomment-310877601

hence reading/writing to data[13] will not work.

Also thanks to David on the mystorm forum:
https://forum.mystorm.uk/t/fpga-unreliability-crashing-hanging/252/6?u=mattvenn

*/
`default_nettype none
module sram (
    input wire reset,
    // 50ns max for data read/write.
    // scope shows it's about 35ns. At 100MHz, each clock cycle is 10ns, so write in 4 cycles
	input wire clk,
    input wire write,
    input wire read,
    input wire [15:0] data_write,       // the data to write
    output wire [15:0] data_read,       // the data that's been read
    input wire [17:0] address,          // address to write to
    output wire ready,                  // high when ready for next operation
    output reg data_pins_out_en,       // when to switch between in and out on data pins

    // SRAM pins
    output wire [17:0] address_pins,    // address pins of the SRAM
    input  wire [15:0] data_pins_in,
    output wire [15:0] data_pins_out,
    output wire OE,                     // ~output enable - low to enable
    output wire WE,                     // ~write enable - low to enable
    output wire CS                      // ~chip select - low to enable
);

    localparam STATE_IDLE = 0;
    localparam STATE_WRITE_SETUP = 1;
    localparam STATE_WRITE = 2;
    localparam STATE_WRITE_WAIT = 3;
    localparam STATE_READ_SETUP = 4;
    localparam STATE_READ = 5;
    localparam STATE_READ_WAIT = 6;

    reg output_enable;
    reg write_enable;
    reg chip_select;

    reg [1:0] wait_count;
    reg [2:0] state;
    reg [15:0] data_read_reg;
    reg [15:0] data_write_reg;
    reg [17:0] address_reg;

    assign address_pins = address_reg;
    assign data_pins_out = data_write_reg;
    assign data_read = data_read_reg;
    assign OE = !output_enable;
    assign WE = !write_enable;
    assign CS = !chip_select;

    assign ready = (!reset && state == STATE_IDLE) ? 1 : 0; 

    initial begin
        state <= STATE_IDLE;
        output_enable <= 0;
        chip_select <= 0;
        write_enable <= 0;
        data_pins_out_en <= 0;
    end

	always@(posedge clk) begin
        if( reset == 1 ) begin
            state <= STATE_IDLE;
            output_enable <= 0;
            data_read_reg <= 0;
            chip_select <= 0;
            write_enable <= 0;
        end
        else begin
            case(state)
                STATE_IDLE: begin
                    write_enable <= 0;
                    output_enable <= 0;
                    chip_select <= 0;
                    data_pins_out_en <= 0;
                    wait_count <= 0;

                    if(write) state <= STATE_WRITE_SETUP;
                    else if(read) state <= STATE_READ_SETUP;
                end

                STATE_WRITE_SETUP: begin
                    chip_select <= 1;               // select chip
                    address_reg <= address;
                    data_pins_out_en <= 1;          // turn data pins into output
                    data_write_reg <= data_write;   // put the data on the pins
                    state <= STATE_WRITE;           // next state...
                end
                STATE_WRITE: begin
                    write_enable <= 1;              // write happens on rising edge of write (falling of !WE)
                    state <= STATE_WRITE_WAIT;      // next state...
                end
                STATE_WRITE_WAIT: begin
                    wait_count <= wait_count + 1;   // sram takes a moment
                    if(wait_count == 1) 
                        state <= STATE_IDLE;        // next state...
                end

                STATE_READ_SETUP: begin
                    output_enable <= 1;             // turn on ram chip's outputs
                    address_reg <= address;
                    chip_select <= 1;               // select chip
                    state <= STATE_READ_WAIT;       // next state...
                end
                STATE_READ_WAIT: begin
                    wait_count <= wait_count + 1;   // wait for data to settle
                    if(wait_count == 1)
                        state <= STATE_READ;        // next state...
                end
                STATE_READ: begin
                    data_read_reg <= data_pins_in;  // put the data on the reg
                    state <= STATE_IDLE;            // next state...
                end
            endcase
        end
    end


endmodule
