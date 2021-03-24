`timescale 1ns/1ps

module loader(input       clk_i,
              input       reset_i,
              input       uart_rx_irq,
              input [7:0] uart_rx_byte,
              
              output reg soft_reset_o,
              output reg hard_reset_o,
              output led1, led2, led3, led4);

parameter S0 = 0, S1 = 1, S2 = 2, S3 = 3, S4 = 4;

reg [2:0] state, next_state;
reg [24:0] counter;
assign led1 = state == S0;
assign led2 = state == S1;
assign led3 = state == S2;
assign led4 = state == S3;
always @(posedge clk_i or negedge reset_i)
begin
	if(!reset_i)
		state <= S0;
	else
		state <= next_state;
end

always @(*)
begin
	case(state)
		S0: begin soft_reset_o = 1'b1; hard_reset_o = 1'b1; end
		S1: begin soft_reset_o = 1'b1; hard_reset_o = 1'b1; end
		S2: begin soft_reset_o = 1'b0; hard_reset_o = 1'b1; end
		S3: begin soft_reset_o = 1'b1; hard_reset_o = 1'b1; end
		S4:
		begin
			if(counter == 25'h30e_3600) //25'h16e_3600
				hard_reset_o = 1'b0;
			else
				hard_reset_o = 1'b1;
			soft_reset_o = 1'b1;
		end
		default: begin soft_reset_o = 1'b1; hard_reset_o = 1'b1; end
	endcase
end

always @(*)
begin
	case(state)
		S0:
		begin
			if(uart_rx_irq && uart_rx_byte == 8'h5f) // 0x5f == '_'
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
			if(counter == 25'h30e_3600)
				next_state = S0;
			else
				next_state = S4;
		end
		
		default: next_state = S0;
	endcase
end

always @(posedge clk_i or negedge reset_i)
begin
	if(!reset_i)
		counter <= 25'b0;
	else
	begin
		if(state == S4)
		begin
			if(uart_rx_irq)
                counter <= 25'b0;
            else
                counter <= counter + 25'b1;
		end
		else
			counter <= 25'b0;
	end
end

endmodule

