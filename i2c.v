module top (
	input  clk,
	output LED1,
	output LED2,
	output LED3,
	output LED4,
	output LED5,
    output pixartclk,
    output i2c_sda,
    output i2c_scl,
    output i2c_debug,
    output edge_out,
    input button,
);
    
    localparam STATE_IDLE = 0;
    localparam STATE_PK1 = 1;
    localparam STATE_WAIT1 = 2;
    localparam STATE_PK2 = 3;
    localparam STATE_WAIT2 = 4;
    localparam STATE_STOP = 5;

    reg dbutton;
    reg [6:0] i2c_addr;
    reg [7:0] i2c_data;
    reg reset = 1;
    reg i2c_start = 0;
	reg [8:0] counter = 0;
    reg [4:0] outcount;
    reg [4:0] state = STATE_IDLE;
    reg start = 0;

    i2c_master i2c(.clk (button_clk), .start(i2c_start), .addr(i2c_addr), .data(i2c_data), .reset (reset), .i2c_sda (i2c_sda), .i2c_scl (i2c_scl), .out(outcount), .ready(i2c_ready));
    debounce db1(.clk (button_clk), .button (button), .debounced (dbutton));

    SB_PLL40_CORE #(
        .FEEDBACK_PATH("SIMPLE"),
        .PLLOUT_SELECT("GENCLK"),
        .DIVR(4'b0000),
        .DIVF(7'b1000010),
        .DIVQ(3'b101),
        .FILTER_RANGE(3'b001)
    ) uut (
        .LOCK(lock),
        .RESETB(1'b1),
        .BYPASS(1'b0),
        .REFERENCECLK(clk),
        .PLLOUTCORE(pixartclk)
    );

	assign {LED1, LED2, LED3, LED4, LED5} = state;
/*
assign LED1 = i2c_start;
    assign LED2 = dbutton;
    assign LED3 = i2c_ready;
    assign LED4 = reset;
    */
    assign edge_out = dbutton;

    // can only assign reg in one always block
    always@(dbutton) begin
        if(dbutton)
            start = 0;
        else
            start = 1;
    end

    always@(posedge clk) begin
        case(state)
            STATE_IDLE: begin
                if(start) begin
                    state <= STATE_PK2;
                end
            end
            STATE_PK1: begin
                i2c_addr <= 7'h20;
                i2c_data <= 8'hAA;
                i2c_start <= 1;
                state <= STATE_WAIT1;
            end
            STATE_WAIT1: begin
                if(i2c_ready == 0) begin
                    i2c_start <= 0;
                    state <= STATE_PK2;
                end
                else begin
                    state <= STATE_WAIT1;
                end
            end
            STATE_PK2: begin
                i2c_addr <= 7'h20;
                i2c_data <= 8'hAB;
                i2c_start <= 1;
                state <= STATE_WAIT2;
            end
            STATE_WAIT2: begin
                if(i2c_ready == 0) begin
                    i2c_start <= 0;
                    state <= STATE_STOP;
                end
                else begin
                    state <= STATE_WAIT2;
                end
            end
            STATE_STOP: begin
                // wait till trigger is finished
                if(start == 0)
                    state <= STATE_IDLE;
            end
        endcase
    end

	always@(posedge clk) begin
        reset <= 0;
		counter <= counter + 1;
        if(counter == 0)
            button_clk <= ~ button_clk;
	end

endmodule


module i2c_master(
    input wire clk,
    input wire reset,
    input wire start,
    input wire [6:0] addr,
    input wire [7:0] data,
    output reg i2c_sda,
    output wire i2c_scl,
    output reg [4:0] out,
    output wire ready
);
    localparam STATE_IDLE = 0; // no clock
    localparam STATE_START = 1;// no clock
    localparam STATE_ADDR = 2;
    localparam STATE_RW = 3;
    localparam STATE_WACK = 4;
    localparam STATE_DATA = 5;
    localparam STATE_WACK2 = 6;
    localparam STATE_STOP = 7; // no clock

    reg [8:0] state;
    reg [7:0] count;
    reg i2c_scl_enable = 0;

    reg [6:0] saved_addr;
    reg [7:0] saved_data;

    initial begin
        state = STATE_IDLE;
    end

    assign out = state;
    assign ready = (reset == 0) && (state == STATE_IDLE) ? 1 : 0;
    assign i2c_scl = (i2c_scl_enable == 0) ? 1 : ~clk;
    
    always@(negedge clk) begin
        if( reset == 1 ) begin
            i2c_scl_enable <= 0;
        end else begin
            if ((state == STATE_IDLE) || (state == STATE_START) || (state == STATE_STOP)) begin
                i2c_scl_enable <= 0;;
            end
            else begin
                i2c_scl_enable <= 1;
            end
        end
    end

	always@(posedge clk) begin
        if( reset == 1 ) begin
            state <= STATE_IDLE;
            i2c_sda <= 1;
            count <= 8'd0;
        end
        else begin
            case(state)
                STATE_IDLE: begin
                    i2c_sda <= 1;
                    if (start) begin
                        saved_addr <= addr;
                        saved_data <= data;
                        state <= STATE_START;
                    end
                    else state <= STATE_IDLE;
                end
                STATE_START: begin
                    i2c_sda <= 0;
                    state <= STATE_ADDR;
                    count <= 6;
                end
                STATE_ADDR: begin // send saved_address 7 bits, MSB
                    i2c_sda <= saved_addr[count];
                    if(count == 0) state <= STATE_RW;
                    else count <= count - 1;
                end
                STATE_RW: begin
                    i2c_sda <= 1;
                    state <= STATE_WACK;
                end
                STATE_WACK: begin
                    state <= STATE_DATA;
                    // need to read this saved_data
                    i2c_sda <= 0;
                    count <= 7;
                end
                STATE_DATA: begin
                    i2c_sda <= saved_data[count];
                    if(count == 0) state <= STATE_WACK2;
                    else count <= count - 1;
                end
                STATE_WACK2: begin
                    // need to read this saved_data
                    i2c_sda <= 0;
                    state <= STATE_STOP;
                end
                STATE_STOP: begin
                    i2c_sda <= 1;
                    state <= STATE_IDLE;
                end
            endcase
        end
    end
endmodule
