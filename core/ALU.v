/*
Arithmetic Logic Unit for the core.
This module is responsible for the execution of arithmetic operations.
*/

module ALU(input [31:0] src1,
           input [31:0] src2,
           input [3:0]  func,

           output reg [31:0] alu_out);

wire [4:0] shamt;
assign shamt = src2[4:0];

always @*
begin
	case(func)
		4'b0000 : alu_out = src1+src2; //add
		4'b0001 : alu_out = src1-src2; //subtract
		4'b0010 : alu_out = src1 ^ src2; //XOR
		4'b0011 : alu_out = src1 | src2; //OR
		4'b0100 : alu_out = src1 & src2; //AND
		4'b0101 : alu_out = (src1 < src2) ? 32'd1 : 32'd0; //set-less-than (unsigned)
		4'b0110 : alu_out = ($signed(src1) < $signed(src2)) ? 32'd1 : 32'd0; //set-less-than (signed)
		4'b0111 : alu_out = src1 << shamt; //shift left
		4'b1000 : alu_out = src1 >> shamt; //shift right
		4'b1001 : alu_out = ($signed(src1)) >>> shamt; //shift right arithmetical
		4'b1010 : alu_out = (src1 == src2) ? 32'd1 : 32'd0; // set if equal
		4'b1011 : alu_out = (src1 == src2) ? 32'd0 : 32'd1; // set if not equal
		4'b1100 : alu_out = (src1 >= src2) ? 32'd1 : 32'd0; // set if greater or equal (unsigned)
		4'b1101 : alu_out = ($signed(src1) >= $signed(src2)) ? 32'd1 : 32'd0; // set if greater or equal (signed)
		4'b1110 : alu_out = (src1 + 4); // PC+4
		4'b1111 : alu_out = src2; //pass
	endcase
end

endmodule
