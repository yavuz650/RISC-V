`timescale 1ns/10ps

module hazard_detection_unit(   input [4:0] rs1,
				input [4:0] rs2,
				input [4:0] idex_rd,
				input idex_mem,
				
				output reg id_mux, ifid_write_en);
				
always @(*)
begin
	if(idex_mem)
	begin
		if(rs1 == idex_rd || rs2 == idex_rd)
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
				
