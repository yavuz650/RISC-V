`timescale 1ns/10ps

module core(input reset_i,
	    	input clk_i,
	    	input [31:0] instr_i,
	    	input [31:0] data_i,
	    	
	    	output [3:0] wmask0_o,
	    	output 		 wen0_o,
	    	output [10:0] instr_addr_o,
	    	output [10:0] data_addr_o,
	    	output [31:0] data_o); //active-low reset. all write_enable signals are also active-low.
				  
	  //sram_1rw1r_32_512_8_freepdk45 memory(.clk0(clk_i), .csb0(!reset_i), .web0(wen_MEM_r), .wmask0(wmask0), .addr0(aluout_EX[10:2]), .din0(mux4_o_EX), .dout0(memout_MEM), //port 1 is for data memory
	 						//			   .clk1(clk_i), .csb1(1'b0), .web1(wen_i), .wmask1(4'b1111), .addr1(mux_addr_o2[10:2]), .din1(instr_i), .dout1(instr_IF)); //port 2 is for instruction memory

//IF signals------------------------------------------------------------
wire [31:0] muxpc_o, plus4_o; //pc-mux output, pc+4 output.
wire [31:0] addr_cal_o; // address calculation output
wire 		muxpc_ctrl; //pc-mux control signal. it is also controls the flush mechanism.
reg [31:0] 	pc_o; //pc out
wire [10:0] mux_addr_o, mux_load_o, mux_addr_o2;
wire [31:0] instr_IF;
wire 		IFID_preg_wen; //IF/ID pipeline register write enable signal.
reg [63:0] 	IFID_preg; //IF/ID pipeline register.
//----------------------------------------------------------------------
//ID signals
wire [4:0] 	 rs1_ID, rs2_ID, rd_ID; //register addresses
wire [31:0]	 data1_ID, data2_ID;
wire [14:0]  ctrl_unit_i; //control unit input
wire [29:0]  imm_dec_i; //immediate decoder input
wire [15:0]  ctrl_unit_o; //control unit output
wire [31:0]  imm_dec_o, pc_ID; //immediate decoder output, pc value
wire 		 mux_ctrl_ID; //control signal for all three muxes
wire 		 mux1_o_ID; //WB field
wire [5:0] 	 mux2_o_ID; //MEM field
wire [8:0] 	 mux3_o_ID; //EX field
reg  [158:0] IDEX_preg; //ID/EX pipeline register.

reg [31:0] register_bank [31:0]; //32x32 register file
//----------------------------------------------------------------------
//EX signals------------------------------------------------------------
wire 		wb_EX;
wire [5:0] 	mem_EX;
wire [8:0] 	ex_EX;
wire [31:0] pc_EX, data1_EX, data2_EX, imm_EX;
wire [4:0] 	rs1_EX, rs2_EX, rd_EX;
wire 		mux1_ctrl_EX, mux3_ctrl_EX, mux5_ctrl_EX;
wire [1:0] 	mux2_ctrl_EX, mux4_ctrl_EX;
wire [31:0] mux1_o_EX, mux2_o_EX, mux3_o_EX, mux4_o_EX, mux5_o_EX;
wire [3:0] 	alu_ctrl;
wire [31:0] aluout_EX;
wire 		J, B, L; //jump, branch, load
reg [107:0] EXMEM_preg; //EX/MEM pipeline register
//----------------------------------------------------------------------
//MEM signals-----------------------------------------------------------
wire 		wb_MEM;
wire [5:0] 	mem_MEM;
wire [31:0] aluout_MEM, data2_MEM;
wire [4:0] 	rd_MEM;
wire [31:0] imm_MEM;
wire [31:0] memout_MEM;
//internal nets
wire 	   wen_MEM;
wire	   wen_MEM_r;
wire [1:0] ls_length, ls_length_r;
wire 	   l_sign;
wire [1:0] mux_ctrl_MEM;
reg [37:0] MEMWB_preg;
wire [3:0] wmask0;
//----------------------------------------------------------------------
//WB signals------------------------------------------------------------
wire [4:0] 	rd_WB;
wire 		wb_WB;
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
		IFID_preg[63:0] <= 64'h13; //nop instruction addi x0,x0,0
	end
	
	else if(!muxpc_ctrl) //branch taken. next address comes from the address calculation output.
	begin
		IFID_preg[31:0] <= 32'h13; //flush the register
		IFID_preg[63:32] <= addr_cal_o;
		pc_o <= addr_cal_o + 32'd4;
	end
		
	else
	begin
		if(!IFID_preg_wen) //stall the pipe if necessary
		begin
			if(pc_o == 32'h0)
				IFID_preg[31:0] <= 32'h13;
			else
				IFID_preg[31:0]	 <= instr_i;
				
			IFID_preg[63:32] <= pc_o - 32'd4 ;
			pc_o <= pc_o + 32'd4;
		end
	end
end
//END IF STAGE-----------------------------------------------------------------------------

//ID STAGE---------------------------------------------------------------------------------
//assign nets
assign rs1_ID 		= IFID_preg[19:15];
assign rs2_ID		= IFID_preg[24:20];
assign rd_ID        = IFID_preg[11:7];
assign pc_ID 		= IFID_preg[63:32];
assign imm_dec_i    = IFID_preg[31:2];
assign ctrl_unit_i  = {IFID_preg[31:25], IFID_preg[14:12], IFID_preg[6:2]};
assign mux1_o_ID	= mux_ctrl_ID ? 1'b1 : ctrl_unit_o[15];
assign mux2_o_ID	= mux_ctrl_ID ? 6'b1 : ctrl_unit_o[14:9];
assign mux3_o_ID	= mux_ctrl_ID ? 9'b0 : ctrl_unit_o[8:0];

control_unit  		  CTRL_UNIT 	(.control_in(ctrl_unit_i), .fields_out(ctrl_unit_o));
imm_decoder   		  IMM_DEC   	(.instr_in(imm_dec_i), .imm_out(imm_dec_o));

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
		IDEX_preg[158:0] <= {7'b1000001,152'b0};
		
	else if(!muxpc_ctrl) //flush the pipe
		IDEX_preg[158:0] <= {7'b1000001,152'b0};
	
	else
	begin
		IDEX_preg[31:0]    <= imm_dec_o;
		IDEX_preg[36:32]   <= rd_ID;
		IDEX_preg[41:37]   <= rs2_ID;
		IDEX_preg[46:42]   <= rs1_ID;
		IDEX_preg[142:111] <= pc_ID;
		IDEX_preg[158]	   <= mux1_o_ID; 
		IDEX_preg[157:152] <= mux2_o_ID;
		IDEX_preg[151:143] <= mux3_o_ID;
		
		if(rs1_ID == 5'b0)
			IDEX_preg[110:79] <= 32'b0;
		else
			IDEX_preg[110:79] <= register_bank[rs1_ID];
		
		if(rs2_ID == 5'b0)
			IDEX_preg[78:47] <= 32'b0;
		else
			IDEX_preg[78:47] <= register_bank[rs2_ID];
	end	
end

//END ID STAGE-----------------------------------------------------------------------------

//EX STAGE---------------------------------------------------------------------------------
hazard_detection_unit HZRD_DET_UNIT (.rs1(rs1_ID), .rs2(rs2_ID), .idex_rd(rd_EX), .idex_mem(L), .id_mux(mux_ctrl_ID), .ifid_write_en(IFID_preg_wen));

//assign fields
assign wb_EX    = IDEX_preg[158];
assign mem_EX   = IDEX_preg[157:152];
assign ex_EX    = IDEX_preg[151:143];
assign pc_EX    = IDEX_preg[142:111];
assign data1_EX = IDEX_preg[110:79];
assign data2_EX = IDEX_preg[78:47];
assign rs1_EX   = IDEX_preg[46:42]; 
assign rs2_EX   = IDEX_preg[41:37];
assign rd_EX    = IDEX_preg[36:32];
assign imm_EX   = IDEX_preg[31:0];
//assign nets
assign mux1_ctrl_EX = ex_EX[4];
assign mux3_ctrl_EX = ex_EX[5];
assign mux5_ctrl_EX = ex_EX[6];
assign alu_ctrl  	= ex_EX[3:0];
assign J 		 	= ex_EX[7]; //jump
assign B 		 	= ex_EX[8]; //branch
assign L 		 	= (!wb_EX & mem_EX[5:4] == 2'b1) ? 1'b1 : 1'b0; //load
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


assign wen0_o	 	= mem_EX[0];
assign ls_length_r 	= mem_EX[2:1];
assign wmask0_o		= ls_length_r == 2'b0 ? 4'b0001
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
		EXMEM_preg[107:0] <= {7'b1000001,101'b0};

	else
	begin
		EXMEM_preg[31:0] 	<= imm_EX;
		EXMEM_preg[36:32] 	<= rd_EX;
		EXMEM_preg[68:37] 	<= mux4_o_EX;
		EXMEM_preg[100:69] 	<= aluout_EX;
		EXMEM_preg[106:101] <= mem_EX;
		EXMEM_preg[107] 	<= wb_EX;
	end
end 

//END EX STAGE-----------------------------------------------------------------------------

//MEM STAGE---------------------------------------------------------------------------------
//assign fields
assign wb_MEM 	  = EXMEM_preg[107];
assign mem_MEM 	  = EXMEM_preg[106:101];
assign aluout_MEM = EXMEM_preg[100:69];
assign data2_MEM  = EXMEM_preg[68:37];
assign rd_MEM 	  = EXMEM_preg[36:32];
assign imm_MEM 	  = EXMEM_preg[31:0];
//assign nets
assign wen_MEM	  = mem_MEM[0];
assign ls_length 	= mem_MEM[2:1];
assign l_sign	    = mem_MEM[3];
assign mux_ctrl_MEM = mem_MEM[5:4];

always @(posedge clk_i or negedge reset_i)
begin
	if(!reset_i)
		MEMWB_preg <= {1'b1, 37'b0}; //reset pipeline register

	else
	begin
	if(wen_MEM) //not a store instruction
	begin
		if(mux_ctrl_MEM == 2'b0)
			MEMWB_preg[36:5] <= aluout_MEM;
			
		else if(mux_ctrl_MEM == 2'b1) //load instruction
		begin
			if(ls_length == 2'b0)
			begin
				if(l_sign == 2'b1) //signed load, perform sign extension
					MEMWB_preg[36:5] <= { {24{data_i[7]}}, data_i[7:0] };
				else
					MEMWB_preg[36:5] <= { 24'b0, data_i[7:0] };
			end
			else if(ls_length == 2'b1)
			begin
				if(l_sign == 2'b1) //signed load, perform sign extension
					MEMWB_preg[36:5] <= { {16{data_i[15]}}, data_i[15:0] };
				else
					MEMWB_preg[36:5] <= { 16'b0, data_i[15:0] };			
			end
			else
				MEMWB_preg[36:5] <= { data_i };	
		end
		
		else
			MEMWB_preg[36:5] <= imm_MEM;
			
	end

	MEMWB_preg[37] 	<= wb_MEM;
	MEMWB_preg[4:0] <= rd_MEM;
	end
end
//END MEM STAGE-----------------------------------------------------------------------------

//WB STAGE---------------------------------------------------------------------------------
//assign nets
assign wb_WB 	 = MEMWB_preg[37];
assign memout_WB = MEMWB_preg[36:5];
assign rd_WB 	 = MEMWB_preg[4:0];
//END WB STAGE-----------------------------------------------------------------------------
endmodule



