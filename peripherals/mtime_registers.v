`timescale 1ns/1ps

module mtime_registers(input reset_i, csb_i, wen_i, clk_i,
                       input [3:0] addr_i,
                       input [31:0] data_i,
                       input [3:0] wmask_i,
                       
                       output mtip_o,
                       output reg [31:0] data_o);

reg [63:0] mtime, mtimecmp;

wire [3:0] byte_addr [3:0]; //byte addresses
wire e_h, l_h, l_l; //greater than, equal and less than for the upper and lower 32 bits (high and low). 

assign byte_addr[0] = addr_i;
assign byte_addr[1] = addr_i + 4'd1;
assign byte_addr[2] = addr_i + 4'd2;
assign byte_addr[3] = addr_i + 4'd3;

always @(posedge clk_i or negedge reset_i)
begin
	if(!reset_i)
		mtime <= 64'b0;
		
	else if(!csb_i & !wen_i)
	begin
		if(!(wmask_i[3] & !byte_addr[3][3]) & !(wmask_i[2] & !byte_addr[2][3]) & !(wmask_i[1] & !byte_addr[1][3]) & !(wmask_i[0] & !byte_addr[0][3]))
		begin
			mtime[31:0] <= mtime[31:0] + 32'd1;
			if(mtime[31:0] == 32'hffff_ffff)
				mtime[63:32] <= mtime[63:32] + 32'd1;		
		end
		
		else
		begin
			if(wmask_i[3] & !byte_addr[3][3])
				mtime[8*byte_addr[3][2:0] +: 8] <= data_i[31:24];

			if(wmask_i[2] & !byte_addr[2][3])
				mtime[8*byte_addr[2][2:0] +: 8] <= data_i[23:16];
			
			if(wmask_i[1] & !byte_addr[1][3])
				mtime[8*byte_addr[1][2:0] +: 8] <= data_i[15:8];
			
			if(wmask_i[0] & !byte_addr[0][3])
				mtime[8*byte_addr[0][2:0] +: 8] <= data_i[7:0];		
		end				
	end
	
	else
	begin
		mtime[31:0] <= mtime[31:0] + 32'd1;
		if(mtime[31:0] == 32'hffff_ffff)
			mtime[63:32] <= mtime[63:32] + 32'd1;			
	end
end

always @(posedge clk_i or negedge reset_i)
begin
	if(!reset_i)
		mtimecmp <= 64'b0;
		
	else if(!csb_i & !wen_i)
	begin
		if(wmask_i[3] & byte_addr[3][3])
			mtimecmp[8*byte_addr[3][2:0] +: 8] <= data_i[31:24];

		if(wmask_i[2] & byte_addr[2][3])
			mtimecmp[8*byte_addr[2][2:0] +: 8] <= data_i[23:16];
			
		if(wmask_i[1] & byte_addr[1][3])
			mtimecmp[8*byte_addr[1][2:0] +: 8] <= data_i[15:8];
			
		if(wmask_i[0] & byte_addr[0][3])
			mtimecmp[8*byte_addr[0][2:0] +: 8] <= data_i[7:0];		
	end
end

always @(*)
begin
	if(byte_addr[3][3]) //mtimecmp
		data_o[31:24] = mtimecmp[8*byte_addr[3][2:0] +: 8];
	else
		data_o[31:24] = mtime[8*byte_addr[3][2:0] +: 8];
		
	if(byte_addr[2][3]) //mtimecmp
		data_o[23:16] = mtimecmp[8*byte_addr[2][2:0] +: 8];
	else
		data_o[23:16] = mtime[8*byte_addr[2][2:0] +: 8];
			
	if(byte_addr[1][3]) //mtimecmp
		data_o[15:8] = mtimecmp[8*byte_addr[1][2:0] +: 8];
	else
		data_o[15:8] = mtime[8*byte_addr[1][2:0] +: 8];
		
	if(byte_addr[0][3]) //mtimecmp
		data_o[7:0] = mtimecmp[8*byte_addr[0][2:0] +: 8];
	else
		data_o[7:0] = mtime[8*byte_addr[0][2:0] +: 8];
end

assign e_h = mtime[63:32] == mtimecmp[63:32];
assign l_h = mtime[63:32] < mtimecmp[63:32];
assign l_l = mtime[31:0] < mtimecmp[31:0];

assign mtip_o = !(l_h | (e_h & l_l)); 
//assign mtip_o = mtime >= mtimecmp ? 1'b1 : 1'b0;

endmodule

