`timescale 1ns/1ps

module loader_wb(input         wb_cyc_i,
                 input         wb_stb_i,
                 input         wb_we_i,
                 input [31:0]  wb_adr_i,
                 input [31:0]  wb_dat_i,
                 input [3:0]   wb_sel_i,
                 output        wb_stall_o,
                 output        wb_ack_o,
                 output [31:0] wb_dat_o,
                 output        wb_err_o,
                 input         wb_rst_i,
                 input         wb_clk_i,

                 input       uart_rx_irq,
                 input [7:0] uart_rx_byte,
                 output reg reset_o,
                 output led1, led2, led4);

parameter S0 = 0, S1 = 1, S2 = 2, S3 = 3, S4 = 4;
parameter SYS_CLK_FREQ = 100000000;

reg [2:0] state, next_state;
reg [31:0] counter;
reg [31:0] reset_cause;

wire clk, rst;
reg stb;

assign led1 = state == S0;
assign led2 = state == S1;
assign led4 = state == S3;

assign clk = wb_clk_i;
assign rst = ~wb_rst_i;

assign wb_dat_o = reset_cause;
assign wb_stall_o = 1'b0;
assign wb_err_o = 1'b0;
assign wb_ack_o = stb & wb_cyc_i;

//input registers
always @(posedge clk or negedge rst)
begin
    if(!rst)
        stb <= 1'b0;
    else
        stb <= wb_stb_i;
end

always @(posedge clk or negedge rst)
begin
	if(!rst)
		state <= S0;
	else
		state <= next_state;
end

always @(posedge clk or negedge rst)
begin
	if(!rst)
		reset_o <= 1'b1;
	else
	begin
		if(state == S1 && uart_rx_irq && uart_rx_byte == 8'h70)
		    reset_o <= 1'b0;
		else if(state == S4 && counter == 2*SYS_CLK_FREQ)
		    reset_o <= 1'b0;
		else
		    reset_o <= 1'b1;
	end
end

always @(*)
begin
	case(state)
		S0:
		begin
			if(uart_rx_irq && uart_rx_byte == 8'h2d) // 0x2d == '-'
				next_state = S1;
			else
				next_state = S0;
		end

		S1:
		begin
			if(uart_rx_irq && uart_rx_byte == 8'h70) // 0x70 == 'p'
				next_state = S2;
			else if (uart_rx_irq && uart_rx_byte == 8'h5f)
				next_state = S1;
			else if(uart_rx_irq)
				next_state = S0;
			else
				next_state = S1;
		end

		S2: next_state = S3;

		S3:
		begin
			if(uart_rx_irq)
				next_state = S4;
			else
				next_state = S3;
		end

		S4:
		begin
			if(counter == 2*SYS_CLK_FREQ)
				next_state = S0;
			else
				next_state = S4;
		end

		default: next_state = S0;
	endcase
end

always @(posedge clk or negedge rst)
begin
	if(!rst)
		reset_cause <= 32'b0;
	else
	begin
		if(next_state == S2)
			reset_cause <= 32'b1;
		else if(next_state == S0)
			reset_cause <= 32'b0;
	end
end

always @(posedge clk or negedge rst)
begin
	if(!rst)
		counter <= 32'b0;
	else
	begin
		if(state == S4)
		begin
			if(uart_rx_irq)
                counter <= 32'b0;
            else
                counter <= counter + 32'b1;
		end
		else
			counter <= 32'b0;
	end
end

endmodule
