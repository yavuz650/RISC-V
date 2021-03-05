`timescale 1ns/10ps

module forwarding_unit(input [4:0] rs1,
                       input [4:0] rs2,
                       input [4:0] exmem_rd,
                       input [4:0] memwb_rd,
                       input exmem_wb, memwb_wb,

                       output reg [1:0] mux1_ctrl,
                       output reg [1:0] mux2_ctrl,
                       
			           //inputs and outputs for csr forwarding 
                       input [11:0] csr_addr_EX, csr_addr_MEM, csr_addr_WB,
                       input        csr_wen_MEM, csr_wen_WB,

                       output reg [1:0] mux3_ctrl);
			  
always @(*)
begin
	if(!exmem_wb)
	begin
		//forward rs1
		if(rs1 == exmem_rd && rs1 != 5'b0)
			mux1_ctrl = 2'b10;
		else if(!memwb_wb)
		begin
			if(rs1 == memwb_rd && rs1 != 5'b0)
				mux1_ctrl = 2'b1;
			else
				mux1_ctrl = 2'b0;
		end
		else
			mux1_ctrl = 2'b0;
			
		//forward rs2
		if(rs2 == exmem_rd && rs2 != 5'b0)
			mux2_ctrl = 2'b0;
		else if(!memwb_wb)
		begin
			if(rs2 == memwb_rd && rs2 != 5'b0)
				mux2_ctrl = 2'b1;
			else
				mux2_ctrl = 2'b10;
		end
		else
			mux2_ctrl = 2'b10;
	end
	
	else if(!memwb_wb)
	begin
		if(rs1 == memwb_rd && rs1 != 5'b0)
			mux1_ctrl = 2'b1;
		else
			mux1_ctrl = 2'b0;
			
		if(rs2 == memwb_rd && rs2 != 5'b0)
			mux2_ctrl = 2'b1;
		else
			mux2_ctrl = 2'b10;
	end
	
	else //no forwarding needed
	begin
		mux1_ctrl = 2'b0;
		mux2_ctrl = 2'b10;
	end
end

always @(*)
begin
	if(!csr_wen_MEM && csr_addr_EX == csr_addr_MEM)
		mux3_ctrl = 2'd1;
	
	else if(!csr_wen_WB && csr_addr_EX == csr_addr_WB)
		mux3_ctrl = 2'd0;
		
	else
		mux3_ctrl = 2'd2;
end

endmodule

