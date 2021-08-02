/*
Control Unit
This module is responsible for generating the necessary control signals for the core.
*/

module control_unit(input [31:0] instr_i,

                    output reg muldiv_start,
                    output reg muldiv_sel,
                    output reg [1:0] op_mul,
                    output reg [1:0] op_div,
                    output reg [3:0] ALU_func,
                    output reg [1:0] CSR_ALU_func,
                    output reg EX_mux1, EX_mux3, EX_mux5, EX_mux7, EX_mux8,
                    output reg [1:0] EX_mux6,
                    output reg B, J,
                    output reg [1:0] MEM_len, //memory load-store length
                    output reg MEM_wen, WB_rf_wen, WB_csr_wen, //memory write enable, register file write enable, CSR unit write enable
                    output reg [1:0] WB_mux,
                    output reg WB_sign, //load-store sign
                    output reg illegal_instr, //illegal instruction exception
                    output     ecall_o, ebreak_o, //ecall and ebreak exception signals
                    output     mret_o);

//mux input signals, do not override
parameter data1_EX = 1'b0;
parameter data2_EX = 1'b0;
parameter imm_EX   = 1'b1;
parameter pc_EX    = 1'b1;

parameter aluout_MEM = 2'd0;
parameter memout_MEM = 2'd1;
parameter imm_MEM    = 2'd2;

wire [6:0] opcode;
wire [2:0] funct3;
wire [6:0] funct7;
wire mret, ecall, ebreak;
assign opcode = instr_i[6:0];
assign funct3 = instr_i[14:12];
assign funct7 = instr_i[31:25];

always @*
begin
    if(opcode == 7'b01100_11 && funct7 == 7'd1) 
	begin
        muldiv_start = 1'b1;
        muldiv_sel = funct3[2];
        op_mul = funct3[1:0];
        op_div = funct3[1:0];
    end
    else 
	begin
        muldiv_start = 1'b0;
        muldiv_sel = 1'b0;
        op_mul = 2'b00;
        op_div = 2'b00;
    end

end

