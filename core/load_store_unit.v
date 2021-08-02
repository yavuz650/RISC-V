module load_store_unit(input clk_i,
                       input reset_i,

                       input [31:0] addr_i,
                       input [31:0] data_i,
                       input [1:0]  length_EX_i,
                       input        load_i,
                       input        wen_i,
                       input        misaligned_EX_i, misaligned_MEM_i,
                       input [31:0] read_data_i,
                       input [1:0]  length_MEM_i,
                       input [1:0]  addr_offset_i,
                       input [23:0] memout_WB_i,

                       output reg [31:0] data_o,
                       output     [31:0] addr_o,
                       output reg [3:0]  wmask_o,
                       output            misaligned_access_o,
                       output reg [31:0] memout_o);

wire addr_misaligned;
reg [31:0] addr_i_reg;
//EX STAGE
//see if the load/store address is misaligned and thus requires two seperate load/store operations
assign addr_misaligned     = (length_EX_i == 2'd2 && addr_i[1:0] != 2'd0) ? 1'b1
                           : (length_EX_i == 2'd1 && addr_i[1:0] == 2'd3) ? 1'b1
                           : 1'b0;

assign misaligned_access_o = (load_i | ~wen_i) & ~misaligned_EX_i & addr_misaligned; //the instruction must be a load or a store, and the address must be misaligned.

//outputs to memory
assign addr_o = misaligned_EX_i ? {addr_i_reg[31:2],2'b0} + 32'd4 : {addr_i[31:2],2'b0};

always @(posedge clk_i or negedge reset_i) 
begin
    if(!reset_i)
	    addr_i_reg <= 32'd0;
	else
	    addr_i_reg <= addr_i;	
end

always @(*)
begin
	if(!misaligned_EX_i)
	begin
		if(length_EX_i == 2'd0)
			wmask_o = 4'b1 << addr_i[1:0];

		else if(length_EX_i == 2'd1)
			wmask_o = 4'b11 << addr_i[1:0];

		else
			wmask_o = 4'b1111 << addr_i[1:0];

		data_o = data_i << 8*addr_i[1:0];
	end

	else
	begin
		if(length_EX_i == 2'd1)
		begin
			wmask_o = 4'b1;
			data_o = data_i >> 8;
		end

		else
		begin
			wmask_o = 4'b1111 >> (3'd4 - {1'b0,addr_i_reg[1:0]});
			data_o = data_i >> 8*(3'd4 - {1'b0,addr_i_reg[1:0]});
		end
	end
end

//----------------------------------------------------------------------//
//MEM STAGE
always @(*)
begin
	if(misaligned_MEM_i)
	begin
		if(length_MEM_i == 2'd2) //32-bit load
		begin
			if(addr_offset_i == 2'd3)
				memout_o = {read_data_i[23:0],memout_WB_i[7:0]};
			else if(addr_offset_i == 2'd2)
				memout_o = {read_data_i[15:0],memout_WB_i[15:0]};
			else // 2'd1
				memout_o = {read_data_i[7:0],memout_WB_i[23:0]};
		end

		else //16-bit load
			memout_o = {16'b0,read_data_i[7:0],memout_WB_i[7:0]};
	end

	else
	begin
		if(length_MEM_i == 2'd2) //32-bit load
		begin
			if(addr_offset_i == 2'd3)
				memout_o = {24'b0,read_data_i[31:24]};
			else if(addr_offset_i == 2'd2)
				memout_o = {16'b0,read_data_i[31:16]};
			else if(addr_offset_i == 2'd1)
				memout_o = {8'b0,read_data_i[31:8]};
			else
				memout_o = read_data_i;
		end

		else if(length_MEM_i == 2'd1) //16-bit load
		begin
			if(addr_offset_i == 2'd3)
				memout_o = {24'b0,read_data_i[31:24]};
			else if(addr_offset_i == 2'd2)
				memout_o = {16'b0,read_data_i[31:16]};
			else if(addr_offset_i == 2'd1)
				memout_o = {16'b0,read_data_i[23:8]};
			else
				memout_o = {16'b0,read_data_i[15:0]};
		end

		else //8-bit load
		begin
			if(addr_offset_i == 2'd3)
				memout_o = {24'b0,read_data_i[31:24]};
			else if(addr_offset_i == 2'd2)
				memout_o = {24'b0,read_data_i[23:16]};
			else if(addr_offset_i == 2'd1)
				memout_o = {24'b0,read_data_i[15:8]};
			else
				memout_o = {24'b0,read_data_i[7:0]};
		end
	end
end

endmodule

