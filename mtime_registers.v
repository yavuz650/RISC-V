`timescale 1ns/10ps

module mtime_registers(input reset_i, csb_i, wen_i, clk_i,
                       input [3:0] addr_i,
                       input [31:0] data_i,
                       input [3:0] wmask_i,
                       
                       output mtip_o,
                       output reg [31:0] data_o);
                      
parameter clk_scaler = 100; //divide clk freq. by this value
parameter cntr_len = 7;

reg [63:0] mtime, mtimecmp;
reg [cntr_len-1:0] intermediate_counter;

wire [3:0] byte_addr [3:0]; //byte addresses

assign byte_addr[0] = addr_i;
assign byte_addr[1] = addr_i + 4'd1;
assign byte_addr[2] = addr_i + 4'd2;
assign byte_addr[3] = addr_i + 4'd3;

always @(posedge clk_i or negedge reset_i)
begin
	if(!reset_i)
		{mtime, mtimecmp, data_o} <= 160'b0;
		
	else if(!csb_i)
	begin
		if(!wen_i)
		begin
			if(wmask_i[3])
			begin
				if(byte_addr[3]) //mtimecmp
					mtimecmp[8*byte_addr[3][2:0] +: 8] <= data_i[31:24];
				else
					mtime[8*byte_addr[3][2:0] +: 8] <= data_i[31:24];
			end
			if(wmask_i[2])
			begin
				if(byte_addr[3]) //mtimecmp
					mtimecmp[8*byte_addr[2][2:0] +: 8] <= data_i[23:16];
				else
					mtime[8*byte_addr[2][2:0] +: 8] <= data_i[23:16];
			end
			if(wmask_i[1])
			begin
				if(byte_addr[3]) //mtimecmp
					mtimecmp[8*byte_addr[1][2:0] +: 8] <= data_i[15:8];
				else
					mtime[8*byte_addr[1][2:0] +: 8] <= data_i[15:8];
			end
			if(wmask_i[0])
			begin
				if(byte_addr[3]) //mtimecmp
					mtimecmp[8*byte_addr[0][2:0] +: 8] <= data_i[7:0];
				else
					mtime[8*byte_addr[0][2:0] +: 8] <= data_i[7:0];
			end
		end
		
		else //read
		begin
				if(byte_addr[3]) //mtimecmp
				begin
					data_o[31:24] <= mtimecmp[8*byte_addr[3][2:0] +: 8];
					data_o[23:16] <= mtimecmp[8*byte_addr[2][2:0] +: 8];
					data_o[15:8] <= mtimecmp[8*byte_addr[1][2:0] +: 8];
					data_o[7:0] <= mtimecmp[8*byte_addr[0][2:0] +: 8];
				end
					
				else //mtime
				begin
					data_o[31:24] <= mtime[8*byte_addr[3][2:0] +: 8];
					data_o[23:16] <= mtime[8*byte_addr[2][2:0] +: 8];
					data_o[15:8] <= mtime[8*byte_addr[1][2:0] +: 8];
					data_o[7:0] <= mtime[8*byte_addr[0][2:0] +: 8];
				end
				
				if(intermediate_counter == clk_scaler-1)
					mtime <= mtime+64'd1;
		end
	end
	
	else if(intermediate_counter == clk_scaler-1)
		mtime <= mtime+64'd1;
end


always @(posedge clk_i or negedge reset_i)
begin
	if(!reset_i)
		intermediate_counter <= 0;
	else if(intermediate_counter == clk_scaler-1)
		intermediate_counter <= 0;
	else
		intermediate_counter <= intermediate_counter + 1;
end

assign mtip_o = mtime >= mtimecmp ? 1'b1 : 1'b0;

endmodule

