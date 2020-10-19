`timescale 1ns/10ps

module top_module(input reset_i, clk_i); //active-low reset. all write_enable signals are also active-low.

//IF signals------------------------------------------------------------
reg [7:0] 	memory [575:0]; //includes both the data and the instruction memory. the two regions are seperated by their respective address spaces. 
wire [31:0] muxpc_o, plus4_o; //pc-mux output, pc+4 output.
wire [31:0] addr_cal_o; // address calculation output
wire 		muxpc_ctrl; //pc-mux control signal. it is also controls the flush mechanism.
reg [31:0] 	pc_o; //pc out
wire 		IFID_preg_wen; //IF/ID pipeline register write enable signal.
reg [63:0] 	IFID_preg; //IF/ID pipeline register.
//----------------------------------------------------------------------
//ID signals
wire [4:0] 	 rs1_ID, rs2_ID, rd_ID; //register addresses
wire [31:0]	 data1_ID, data2_ID;
wire [14:0]  ctrl_unit_i; //control unit input
wire [29:0]  imm_dec_i; //immediate decoder input
wire [15:0]  ctrl_unit_o; //control unit output
wire [31:0]  imm_dec_o, pc_ID; //immediate decoder output, register file outputs, pc value
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
//data memory
//internal nets
wire 	   wen_MEM;
wire [1:0] ls_length;
wire 	   l_sign;
wire [1:0] mux_ctrl_MEM;
reg [37:0] MEMWB_preg;
//----------------------------------------------------------------------
//WB signals------------------------------------------------------------
wire [4:0] 	rd_WB;
wire 		wb_WB;
wire [31:0] memout_WB;
//----------------------------------------------------------------------

//IF STAGE---------------------------------------------------------------------------------
//assign muxpc_o = muxpc_ctrl ? plus4_o : addr_cal_o; pc-mux
//assign plus4_o = pc_o + 32'd4; pc+4

always @(posedge clk_i or negedge reset_i) 
begin
	if(!reset_i)
	begin
		//reset pc to wherever.
		pc_o <= 32'b0;
		IFID_preg[63:0] <= 64'h13; //nop instruction addi x0,x0,0
	end
	
	else if(!muxpc_ctrl) //branch taken. next address comes from the address calculation output.
	begin
		IFID_preg[31:0] <= {memory[addr_cal_o[8:0]+9'd3], memory[addr_cal_o[8:0]+9'd2], memory[addr_cal_o[8:0]+9'd1], memory[addr_cal_o[8:0]]};
		IFID_preg[63:32] <= addr_cal_o;
		pc_o <= addr_cal_o + 32'd4;
	end
		
	else
	begin
		if(!IFID_preg_wen) //stall the pipe if necessary
		begin
			IFID_preg[31:0]	 <= {memory[pc_o[8:0]+9'd3], memory[pc_o[8:0]+9'd2], memory[pc_o[8:0]+9'd1], memory[pc_o[8:0]]};
			IFID_preg[63:32] <= pc_o;
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

//instantiate the forwarding unit.
forwarding_unit FWD_UNIT(.rs1(rs1_EX), .rs2(rs2_EX), .exmem_rd(rd_MEM), .memwb_rd(rd_WB), .exmem_wb(wb_MEM), .memwb_wb(wb_WB), .mux1_ctrl(mux2_ctrl_EX), .mux2_ctrl(mux4_ctrl_EX));
//instantiate the ALU
ALU ALU (.src1(mux1_o_EX), .src2(mux3_o_EX), .func(alu_ctrl), .alu_out(aluout_EX));

//branch logic and address calculation
assign muxpc_ctrl = ~(J | (B & aluout_EX[0]));
assign addr_cal_o = mux5_o_EX + imm_EX;


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
assign wen_MEM 		= mem_MEM[0];
assign ls_length 	= mem_MEM[2:1];
assign l_sign	 	= mem_MEM[3];
assign mux_ctrl_MEM = mem_MEM[5:4];

always @(posedge clk_i or negedge reset_i)
begin
	if(!reset_i)
	begin
		//initialize instruction memory...
memory[0] <= 8'h13; memory[1] <= 8'h01; memory[2] <= 8'h00; memory[3] <= 8'h24; 
memory[4] <= 8'h33; memory[5] <= 8'h04; memory[6] <= 8'h01; memory[7] <= 8'h00; 
memory[8] <= 8'h6F; memory[9] <= 8'h00; memory[10] <= 8'h80; memory[11] <= 8'h0F; 
memory[12] <= 8'h13; memory[13] <= 8'h01; memory[14] <= 8'h01; memory[15] <= 8'hFD; 
memory[16] <= 8'h23; memory[17] <= 8'h26; memory[18] <= 8'h81; memory[19] <= 8'h02; 
memory[20] <= 8'h13; memory[21] <= 8'h04; memory[22] <= 8'h01; memory[23] <= 8'h03; 
memory[24] <= 8'h23; memory[25] <= 8'h2E; memory[26] <= 8'hA4; memory[27] <= 8'hFC; 
memory[28] <= 8'h23; memory[29] <= 8'h2C; memory[30] <= 8'hB4; memory[31] <= 8'hFC; 
memory[32] <= 8'h23; memory[33] <= 8'h26; memory[34] <= 8'h04; memory[35] <= 8'hFE; 
memory[36] <= 8'h23; memory[37] <= 8'h24; memory[38] <= 8'h04; memory[39] <= 8'hFE; 
memory[40] <= 8'h6F; memory[41] <= 8'h00; memory[42] <= 8'hC0; memory[43] <= 8'h0A; 
memory[44] <= 8'h83; memory[45] <= 8'h27; memory[46] <= 8'h84; memory[47] <= 8'hFE; 
memory[48] <= 8'h93; memory[49] <= 8'h97; memory[50] <= 8'h27; memory[51] <= 8'h00; 
memory[52] <= 8'h03; memory[53] <= 8'h27; memory[54] <= 8'hC4; memory[55] <= 8'hFD; 
memory[56] <= 8'hB3; memory[57] <= 8'h07; memory[58] <= 8'hF7; memory[59] <= 8'h00; 
memory[60] <= 8'h03; memory[61] <= 8'hA7; memory[62] <= 8'h07; memory[63] <= 8'h00; 
memory[64] <= 8'h83; memory[65] <= 8'h27; memory[66] <= 8'h84; memory[67] <= 8'hFE; 
memory[68] <= 8'h93; memory[69] <= 8'h87; memory[70] <= 8'h17; memory[71] <= 8'h00; 
memory[72] <= 8'h93; memory[73] <= 8'h97; memory[74] <= 8'h27; memory[75] <= 8'h00; 
memory[76] <= 8'h83; memory[77] <= 8'h26; memory[78] <= 8'hC4; memory[79] <= 8'hFD; 
memory[80] <= 8'hB3; memory[81] <= 8'h87; memory[82] <= 8'hF6; memory[83] <= 8'h00; 
memory[84] <= 8'h83; memory[85] <= 8'hA7; memory[86] <= 8'h07; memory[87] <= 8'h00; 
memory[88] <= 8'h63; memory[89] <= 8'hD8; memory[90] <= 8'hE7; memory[91] <= 8'h06; 
memory[92] <= 8'h83; memory[93] <= 8'h27; memory[94] <= 8'h84; memory[95] <= 8'hFE; 
memory[96] <= 8'h93; memory[97] <= 8'h97; memory[98] <= 8'h27; memory[99] <= 8'h00; 
memory[100] <= 8'h03; memory[101] <= 8'h27; memory[102] <= 8'hC4; memory[103] <= 8'hFD; 
memory[104] <= 8'hB3; memory[105] <= 8'h07; memory[106] <= 8'hF7; memory[107] <= 8'h00; 
memory[108] <= 8'h83; memory[109] <= 8'hA7; memory[110] <= 8'h07; memory[111] <= 8'h00; 
memory[112] <= 8'h23; memory[113] <= 8'h22; memory[114] <= 8'hF4; memory[115] <= 8'hFE; 
memory[116] <= 8'h83; memory[117] <= 8'h27; memory[118] <= 8'h84; memory[119] <= 8'hFE; 
memory[120] <= 8'h93; memory[121] <= 8'h87; memory[122] <= 8'h17; memory[123] <= 8'h00; 
memory[124] <= 8'h93; memory[125] <= 8'h97; memory[126] <= 8'h27; memory[127] <= 8'h00; 
memory[128] <= 8'h03; memory[129] <= 8'h27; memory[130] <= 8'hC4; memory[131] <= 8'hFD; 
memory[132] <= 8'h33; memory[133] <= 8'h07; memory[134] <= 8'hF7; memory[135] <= 8'h00; 
memory[136] <= 8'h83; memory[137] <= 8'h27; memory[138] <= 8'h84; memory[139] <= 8'hFE; 
memory[140] <= 8'h93; memory[141] <= 8'h97; memory[142] <= 8'h27; memory[143] <= 8'h00; 
memory[144] <= 8'h83; memory[145] <= 8'h26; memory[146] <= 8'hC4; memory[147] <= 8'hFD; 
memory[148] <= 8'hB3; memory[149] <= 8'h87; memory[150] <= 8'hF6; memory[151] <= 8'h00; 
memory[152] <= 8'h03; memory[153] <= 8'h27; memory[154] <= 8'h07; memory[155] <= 8'h00; 
memory[156] <= 8'h23; memory[157] <= 8'hA0; memory[158] <= 8'hE7; memory[159] <= 8'h00; 
memory[160] <= 8'h83; memory[161] <= 8'h27; memory[162] <= 8'h84; memory[163] <= 8'hFE; 
memory[164] <= 8'h93; memory[165] <= 8'h87; memory[166] <= 8'h17; memory[167] <= 8'h00; 
memory[168] <= 8'h93; memory[169] <= 8'h97; memory[170] <= 8'h27; memory[171] <= 8'h00; 
memory[172] <= 8'h03; memory[173] <= 8'h27; memory[174] <= 8'hC4; memory[175] <= 8'hFD; 
memory[176] <= 8'hB3; memory[177] <= 8'h07; memory[178] <= 8'hF7; memory[179] <= 8'h00; 
memory[180] <= 8'h03; memory[181] <= 8'h27; memory[182] <= 8'h44; memory[183] <= 8'hFE; 
memory[184] <= 8'h23; memory[185] <= 8'hA0; memory[186] <= 8'hE7; memory[187] <= 8'h00; 
memory[188] <= 8'h83; memory[189] <= 8'h27; memory[190] <= 8'hC4; memory[191] <= 8'hFE; 
memory[192] <= 8'h93; memory[193] <= 8'h87; memory[194] <= 8'h17; memory[195] <= 8'h00; 
memory[196] <= 8'h23; memory[197] <= 8'h26; memory[198] <= 8'hF4; memory[199] <= 8'hFE; 
memory[200] <= 8'h83; memory[201] <= 8'h27; memory[202] <= 8'h84; memory[203] <= 8'hFE; 
memory[204] <= 8'h93; memory[205] <= 8'h87; memory[206] <= 8'h17; memory[207] <= 8'h00; 
memory[208] <= 8'h23; memory[209] <= 8'h24; memory[210] <= 8'hF4; memory[211] <= 8'hFE; 
memory[212] <= 8'h83; memory[213] <= 8'h27; memory[214] <= 8'h84; memory[215] <= 8'hFD; 
memory[216] <= 8'h93; memory[217] <= 8'h87; memory[218] <= 8'hF7; memory[219] <= 8'hFF; 
memory[220] <= 8'h03; memory[221] <= 8'h27; memory[222] <= 8'h84; memory[223] <= 8'hFE; 
memory[224] <= 8'hE3; memory[225] <= 8'h46; memory[226] <= 8'hF7; memory[227] <= 8'hF4; 
memory[228] <= 8'h83; memory[229] <= 8'h27; memory[230] <= 8'hC4; memory[231] <= 8'hFE; 
memory[232] <= 8'hE3; memory[233] <= 8'h9C; memory[234] <= 8'h07; memory[235] <= 8'hF2; 
memory[236] <= 8'h13; memory[237] <= 8'h00; memory[238] <= 8'h00; memory[239] <= 8'h00; 
memory[240] <= 8'h13; memory[241] <= 8'h00; memory[242] <= 8'h00; memory[243] <= 8'h00; 
memory[244] <= 8'h03; memory[245] <= 8'h24; memory[246] <= 8'hC1; memory[247] <= 8'h02; 
memory[248] <= 8'h13; memory[249] <= 8'h01; memory[250] <= 8'h01; memory[251] <= 8'h03; 
memory[252] <= 8'h67; memory[253] <= 8'h80; memory[254] <= 8'h00; memory[255] <= 8'h00; 
memory[256] <= 8'h13; memory[257] <= 8'h01; memory[258] <= 8'h01; memory[259] <= 8'hFD; 
memory[260] <= 8'h23; memory[261] <= 8'h26; memory[262] <= 8'h11; memory[263] <= 8'h02; 
memory[264] <= 8'h23; memory[265] <= 8'h24; memory[266] <= 8'h81; memory[267] <= 8'h02; 
memory[268] <= 8'h13; memory[269] <= 8'h04; memory[270] <= 8'h01; memory[271] <= 8'h03; 
memory[272] <= 8'h93; memory[273] <= 8'h07; memory[274] <= 8'h40; memory[275] <= 8'h17; 
memory[276] <= 8'h03; memory[277] <= 8'hA8; memory[278] <= 8'h07; memory[279] <= 8'h00; 
memory[280] <= 8'h03; memory[281] <= 8'hA5; memory[282] <= 8'h47; memory[283] <= 8'h00; 
memory[284] <= 8'h83; memory[285] <= 8'hA5; memory[286] <= 8'h87; memory[287] <= 8'h00; 
memory[288] <= 8'h03; memory[289] <= 8'hA6; memory[290] <= 8'hC7; memory[291] <= 8'h00; 
memory[292] <= 8'h83; memory[293] <= 8'hA6; memory[294] <= 8'h07; memory[295] <= 8'h01; 
memory[296] <= 8'h03; memory[297] <= 8'hA7; memory[298] <= 8'h47; memory[299] <= 8'h01; 
memory[300] <= 8'h83; memory[301] <= 8'hA7; memory[302] <= 8'h87; memory[303] <= 8'h01; 
memory[304] <= 8'h23; memory[305] <= 8'h2A; memory[306] <= 8'h04; memory[307] <= 8'hFD; 
memory[308] <= 8'h23; memory[309] <= 8'h2C; memory[310] <= 8'hA4; memory[311] <= 8'hFC; 
memory[312] <= 8'h23; memory[313] <= 8'h2E; memory[314] <= 8'hB4; memory[315] <= 8'hFC; 
memory[316] <= 8'h23; memory[317] <= 8'h20; memory[318] <= 8'hC4; memory[319] <= 8'hFE; 
memory[320] <= 8'h23; memory[321] <= 8'h22; memory[322] <= 8'hD4; memory[323] <= 8'hFE; 
memory[324] <= 8'h23; memory[325] <= 8'h24; memory[326] <= 8'hE4; memory[327] <= 8'hFE; 
memory[328] <= 8'h23; memory[329] <= 8'h26; memory[330] <= 8'hF4; memory[331] <= 8'hFE; 
memory[332] <= 8'h93; memory[333] <= 8'h07; memory[334] <= 8'h44; memory[335] <= 8'hFD; 
memory[336] <= 8'h93; memory[337] <= 8'h05; memory[338] <= 8'h70; memory[339] <= 8'h00; 
memory[340] <= 8'h13; memory[341] <= 8'h85; memory[342] <= 8'h07; memory[343] <= 8'h00; 
memory[344] <= 8'hEF; memory[345] <= 8'hF0; memory[346] <= 8'h5F; memory[347] <= 8'hEB; 
memory[348] <= 8'h93; memory[349] <= 8'h07; memory[350] <= 8'h00; memory[351] <= 8'h00; 
memory[352] <= 8'h13; memory[353] <= 8'h85; memory[354] <= 8'h07; memory[355] <= 8'h00; 
memory[356] <= 8'h83; memory[357] <= 8'h20; memory[358] <= 8'hC1; memory[359] <= 8'h02; 
memory[360] <= 8'h03; memory[361] <= 8'h24; memory[362] <= 8'h81; memory[363] <= 8'h02; 
memory[364] <= 8'h13; memory[365] <= 8'h01; memory[366] <= 8'h01; memory[367] <= 8'h03; 
memory[368] <= 8'h67; memory[369] <= 8'h80; memory[370] <= 8'h00; memory[371] <= 8'h00; 
memory[372] <= 8'hC3; memory[373] <= 8'h00; memory[374] <= 8'h00; memory[375] <= 8'h00; 
memory[376] <= 8'h0E; memory[377] <= 8'h00; memory[378] <= 8'h00; memory[379] <= 8'h00; 
memory[380] <= 8'hB0; memory[381] <= 8'h00; memory[382] <= 8'h00; memory[383] <= 8'h00; 
memory[384] <= 8'h67; memory[385] <= 8'h00; memory[386] <= 8'h00; memory[387] <= 8'h00; 
memory[388] <= 8'h36; memory[389] <= 8'h00; memory[390] <= 8'h00; memory[391] <= 8'h00; 
memory[392] <= 8'h20; memory[393] <= 8'h00; memory[394] <= 8'h00; memory[395] <= 8'h00; 
memory[396] <= 8'h80; memory[397] <= 8'h00; memory[398] <= 8'h00; memory[399] <= 8'h00; 
		MEMWB_preg <= {1'b1, 37'b0}; //reset pipeline register
	end

	else if(!wen_MEM) //store instruction
	begin
		if(ls_length == 2'b0) //byte
			memory[aluout_MEM] <= data2_MEM[7:0];
		else if(ls_length == 2'b1) //half-word
		begin
			memory[aluout_MEM] <= data2_MEM[7:0];
			memory[aluout_MEM + 32'd1] <= data2_MEM[15:8];
		end
		else
		begin //word
			memory[aluout_MEM] <= data2_MEM[7:0];
			memory[aluout_MEM + 32'd1] <= data2_MEM[15:8];
			memory[aluout_MEM + 32'd2] <= data2_MEM[23:16];	
			memory[aluout_MEM + 32'd3] <= data2_MEM[31:24];	
		end
		
		MEMWB_preg[37] 	<= wb_MEM;
		MEMWB_preg[4:0] <= rd_MEM;		
	end
	
	else //not a store instruction
	begin
		if(mux_ctrl_MEM == 2'b0)
			MEMWB_preg[36:5] <= aluout_MEM;
			
		else if(mux_ctrl_MEM == 2'b1) //load instruction
		begin
			if(ls_length == 2'b0)
			begin
				if(l_sign == 2'b1) //signed load, perform sign extension
					MEMWB_preg[36:5] <= { {24{memory[aluout_MEM][7]}}, memory[aluout_MEM] };
				else
					MEMWB_preg[36:5] <= { 24'b0, memory[aluout_MEM] };
			end
			else if(ls_length == 2'b1)
			begin
				if(l_sign == 2'b1) //signed load, perform sign extension
					MEMWB_preg[36:5] <= { {16{memory[aluout_MEM + 32'd1][7]}}, memory[aluout_MEM + 32'd1], memory[aluout_MEM] };
				else
					MEMWB_preg[36:5] <= { 16'b0, memory[aluout_MEM + 32'd1], memory[aluout_MEM] };			
			end
			else
				MEMWB_preg[36:5] <= { memory[aluout_MEM + 32'd3], memory[aluout_MEM + 32'd2], memory[aluout_MEM + 32'd1], memory[aluout_MEM] };	
		end
		
		else
			MEMWB_preg[36:5] <= imm_MEM;

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



