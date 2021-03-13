`timescale 1ns/10ps

module hazard_detection_unit(input [4:0] rs1,
                             input [4:0] rs2,
                             input [4:0] opcode,
                             input funct3,
                             input [4:0] idex_rd,
                             input idex_mem,
				
                             output reg id_mux, ifid_write_en);
				
wire uses_rs1, uses_rs2;

assign uses_rs1 = opcode[4:1] == 4'b1100 ||
                  opcode[4:0] == 5'b00000 ||
                  opcode[4:0] == 5'b01000 ||
                  opcode[4:0] == 5'b00100 ||
                  opcode[4:0] == 5'b01100 ||
                  (opcode[4:0] == 5'b11100 && ~funct3);
                  
assign uses_rs2 = opcode[4:0] == 5'b11000 ||
                  opcode[4:0] == 5'b01000 ||
                  opcode[4:0] == 5'b01100 ;
always @(*)
begin
	if(idex_mem)
	begin
		if((rs1 == idex_rd && uses_rs1) || (rs2 == idex_rd && uses_rs2))
		begin
			ifid_write_en <= 1'b1;
			id_mux <= 1'b1;
		end
		else
		begin
			ifid_write_en <= 1'b0;
			id_mux <= 1'b0;		
		end
	end
	else
	begin
		ifid_write_en <= 1'b0;
		id_mux <= 1'b0;	
	end
end			
				
endmodule
				
