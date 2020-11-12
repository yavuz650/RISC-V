`timescale 1ns/10ps

//output fields
`define WB       WB_o
`define MEM_MUX  MEM_o[5:4]
`define MEM_SIGN MEM_o[3]
`define MEM_LEN  MEM_o[2:1]
`define MEM_WEN  MEM_o[0]
`define B        EX_o[8]
`define J        EX_o[7]
`define EX_MUX3  EX_o[6]
`define EX_MUX2  EX_o[5]
`define EX_MUX1  EX_o[4]
`define ALU 	 EX_o[3:0]

//mux control signals
`define data1_EX 1'b0
`define data2_EX 1'b0
`define imm_EX   1'b1
`define pc_EX    1'b1

`define aluout_MEM 2'd0
`define memout_MEM 2'd1
`define imm_MEM    2'd2

module control_unit(input [14:0] control_i, //instr[31:25|14:12|6:2]
                    output reg WB_o,
                    output reg [5:0] MEM_o,
                    output reg [8:0] EX_o);
			
always @*
begin
	casez(control_i[4:0])
	
		//BEQ, BNE, BLT, BGE, BLTU, BGEU
		5'b11000: begin 
			`WB = 1'b1; `MEM_MUX = `aluout_MEM; `MEM_SIGN = 1'b0; `MEM_LEN = 2'b0; `MEM_WEN = 1'b1; `B = 1'b1; `J = 1'b0; `EX_MUX3 = `pc_EX; `EX_MUX2 = `data2_EX; `EX_MUX1 = `data1_EX;
			case(control_i[7:5])
				3'b000: `ALU = 4'b1010; //BEQ
				3'b001: `ALU = 4'b1011; //BNE
				3'b100: `ALU = 4'b0110; //BLT
				3'b101: `ALU = 4'b1101; //BGE
				3'b110: `ALU = 4'b0101; //BLTU
				3'b111: `ALU = 4'b1100; //BGEU
				default: `ALU = 4'b0000;
			endcase		
		end
		
		//LUI
		5'b01101: begin `WB = 1'b0; `MEM_MUX = `aluout_MEM; `MEM_SIGN = 1'b0; `MEM_LEN = 2'b0; `MEM_WEN = 1'b1; `B = 1'b0; `J = 1'b0; `EX_MUX3 = `data1_EX; `EX_MUX2 = `imm_EX; `EX_MUX1 = `pc_EX; `ALU = 4'b0000; end
		//AUIPC
		5'b00101: begin `WB = 1'b0; `MEM_MUX = `imm_MEM; `MEM_SIGN = 1'b0; `MEM_LEN = 2'b0; `MEM_WEN = 1'b1; `B = 1'b0; `J = 1'b0; `EX_MUX3 = `data1_EX; `EX_MUX2 = `data2_EX; `EX_MUX1 = `data1_EX; `ALU = 4'b0000; end 
		
		//JAL, JALR
		5'b110?1: begin 
			`WB = 1'b0; `MEM_MUX = `aluout_MEM; `MEM_SIGN = 1'b0; `MEM_LEN = 2'b0; `MEM_WEN = 1'b1; `B = 1'b0; `J = 1'b1; `EX_MUX2 = `data2_EX; `EX_MUX1 = `pc_EX; `ALU = 4'b1110;
			case(control_i[1])
				1'b1: `EX_MUX3 = `pc_EX;    //JAL
				1'b0: `EX_MUX3 = `data1_EX; //JALR
			endcase
		end
		
		//LB, LH, LW, LBU, LHU
		5'b00000: begin 
			`WB = 1'b0; `MEM_MUX = `memout_MEM; `MEM_WEN = 1'b1; `B = 1'b0; `J = 1'b0; `EX_MUX3 = `data1_EX; `EX_MUX2 = `imm_EX; `EX_MUX1 = `data1_EX; `ALU = 4'b0000;
			case(control_i[7:5])
				3'b000: begin `MEM_SIGN = 1'b1; `MEM_LEN = 2'd0; end //LB 
				3'b001: begin `MEM_SIGN = 1'b1; `MEM_LEN = 2'd1; end //LH
				3'b010:	begin `MEM_SIGN = 1'b1; `MEM_LEN = 2'd2; end //LW
				3'b100: begin `MEM_SIGN = 1'b0; `MEM_LEN = 2'd0; end //LBU
				3'b101: begin `MEM_SIGN = 1'b0; `MEM_LEN = 2'd1; end //LHU
				default: begin `MEM_SIGN = 1'b0; `MEM_LEN = 2'd0; end
			endcase
		end
		
		//SB, SH, SW
		5'b01000: begin 
			`WB = 1'b1; `MEM_MUX = `aluout_MEM; `MEM_SIGN = 1'b0; `MEM_WEN = 1'b0; `B = 1'b0; `J = 1'b0; `EX_MUX3 = `data1_EX; `EX_MUX2 = `imm_EX; `EX_MUX1 = `data1_EX; `ALU = 4'b0000;
			case(control_i[7:5])
				3'b000: `MEM_LEN = 2'd0; //SB
				3'b001: `MEM_LEN = 2'd1; //SH
				3'b010: `MEM_LEN = 2'd2; //SW
				default: `MEM_LEN = 2'd0;
			endcase
		end
			
		//ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI, ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND
		5'b0?100: begin 
			`WB = 1'b0; `MEM_MUX = `aluout_MEM; `MEM_SIGN = 1'b0; `MEM_LEN = 2'b0; `MEM_WEN = 1'b1; `B = 1'b0; `J = 1'b0; `EX_MUX3 = `data1_EX; `EX_MUX1 = `data1_EX;
			
			case(control_i[3]) 
				1'b0: `EX_MUX2 = `imm_EX;
				1'b1: `EX_MUX2 = `data2_EX;
			endcase
			
			case(control_i[7:5])
				3'b000: begin //ADD, ADDI, SUB
					if(control_i[3]) //see if it is an add or a subtract
				 		`ALU = {3'b0,control_i[13]}; //ADD, SUB
				 	else
				 		`ALU = 4'b0; //ADDI
				end
				 
				3'b001: `ALU = 4'b0111; //SLL, SLLI 
				3'b010: `ALU = 4'b0110; //SLT, SLTI
				3'b011: `ALU = 4'b0101; //SLTU, SLTIU
				3'b100: `ALU = 4'b0010; //XOR, XORI
				3'b101: begin //SRA, SRAI, SRL, SRLI
					if(control_i[13])
						`ALU = 4'b1001; //SRA, SRAI
					else  
						`ALU = 4'b1000; //SRL, SRLI
				end
				
				3'b110: `ALU = 4'b0011; //OR, ORI
				3'b111: `ALU = 4'b0100; //AND, ANDI
			endcase
		end
		
		default: {WB_o, MEM_o, EX_o} = 16'h41; //nop
	endcase
		
end
			
endmodule
