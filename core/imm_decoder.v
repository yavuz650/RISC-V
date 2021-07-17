/*
Immediate Decoder
Generates immediate values as defined in the spec.
*/

module imm_decoder(input [29:0] instr_in,
                   output reg [31:0] imm_out);


always @*
begin
	case(instr_in[4:0])
		5'b01101 : imm_out = { instr_in[29:10], 12'b0 }; // U-type
		5'b00101 : imm_out = { instr_in[29:10], 12'b0 }; // U-type
		5'b11011 : imm_out = { {12{ instr_in[29] }}, instr_in[17:10], instr_in[18], instr_in[28:23], instr_in[22:19], 1'b0 };// J-type
		5'b11001 : imm_out = { {21{ instr_in[29] }}, instr_in[28:23], instr_in[22:19], instr_in[18] };// I-type
		5'b00000 : imm_out = { {21{ instr_in[29] }}, instr_in[28:23], instr_in[22:19], instr_in[18] };// I-type
		5'b00100 : imm_out = { {21{ instr_in[29] }}, instr_in[28:23], instr_in[22:19], instr_in[18] };// I-type
		5'b11000 : imm_out = { {20{ instr_in[29] }}, instr_in[5], instr_in[28:23], instr_in[9:6], 1'b0 };// B-type
		5'b01000 : imm_out = { {21{ instr_in[29] }}, instr_in[28:23], instr_in[9:6], instr_in[5] };// S-type
		5'b11100 : imm_out = { 27'b0, instr_in[17:13] }; // CSR immediate

		default  : imm_out = 32'b0;
	endcase
end
endmodule
