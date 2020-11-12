`timescale 1ns/10ps

module core(input reset_i,
            input clk_i,
            input [31:0] instr_i,
            input [31:0] data_i,
	    	
            output [3:0]  wmask0_o,
            output        wen0_o,
            output [10:0] instr_addr_o,
            output [10:0] data_addr_o,
            output [31:0] data_o); //active-low reset. all write_enable signals are also active-low.
				  

//IF signals------------------------------------------------------------
wire [31:0] muxpc_o, plus4_o; //pc-mux output, pc+4 output.
wire [31:0] addr_cal_o; // address calculation output
wire        muxpc_ctrl; //pc-mux control signal. it is also controls the flush mechanism.
reg [31:0]  pc_o; //pc out
wire [10:0] mux_addr_o, mux_load_o, mux_addr_o2;
wire [31:0] instr_IF;
wire        IFID_preg_wen; //IF/ID pipeline register write enable signal.
//pipeline register
reg [31:0] IFID_preg_instr;
reg [31:0] IFID_preg_pc;
//----------------------------------------------------------------------
//ID signals
wire [4:0]   rs1_ID, rs2_ID, rd_ID; //register addresses
wire [31:0]  data1_ID, data2_ID;
wire [14:0]  ctrl_unit_i; //control unit input
wire [29:0]  imm_dec_i; //immediate decoder input
//control unit outputs
wire         ctrl_unit_wb_o;
wire [5:0]   ctrl_unit_mem_o;
wire [8:0]   ctrl_unit_ex_o;
wire [31:0]  imm_dec_o, pc_ID; //immediate decoder output, pc value
wire         mux_ctrl_ID; //control signal for all three muxes
wire         mux1_o_ID; //WB field
wire [5:0]   mux2_o_ID; //MEM field
wire [8:0]   mux3_o_ID; //EX field
//pipeline register
reg [31:0] IDEX_preg_imm;
reg [4:0]  IDEX_preg_rd, IDEX_preg_rs2, IDEX_preg_rs1;
reg [31:0] IDEX_preg_data2, IDEX_preg_data1;
reg [31:0] IDEX_preg_pc;
reg [8:0]  IDEX_preg_ex;
reg [5:0]  IDEX_preg_mem;
reg 	   IDEX_preg_wb;

reg [31:0] register_bank [31:0]; //32x32 register file
//----------------------------------------------------------------------
//EX signals------------------------------------------------------------
wire        wb_EX;
wire [5:0]  mem_EX;
wire [8:0]  ex_EX;
wire [31:0] pc_EX, data1_EX, data2_EX, imm_EX;
wire [4:0]  rs1_EX, rs2_EX, rd_EX;
wire        mux1_ctrl_EX, mux3_ctrl_EX, mux5_ctrl_EX;
wire [1:0]  mux2_ctrl_EX, mux4_ctrl_EX;
wire [31:0] mux1_o_EX, mux2_o_EX, mux3_o_EX, mux4_o_EX, mux5_o_EX;
wire [3:0]  alu_ctrl;
wire [31:0] aluout_EX;
wire        J, B, L; //jump, branch, load
//pipeline register
reg [31:0] EXMEM_preg_imm;
reg [4:0]  EXMEM_preg_rd;
reg [31:0] EXMEM_preg_data2;
reg [31:0] EXMEM_preg_aluout;
reg [5:0]  EXMEM_preg_mem;
reg        EXMEM_preg_wb;
//----------------------------------------------------------------------
//MEM signals-----------------------------------------------------------
wire        wb_MEM;
wire [5:0]  mem_MEM;
wire [31:0] aluout_MEM, data2_MEM;
wire [4:0]  rd_MEM;
wire [31:0] imm_MEM;
wire [31:0] memout_MEM;
//internal nets
wire       wen_MEM;
wire       wen_MEM_r;
wire [1:0] ls_length, ls_length_r;
wire       l_sign;
wire [1:0] mux_ctrl_MEM;
wire [3:0] wmask0;
//pipeline register
reg [4:0]  MEMWB_preg_rd;
reg [31:0] MEMWB_preg_memout;
reg        MEMWB_preg_wb;
reg [37:0] MEMWB_preg;
//----------------------------------------------------------------------
//WB signals------------------------------------------------------------
wire [4:0]  rd_WB;
wire        wb_WB;
wire [31:0] memout_WB;
//----------------------------------------------------------------------

//IF STAGE---------------------------------------------------------------------------------
//assign mux_load_o = wen_i ? pc_o[10:0] : addr_i;
assign mux_addr_o = muxpc_ctrl ? pc_o[10:0] : addr_cal_o[10:0];
assign mux_addr_o2 = IFID_preg_wen ? mux_addr_o - 11'd4 : mux_addr_o;
assign instr_addr_o = mux_addr_o2;

always @(posedge clk_i or negedge reset_i) 
begin
	if(!reset_i)
	begin
		//reset pc to wherever.
		pc_o <= 32'h0;
		{IFID_preg_pc, IFID_preg_instr} <= 64'h13; //nop instruction addi x0,x0,0
	end
	
	else if(!muxpc_ctrl) //branch taken. next address comes from the address calculation output.
	begin
		IFID_preg_instr <= 32'h13; //flush the register
		IFID_preg_pc    <= addr_cal_o;
		pc_o <= addr_cal_o + 32'd4;
	end
		
	else
	begin
		if(!IFID_preg_wen) //stall the pipe if necessary
		begin
			if(pc_o == 32'h0)
				IFID_preg_instr <= 32'h13;
			else
				IFID_preg_instr <= instr_i;
				
			IFID_preg_pc <= pc_o - 32'd4 ;
			pc_o <= pc_o + 32'd4;
		end
	end
end
//END IF STAGE-----------------------------------------------------------------------------

//ID STAGE---------------------------------------------------------------------------------
//assign nets
assign rs1_ID       = IFID_preg_instr[19:15];
assign rs2_ID       = IFID_preg_instr[24:20];
assign rd_ID        = IFID_preg_instr[11:7];
assign pc_ID        = IFID_preg_pc;
assign imm_dec_i    = IFID_preg_instr[31:2];
assign ctrl_unit_i  = {IFID_preg_instr[31:25], IFID_preg_instr[14:12], IFID_preg_instr[6:2]};
assign mux1_o_ID    = mux_ctrl_ID ? 1'b1 : ctrl_unit_wb_o;
assign mux2_o_ID    = mux_ctrl_ID ? 6'b1 : ctrl_unit_mem_o;
assign mux3_o_ID    = mux_ctrl_ID ? 9'b0 : ctrl_unit_ex_o;

control_unit    CTRL_UNIT 	(.control_i(ctrl_unit_i), .WB_o(ctrl_unit_wb_o), .MEM_o(ctrl_unit_mem_o), .EX_o(ctrl_unit_ex_o));
imm_decoder     IMM_DEC   	(.instr_in(imm_dec_i), .imm_out(imm_dec_o));

integer i;
always @(negedge clk_i or negedge reset_i) //write to register file
begin
	if(!reset_i)
	begin
		for(i=0; i < 32; i = i+1)
			register_bank[i] <= 32'b0; //reset all registers to 0.
	end
	
	else if(!wb_WB)
		register_bank[rd_WB] <= memout_WB;	
end


always @(posedge clk_i or negedge reset_i) 
begin
	if(!reset_i)
		{IDEX_preg_wb, IDEX_preg_mem, IDEX_preg_ex, IDEX_preg_pc, IDEX_preg_data1, IDEX_preg_data2, IDEX_preg_rs1, IDEX_preg_rs2, IDEX_preg_rd, IDEX_preg_imm}  <= {7'b1000001,152'b0};
		
	else if(!muxpc_ctrl) //flush the pipe
		{IDEX_preg_wb, IDEX_preg_mem, IDEX_preg_ex, IDEX_preg_pc, IDEX_preg_data1, IDEX_preg_data2, IDEX_preg_rs1, IDEX_preg_rs2, IDEX_preg_rd, IDEX_preg_imm}  <= {7'b1000001,152'b0};
	
	else
	begin
		IDEX_preg_imm <= imm_dec_o;
		IDEX_preg_rd  <= rd_ID;
		IDEX_preg_rs2 <= rs2_ID;
		IDEX_preg_rs1 <= rs1_ID;
		IDEX_preg_pc  <= pc_ID;
		IDEX_preg_ex  <= mux3_o_ID;
		IDEX_preg_mem <= mux2_o_ID;
		IDEX_preg_wb  <= mux1_o_ID;
		
		if(rs1_ID == 5'b0)
			IDEX_preg_data1 <= 32'b0;
		else
			IDEX_preg_data1 <= register_bank[rs1_ID];
		
		if(rs2_ID == 5'b0)
			IDEX_preg_data2 <= 32'b0;
		else
			IDEX_preg_data2 <= register_bank[rs2_ID];
	end	
end

//END ID STAGE-----------------------------------------------------------------------------

//EX STAGE---------------------------------------------------------------------------------
hazard_detection_unit HZRD_DET_UNIT (.rs1(rs1_ID), .rs2(rs2_ID), .idex_rd(rd_EX), .idex_mem(L), .id_mux(mux_ctrl_ID), .ifid_write_en(IFID_preg_wen));

//assign fields
assign wb_EX    = IDEX_preg_wb;
assign mem_EX   = IDEX_preg_mem;
assign ex_EX    = IDEX_preg_ex;
assign pc_EX    = IDEX_preg_pc;
assign data1_EX = IDEX_preg_data1;
assign data2_EX = IDEX_preg_data2;
assign rs1_EX   = IDEX_preg_rs1; 
assign rs2_EX   = IDEX_preg_rs2;
assign rd_EX    = IDEX_preg_rd;
assign imm_EX   = IDEX_preg_imm;
//assign nets
assign mux1_ctrl_EX = ex_EX[4];
assign mux3_ctrl_EX = ex_EX[5];
assign mux5_ctrl_EX = ex_EX[6];
assign alu_ctrl     = ex_EX[3:0];
assign J            = ex_EX[7]; //jump
assign B            = ex_EX[8]; //branch
assign L            = (!wb_EX & mem_EX[5:4] == 2'b1) ? 1'b1 : 1'b0; //load
//muxes
assign mux1_o_EX = mux1_ctrl_EX ? pc_EX : mux2_o_EX;
assign mux2_o_EX = mux2_ctrl_EX == 2'b10 ? aluout_MEM
				 : mux2_ctrl_EX == 2'b01 ? memout_WB
				 : data1_EX;
assign mux3_o_EX = mux3_ctrl_EX ? imm_EX : mux4_o_EX;
assign mux4_o_EX = mux4_ctrl_EX == 2'b10 ? data2_EX 
				 : mux4_ctrl_EX == 2'b01 ? memout_WB 
				 : aluout_MEM;
assign mux5_o_EX = mux5_ctrl_EX ? pc_EX	 : mux2_o_EX;


assign wen0_o       = mem_EX[0];
assign ls_length_r  = mem_EX[2:1];
assign wmask0_o     = ls_length_r == 2'b0 ? 4'b0001
					: ls_length_r == 2'b1 ? 4'b0011
					: 4'b1111;
//instantiate the forwarding unit.
forwarding_unit FWD_UNIT(.rs1(rs1_EX), .rs2(rs2_EX), .exmem_rd(rd_MEM), .memwb_rd(rd_WB), .exmem_wb(wb_MEM), .memwb_wb(wb_WB), .mux1_ctrl(mux2_ctrl_EX), .mux2_ctrl(mux4_ctrl_EX));
//instantiate the ALU
ALU ALU (.src1(mux1_o_EX), .src2(mux3_o_EX), .func(alu_ctrl), .alu_out(aluout_EX));

//branch logic and address calculation
assign muxpc_ctrl  = ~(J | (B & aluout_EX[0]));
assign addr_cal_o  = mux5_o_EX + imm_EX;
//outputs. they are registered within the memory.
assign data_addr_o = aluout_EX[10:0];
assign data_o	   = mux4_o_EX;

always @(posedge clk_i or negedge reset_i) //clock the outputs to the pipeline register
begin
	if(!reset_i)
		{EXMEM_preg_wb, EXMEM_preg_mem, EXMEM_preg_aluout, EXMEM_preg_data2, EXMEM_preg_rd, EXMEM_preg_imm} <= {7'b1000001,101'b0};

	else
	begin
		EXMEM_preg_imm    <= imm_EX;
		EXMEM_preg_rd     <= rd_EX;
		EXMEM_preg_data2  <= mux4_o_EX;
		EXMEM_preg_aluout <= aluout_EX;
		EXMEM_preg_mem    <= mem_EX;
		EXMEM_preg_wb     <= wb_EX;
	end
end 

//END EX STAGE-----------------------------------------------------------------------------

//MEM STAGE---------------------------------------------------------------------------------
//assign fields
assign wb_MEM 	  = EXMEM_preg_wb;
assign mem_MEM 	  = EXMEM_preg_mem;
assign aluout_MEM = EXMEM_preg_aluout;
assign data2_MEM  = EXMEM_preg_data2;
assign rd_MEM 	  = EXMEM_preg_rd;
assign imm_MEM 	  = EXMEM_preg_imm;
//assign nets
assign wen_MEM      = mem_MEM[0];
assign ls_length    = mem_MEM[2:1];
assign l_sign       = mem_MEM[3];
assign mux_ctrl_MEM = mem_MEM[5:4];

always @(posedge clk_i or negedge reset_i)
begin
	if(!reset_i)
		{MEMWB_preg_wb, MEMWB_preg_memout, MEMWB_preg_rd} <= {1'b1, 37'b0}; //reset pipeline register

	else
	begin
	if(wen_MEM) //not a store instruction
	begin
		if(mux_ctrl_MEM == 2'b0)
			MEMWB_preg_memout <= aluout_MEM;
			
		else if(mux_ctrl_MEM == 2'b1) //load instruction
		begin
			if(ls_length == 2'b0)
			begin
				if(l_sign == 2'b1) //signed load, perform sign extension
					MEMWB_preg_memout <= { {24{data_i[7]}}, data_i[7:0] };
				else
					MEMWB_preg_memout <= { 24'b0, data_i[7:0] };
			end
			else if(ls_length == 2'b1)
			begin
				if(l_sign == 2'b1) //signed load, perform sign extension
					MEMWB_preg_memout <= { {16{data_i[15]}}, data_i[15:0] };
				else
					MEMWB_preg_memout <= { 16'b0, data_i[15:0] };			
			end
			else
				MEMWB_preg_memout <= { data_i };	
		end
		
		else
			MEMWB_preg_memout <= imm_MEM;
			
	end

	MEMWB_preg_wb <= wb_MEM;
	MEMWB_preg_rd <= rd_MEM;
	end
end
//END MEM STAGE-----------------------------------------------------------------------------

//WB STAGE---------------------------------------------------------------------------------
//assign nets
assign wb_WB 	 = MEMWB_preg_wb;
assign memout_WB = MEMWB_preg_memout;
assign rd_WB 	 = MEMWB_preg_rd;
//END WB STAGE-----------------------------------------------------------------------------
endmodule