always @*
begin
	casez(opcode)
		//BEQ, BNE, BLT, BGE, BLTU, BGEU
		7'b11000_11:
		begin
			WB_rf_wen = 1'b1;
			WB_csr_wen = 1'b1;
			WB_mux = aluout_MEM;
			WB_sign = 1'b0;
			MEM_len = 2'b0;
			MEM_wen = 1'b1;
			CSR_ALU_func = 2'b0;
			B = 1'b1;
			J = 1'b0;
			EX_mux8 = 2'd0;
			EX_mux7 = 1'b1;
			EX_mux6 = 2'b0;
			EX_mux5 = 1'b1;
			EX_mux3 = data2_EX;
			EX_mux1 = data1_EX;
			case(funct3)
				3'b000: ALU_func = 4'b1010; //BEQ
				3'b001: ALU_func = 4'b1011; //BNE
				3'b100: ALU_func = 4'b0110; //BLT
				3'b101: ALU_func = 4'b1101; //BGE
				3'b110: ALU_func = 4'b0101; //BLTU
				3'b111: ALU_func = 4'b1100; //BGEU
				default: ALU_func = 4'b0000;
			endcase
		end

		//LUI
		7'b01101_11:
		begin
			WB_rf_wen = 1'b0;
			WB_csr_wen = 1'b1;
			WB_mux = imm_MEM;
			WB_sign = 1'b0;
			MEM_len = 2'b0;
			MEM_wen = 1'b1;
			CSR_ALU_func = 2'b0;
			B = 1'b0;
			J = 1'b0;
			EX_mux8 = 2'd0;
			EX_mux7 = 1'b1;
			EX_mux6 = 2'b0;
			EX_mux5 = 1'b0;
			EX_mux3 = imm_EX;
			EX_mux1 = pc_EX;
			ALU_func = 4'b1111;
		end

		//AUIPC
		7'b00101_11:
		begin
			WB_rf_wen = 1'b0;
			WB_csr_wen = 1'b1;
			WB_mux = aluout_MEM;
			WB_sign = 1'b0;
			MEM_len = 2'b0;
			MEM_wen = 1'b1;
			CSR_ALU_func = 2'b0;
			B = 1'b0;
			J = 1'b0;
			EX_mux8 = 2'd0;
			EX_mux7 = 1'b1;
			EX_mux6 = 2'b0;
			EX_mux5 = 1'b0;
			EX_mux3 = imm_EX;
			EX_mux1 = pc_EX;
			ALU_func = 4'b0000;
		end

		//JAL, JALR
		7'b110?1_11:
		begin
			WB_rf_wen = 1'b0;
			WB_csr_wen = 1'b1;
			WB_mux = aluout_MEM;
			WB_sign = 1'b0;
			MEM_len = 2'b0;
			MEM_wen = 1'b1;
			CSR_ALU_func = 2'b0;
			B = 1'b0;
			J = 1'b1;
			EX_mux8 = 2'd0;
			EX_mux7 = 1'b1;
			EX_mux6 = 2'b0;
			EX_mux3 = data2_EX;
			EX_mux1 = pc_EX;
			ALU_func = 4'b1110;

			case(opcode[3])
				1'b1: EX_mux5 = 1'b1; //JAL
				1'b0: EX_mux5 = 1'b0; //JALR
			endcase
		end

		//LB, LH, LW, LBU, LHU
		7'b00000_11:
		begin
			WB_rf_wen = 1'b0;
			WB_csr_wen = 1'b1;
			WB_mux = memout_MEM;
			MEM_wen = 1'b1;
			CSR_ALU_func = 2'b0;
			B = 1'b0;
			J = 1'b0;
			EX_mux8 = 2'd0;
			EX_mux7 = 1'b1;
			EX_mux6 = 2'b0;
			EX_mux5 = 1'b0;
			EX_mux3 = imm_EX;
			EX_mux1 = data1_EX;
			ALU_func = 4'b0000;

			case(funct3)
				3'b000: begin WB_sign = 1'b1; MEM_len = 2'd0; end //LB
				3'b001: begin WB_sign = 1'b1; MEM_len = 2'd1; end //LH
				3'b010:	begin WB_sign = 1'b1; MEM_len = 2'd2; end //LW
				3'b100: begin WB_sign = 1'b0; MEM_len = 2'd0; end //LBU
				3'b101: begin WB_sign = 1'b0; MEM_len = 2'd1; end //LHU
				default: begin WB_sign = 1'b0; MEM_len = 2'd0; end
			endcase
		end

		//SB, SH, SW
		7'b01000_11:
		begin
			WB_rf_wen = 1'b1;
			WB_csr_wen = 1'b1;
			WB_mux = aluout_MEM;
			WB_sign = 1'b0;
			MEM_wen = 1'b0;
			CSR_ALU_func = 2'b0;
			B = 1'b0;
			J = 1'b0;
			EX_mux8 = 2'd0;
			EX_mux7 = 1'b1;
			EX_mux6 = 2'b0;
			EX_mux5 = 1'b0;
			EX_mux3 = imm_EX;
			EX_mux1 = data1_EX;
			ALU_func = 4'b0000;

			case(funct3)
				3'b000: MEM_len = 2'd0; //SB
				3'b001: MEM_len = 2'd1; //SH
				3'b010: MEM_len = 2'd2; //SW
				default: MEM_len = 2'd0;
			endcase
		end

		//ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI, ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND
		7'b0?100_11:
		begin
			WB_rf_wen = 1'b0;
			WB_csr_wen = 1'b1;
			WB_mux = aluout_MEM;
			WB_sign = 1'b0;
			MEM_len = 2'b0;
			MEM_wen = 1'b1;
			CSR_ALU_func = 2'b0;
			B = 1'b0;
			J = 1'b0;
			EX_mux7 = 1'b1;
			EX_mux8 = 2'd0;

			//If the instruction is a MUL/DIV, choose the output from the MULDIV block.
			if(funct7 == 7'd1 && opcode[5] == 1'b1)
				EX_mux6 = 2'b10;
			else
				EX_mux6 = 2'b00;

			EX_mux5 = 1'b0;
			EX_mux1 = data1_EX;

			case(opcode[5])
				1'b0: EX_mux3 = imm_EX;
				1'b1: EX_mux3 = data2_EX;
			endcase

			case(funct3)
				3'b000:
				begin //ADD, ADDI, SUB
					if(opcode[5]) //see if it is an add or a subtract
						ALU_func = {3'b0,funct7[5]}; //ADD, SUB
				 	else
				 		ALU_func = 4'b0; //ADDI
				end

				3'b001: ALU_func = 4'b0111; //SLL, SLLI
				3'b010: ALU_func = 4'b0110; //SLT, SLTI
				3'b011: ALU_func = 4'b0101; //SLTU, SLTIU
				3'b100: ALU_func = 4'b0010; //XOR, XORI
				3'b101:
				begin //SRA, SRAI, SRL, SRLI
					if(funct7[5])
						ALU_func = 4'b1001; //SRA, SRAI
					else
						ALU_func = 4'b1000; //SRL, SRLI
				end

				3'b110: ALU_func = 4'b0011; //OR, ORI
				3'b111:	ALU_func = 4'b0100; //AND, ANDI
			endcase
		end

		//CSRRW, CSRRS, CSRRC, CSRRWI, CSRRSI, CSRRCI
		7'b11100_11:
		begin
			WB_rf_wen = 1'b0;
			WB_csr_wen = 1'b0;
			WB_mux = aluout_MEM;
			WB_sign = 1'b0;
			MEM_len = 2'b0;
			MEM_wen = 1'b1;
			B = 1'b0;
			J = 1'b0;
			EX_mux1 = 1'b0;
			EX_mux3 = 1'b0;
			EX_mux5 = 1'b0;
			EX_mux6 = 2'd1;
			EX_mux7 = 1'b0;
			EX_mux8 = funct3[2];
            ALU_func = 4'd0;

			casez(funct3)
				3'b?01: CSR_ALU_func = 2'd0; //RW,RWI
				3'b?10: CSR_ALU_func = 2'd1; //RS,RSI
				3'b?11: CSR_ALU_func = 2'd2; //RC,RCI
				default: CSR_ALU_func = 2'd0;
			endcase

		end

		default: begin
			ALU_func = 4'b0;
			CSR_ALU_func = 2'b0;
			{EX_mux5, EX_mux6, EX_mux7, EX_mux1, EX_mux3, EX_mux8} = 7'b0;
			{B, J} = 2'b0;
			MEM_len = 2'b0;
			WB_mux = 2'b0;
			WB_sign = 1'b0;
			{MEM_wen,WB_rf_wen,WB_csr_wen} = 3'b111;
		end

	endcase
end

assign ecall  = instr_i == 32'h0000_0073;
assign ebreak = instr_i == 32'h0010_0073;
assign mret   = instr_i == 32'h3020_0073;

always @(*)
begin
	casez(opcode)
		//BEQ, BNE, BLT, BGE, BLTU, BGEU
		7'b11000_11: illegal_instr = funct3[2:1] == 2'b01;

		//LUI, AUIPC
		7'b0?101_11: illegal_instr = 1'b0;

		//JAL, JALR
		7'b110?1_11:
		begin
			case(opcode[3])
				1'b1: illegal_instr = 1'b0; //JAL
				1'b0: illegal_instr = funct3 != 3'd0; //JALR
			endcase
		end

		//LB, LH, LW, LBU, LHU
		7'b00000_11:
		begin
			if(funct3 == 3'd3 || funct3 == 3'd6 || funct3 == 3'd7)
				illegal_instr = 1'b1;
			else
				illegal_instr = 1'b0;
		end

		//SB, SH, SW
		7'b01000_11:
		begin
			if(funct3 == 3'd0 || funct3 == 3'd1 || funct3 == 3'd2)
				illegal_instr = 1'b0;
			else
				illegal_instr = 1'b1;
		end

		//ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI, ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND
		7'b0?100_11:
		begin
			case(opcode[5])
				1'b1:
				begin
					if(funct7 == 7'd1)
						illegal_instr = 1'b0;

					else if(funct3 == 3'd0 || funct3 == 3'd5)
						illegal_instr = {funct7[6],funct7[4:0]} != 6'd0;

					else
						illegal_instr = funct7 != 7'd0;
				end

				1'b0:
				begin
					if(funct3 == 3'd1)
						illegal_instr = funct7 != 7'd0;

					else if(funct3 == 3'd5)
						illegal_instr = {funct7[6],funct7[4:0]} != 6'd0;

					else
						illegal_instr = 1'b0;
				end
			endcase
		end

		//CSRRW, CSRRS, CSRRC, CSRRWI, CSRRSI, CSRRCI, EBREAK, ECALL
		7'b11100_11: illegal_instr = !(ecall || ebreak || mret) && (funct3 == 3'b100);

		default: illegal_instr = 1'b1;
	endcase
end

assign mret_o = mret;
assign ecall_o = ecall;
assign ebreak_o = ebreak;

endmodule
