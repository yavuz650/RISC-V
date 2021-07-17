/*
Hazard Detection Unit
This module is responsible for detecting data hazards that require pipeline stalls.
A pipeline stall is necessary when the instruction right after a load instruction
has a data dependency on the load instruction.
*/
module hazard_detection_unit(input [4:0] rs1,
                             input [4:0] rs2,
                             input [4:0] opcode, //opcode is used to determine if the instruction needs rs1 and/or rs2.
                             input funct3,
                             input [4:0] rd_EX,
                             input L_EX, //indicates if the instruction is a load

                             output reg hazard_stall);

wire uses_rs1, uses_rs2;

assign uses_rs1 = opcode[4:1] == 4'b1100 || //JALR and branch instructions
                  opcode[4:0] == 5'b00000 || //load instructions
                  opcode[4:0] == 5'b01000 || //store instructions
                  opcode[4:0] == 5'b00100 || //register-immediate arithmetic
                  opcode[4:0] == 5'b01100 || //register-register arithmetic
                  (opcode[4:0] == 5'b11100 && funct3 == 1'b0); //CSR instructions

assign uses_rs2 = opcode[4:0] == 5'b11000 || //branch instructions
                  opcode[4:0] == 5'b01000 || //store instructions
                  opcode[4:0] == 5'b01100; //register-register arithmetic
always @(*)
begin
	if(L_EX)
	begin
		if((rs1 == rd_EX && uses_rs1) || (rs2 == rd_EX && uses_rs2))
			hazard_stall = 1'b1;

		else
			hazard_stall = 1'b0;
	end
	else
	begin
		hazard_stall = 1'b0;
	end
end

endmodule
