`timescale 1ns/1ps

//mux input signals
`define data1_EX  2'b0
`define data2_EX  2'b0
`define imm_EX    2'b1
`define pc_EX     2'b1

`define aluout_MEM 2'd0
`define memout_MEM 2'd1
`define imm_MEM    2'd2

module control_unit(input [14:0] control_i, //instr[31:25|14:12|6:2]
                    output reg [3:0] ALU_func1,
                    output reg [1:0] ALU_func2,
                    output reg EX_mux5, EX_mux6, EX_mux7,
                    output reg [1:0] EX_mux1, EX_mux3,
                    output reg B, J,
                    output reg [1:0] MEM_len,
                    output reg MEM_wen, WB_rf_wen, WB_csr_wen,
                    output reg [1:0] WB_mux,
                    output reg WB_sign);
			
always @*
begin
	casez(control_i[4:0])
	
		//BEQ, BNE, BLT, BGE, BLTU, BGEU
		5'b11000: 
		begin 
			WB_rf_wen = 1'b1; WB_csr_wen = 1'b1; WB_mux = `aluout_MEM; WB_sign = 1'b0; MEM_len = 2'b0; MEM_wen = 1'b1; ALU_func2 = 2'b0;
			B = 1'b1; J = 1'b0; EX_mux7 = 1'b1; EX_mux6 = 1'b0; EX_mux5 = 1'b1; EX_mux3 = `data2_EX; EX_mux1 = `data1_EX; 
			case(control_i[7:5])
				3'b000: ALU_func1 = 4'b1010; //BEQ
				3'b001: ALU_func1 = 4'b1011; //BNE
				3'b100: ALU_func1 = 4'b0110; //BLT
				3'b101: ALU_func1 = 4'b1101; //BGE
				3'b110: ALU_func1 = 4'b0101; //BLTU
				3'b111: ALU_func1 = 4'b1100; //BGEU
				default: ALU_func1 = 4'b0000;
			endcase		
		end
		
		//LUI
		5'b01101: 
		begin 
			WB_rf_wen = 1'b0; WB_csr_wen = 1'b1; WB_mux = `aluout_MEM; WB_sign = 1'b0; MEM_len = 2'b0; MEM_wen = 1'b1; ALU_func2 = 2'b1;
			B = 1'b0; J = 1'b0; EX_mux7 = 1'b1; EX_mux6 = 1'b0; EX_mux5 = 1'b0; EX_mux3 = `imm_EX; EX_mux1 = `pc_EX; ALU_func1 = 4'b1111;  
		end
		
		//AUIPC
		5'b00101: 
		begin 
			WB_rf_wen = 1'b0; WB_csr_wen = 1'b1; WB_mux = `imm_MEM; WB_sign = 1'b0; MEM_len = 2'b0; MEM_wen = 1'b1; ALU_func2 = 2'b0;
			B = 1'b0; J = 1'b0; EX_mux7 = 1'b1; EX_mux6 = 1'b0; EX_mux5 = 1'b0; EX_mux3 = `imm_EX; EX_mux1 = `pc_EX; ALU_func1 = 4'b0000;  
		end 
		
		//JAL, JALR
		5'b110?1: 
		begin 
			WB_rf_wen = 1'b0; WB_csr_wen = 1'b1; WB_mux = `aluout_MEM; WB_sign = 1'b0; MEM_len = 2'b0; MEM_wen = 1'b1; ALU_func2 = 2'b0;
			B = 1'b0; J = 1'b1; EX_mux7 = 1'b1; EX_mux6 = 1'b0; EX_mux3 = `data2_EX; EX_mux1 = `pc_EX; ALU_func1 = 4'b1110; 
			case(control_i[1])
				1'b1: EX_mux5 = 1'b1; //JAL
				1'b0: EX_mux5 = 1'b0; //JALR
			endcase
		end
		
		//LB, LH, LW, LBU, LHU
		5'b00000: 
		begin 
			WB_rf_wen = 1'b0; WB_csr_wen = 1'b1; WB_mux = `memout_MEM; MEM_wen = 1'b1; ALU_func2 = 2'b0;
			B = 1'b0; J = 1'b0; EX_mux7 = 1'b1; EX_mux6 = 1'b0; EX_mux5 = 1'b0; EX_mux3 = `imm_EX; EX_mux1 = `data1_EX; ALU_func1 = 4'b0000; 
			case(control_i[7:5])
				3'b000: begin WB_sign = 1'b1; MEM_len = 2'd0; end //LB 
				3'b001: begin WB_sign = 1'b1; MEM_len = 2'd1; end //LH
				3'b010:	begin WB_sign = 1'b1; MEM_len = 2'd2; end //LW
				3'b100: begin WB_sign = 1'b0; MEM_len = 2'd0; end //LBU
				3'b101: begin WB_sign = 1'b0; MEM_len = 2'd1; end //LHU
				default: begin WB_sign = 1'b0; MEM_len = 2'd0; end
			endcase
		end
		
		//SB, SH, SW
		5'b01000: 
		begin 
			WB_rf_wen = 1'b1; WB_csr_wen = 1'b1; WB_mux = `aluout_MEM; WB_sign = 1'b0; MEM_wen = 1'b0; ALU_func2 = 2'b0;
			B = 1'b0; J = 1'b0; EX_mux7 = 1'b1; EX_mux6 = 1'b0; EX_mux5 = 1'b0; EX_mux3 = `imm_EX; EX_mux1 = `data1_EX; ALU_func1 = 4'b0000; 
			case(control_i[7:5])
				3'b000: MEM_len = 2'd0; //SB
				3'b001: MEM_len = 2'd1; //SH
				3'b010: MEM_len = 2'd2; //SW
				default: MEM_len = 2'd0;
			endcase
		end
			
		//ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI, ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND
		5'b0?100: 
		begin 
			WB_rf_wen = 1'b0; WB_csr_wen = 1'b1; WB_mux = `aluout_MEM; WB_sign = 1'b0; MEM_len = 2'b0; MEM_wen = 1'b1; ALU_func2 = 2'b0;
			B = 1'b0; J = 1'b0; EX_mux7 = 1'b1; EX_mux6 = 1'b0; EX_mux5 = 1'b0; EX_mux1 = `data1_EX; 
			
			case(control_i[3]) 
				1'b0: EX_mux3 = `imm_EX;
				1'b1: EX_mux3 = `data2_EX;
			endcase
			
			case(control_i[7:5])
				3'b000: 
				begin //ADD, ADDI, SUB
					if(control_i[3]) //see if it is an add or a subtract
				 		ALU_func1 = {3'b0,control_i[13]}; //ADD, SUB
				 	else
				 		ALU_func1 = 4'b0; //ADDI
				end
				 
				3'b001: ALU_func1 = 4'b0111; //SLL, SLLI 
				3'b010: ALU_func1 = 4'b0110; //SLT, SLTI
				3'b011: ALU_func1 = 4'b0101; //SLTU, SLTIU
				3'b100: ALU_func1 = 4'b0010; //XOR, XORI
				3'b101: 
				begin //SRA, SRAI, SRL, SRLI
					if(control_i[13])
						ALU_func1 = 4'b1001; //SRA, SRAI
					else  
						ALU_func1 = 4'b1000; //SRL, SRLI
				end
				
				3'b110: ALU_func1 = 4'b0011; //OR, ORI
				3'b111: ALU_func1 = 4'b0100; //AND, ANDI
			endcase
		end
		
		//CSRRW, CSRRS, CSRRC, CSRRWI, CSRRSI, CSRRCI
		5'b11100: 
		begin
			WB_rf_wen = 1'b0; WB_csr_wen = 1'b0; WB_mux = `aluout_MEM; WB_sign = 1'b0; MEM_len = 2'b0; MEM_wen = 1'b1;
			B = 1'b0; J = 1'b0; EX_mux5 = 1'b0; EX_mux6 = 1'b1; 
			
			case(control_i[7])
				1'b0: begin EX_mux1 = `data1_EX; EX_mux3 = 2'd2; EX_mux7 = 1'b0; end //register
				1'b1: begin EX_mux1 = 2'd2; EX_mux3 = `imm_EX; EX_mux7 = 1'b1; end //immediate
			endcase
			
			casez(control_i[7:5])
				3'b001: begin ALU_func1 = 4'b1111; ALU_func2 = 2'b00; end //RW
				3'b?10: begin ALU_func1 = 4'b0011; ALU_func2 = 2'b00; end //RS,RSI
				3'b011: begin ALU_func1 = 4'b0100; ALU_func2 = 2'b01; end //RC
				3'b101: begin ALU_func1 = 4'b1111; ALU_func2 = 2'b01; end //RWI
				3'b111: begin ALU_func1 = 4'b0100; ALU_func2 = 2'b10; end //RCI
				default: begin ALU_func1 = 4'b1111; ALU_func2 = 2'b00; end
			endcase
		
		end
		
		default: {ALU_func1,ALU_func2,EX_mux5,EX_mux6,EX_mux7,EX_mux1,EX_mux3,B,J,MEM_len,WB_mux,WB_sign,MEM_wen,WB_rf_wen,WB_csr_wen} = 23'h7;//{8'h1,11'h0,4'h7};// //nop
	endcase
		
end
			
endmodule


