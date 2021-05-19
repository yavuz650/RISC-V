`timescale 1ns/1ps

module core(input hreset_i, sreset_i,  //active-low resets. all write_enable signals are also active-low.
                                       //different reset signals set mcause to different values.
            input clk_i,

            input  [31:0] data_i,       //data memory input
            output [3:0]  data_wmask_o, //data memory mask output
            output        data_wen_o,   //data memory write enable output
            output [31:0] data_addr_o,  //data memory address output
            output [31:0] data_o,       //data memory data output
            output        data_req_o,   //data access request output. driven high when a store/load is carried out
            input         data_err_i,   //data access error input. this will trigger a store/load access fault.

            input  [31:0] instr_i,      //instruction input
            output [31:0] instr_addr_o, //instruction address output
            input         instr_access_fault_i, //instruction access fault exception signal

            input         meip_i, mtip_i, msip_i, //interrupts
            input  [15:0] fast_irq_i,

            output irq_ack_o);     //interrupt acknowledge signal. driven high for one cycle when an external interrupt is handled.

parameter reset_vector = 32'h0; //pc is set to this address when a reset occurs.
wire reset_i;

//IF SIGNALS--------IF SIGNALS--------IF SIGNALS--------IF SIGNALS--------IF SIGNALS--------IF SIGNALS--------IF SIGNALS
//mux signals
wire        mux1_ctrl_IF, mux2_ctrl_IF, mux3_ctrl_IF, mux4_ctrl_IF; //mux control signals
wire [31:0] mux1_o_IF, mux2_o_IF, mux3_o_IF, mux4_o_IF; //mux outputs
//PC
wire [31:0] pc_i; //pc input
reg  [31:0] pc_o; //pc output

wire hazard_stall_IF; //stalls the IF stage when it is high. it is driven by the hazard detection unit.
//pipeline registers
reg [31:0] IFID_preg_instr;
reg [31:0] IFID_preg_pc;
reg        IFID_preg_dummy; //indicates if the instruction in the ID stage is dummy, i.e. a flushed instruction, nop.
//END IF SIGNALS--------END IF SIGNALS--------END IF SIGNALS--------END IF SIGNALS--------END IF SIGNALS--------END IF SIGNALS

//ID SIGNALS--------ID SIGNALS--------ID SIGNALS--------ID SIGNALS--------ID SIGNALS--------ID SIGNALS--------ID SIGNALS
wire [4:0]  rs1_ID, rs2_ID, rd_ID; //register addresses
wire [31:0] data1_ID, data2_ID;
wire [11:0] csr_addr_ID; //CSR register address
wire        mret_ID; //driven high when the instruction in ID stage is MRET.
wire        hazard_stall_ID;
//control unit outputs
wire ctrl_unit_muldiv_start;
wire ctrl_unit_muldiv_sel;
wire [1:0] ctrl_unit_op_mul;
wire [1:0] ctrl_unit_op_div;

wire [3:0] ctrl_unit_alu_func1;
wire [1:0] ctrl_unit_alu_func2;
wire       ctrl_unit_ex_mux5, ctrl_unit_ex_mux7;
wire [1:0] ctrl_unit_ex_mux1, ctrl_unit_ex_mux3, ctrl_unit_ex_mux6;
wire       ctrl_unit_B, ctrl_unit_J;
wire [1:0] ctrl_unit_mem_len;
wire       ctrl_unit_mem_wen, ctrl_unit_wb_rf_wen, ctrl_unit_wb_csr_wen;
wire [1:0] ctrl_unit_wb_mux;
wire       ctrl_unit_wb_sign;
wire       ctrl_unit_illegal_instr, ctrl_unit_ecall, ctrl_unit_ebreak;
//mux signals
wire        mux_ctrl_ID; //control signal for all three muxes
wire [6:0]  mux1_o_ID; //WB field
wire [2:0]  mux2_o_ID; //MEM field
wire [21:0] mux3_o_ID; //EX field

wire [29:0] imm_dec_i; //immediate decoder input
wire [31:0] imm_dec_o; //immediate decoder output
wire [31:0] pc_ID; //pc value

//pipeline registers
reg [31:0] IDEX_preg_imm;
reg [4:0]  IDEX_preg_rd, IDEX_preg_rs2, IDEX_preg_rs1;
reg [31:0] IDEX_preg_data2, IDEX_preg_data1;
reg [31:0] IDEX_preg_pc;
reg [21:0] IDEX_preg_ex;
reg [2:0]  IDEX_preg_mem;
reg [6:0]  IDEX_preg_wb;
reg [11:0] IDEX_preg_csr_addr;
reg        IDEX_preg_dummy; //indicates if the instruction in the EX stage is dummy, i.e. a flushed instruction, nop.
reg        IDEX_preg_mret; //driven high when the instruction in EX stage is MRET.
reg        IDEX_preg_misaligned; //driven high when the second part of a misaligned access is being executed in EX stage.

reg [31:0] register_bank [31:0]; //32x32 register file
//END ID SIGNALS--------END ID SIGNALS--------END ID SIGNALS--------END ID SIGNALS--------END ID SIGNALS--------END ID SIGNALS

//EX SIGNALS--------EX SIGNALS--------EX SIGNALS--------EX SIGNALS--------EX SIGNALS--------EX SIGNALS--------EX SIGNALS
wire muldiv_start;
wire muldiv_sel;
wire [1:0] op_mul, op_div;
wire muldiv_done_EX;
wire [31:0] R_EX;
wire muldiv_stall_EX;

//signals from previous stage
wire [6:0]  wb_EX;
wire [2:0]  mem_EX;
wire [21:0] ex_EX;
wire [31:0] pc_EX, data1_EX, data2_EX, imm_EX;
wire [4:0]  rs1_EX, rs2_EX, rd_EX;
wire [11:0] csr_addr_EX;
//mux signals
wire [1:0]  mux1_ctrl_EX, mux2_ctrl_EX, mux3_ctrl_EX, mux4_ctrl_EX, mux6_ctrl_EX, mux8_ctrl_EX;
wire        mux5_ctrl_EX, mux7_ctrl_EX;
wire [31:0] mux1_o_EX, mux2_o_EX, mux3_o_EX, mux4_o_EX, mux5_o_EX, mux6_o_EX, mux7_o_EX, mux8_o_EX;
//ALU signals
wire [3:0]  alu_func1;
wire [1:0]  alu_func2;
wire [31:0] aluout_EX;

wire        J, B, L; //jump, branch, load
wire        misaligned_access; //driven high when the first part of a misaligned access is being executed.
wire        mem_wen_EX;
wire [1:0]  mem_length_EX;
wire        instr_addr_misaligned; //driven high when the calculated instruction address is misaligned, which causes an exception.
wire        hazard_stall; //output of the hazard detection unit.
//branch signals
wire [31:0] branch_target_addr; //branch target address, calculated in EX stage.
wire [31:0] branch_addr_calc; //intermediate value during address calculation.
wire        take_branch; //branch decision signal. 1 if the branch is taken, 0 otherwise.

//pipeline registers
reg [31:0] EXMEM_preg_imm;
reg [4:0]  EXMEM_preg_rd;
reg [31:0] EXMEM_preg_data2;
reg [31:0] EXMEM_preg_aluout;
reg [31:0] EXMEM_preg_pc;
reg [11:0] EXMEM_preg_csr_addr;
reg [2:0]  EXMEM_preg_mem;
reg [6:0]  EXMEM_preg_wb;
reg        EXMEM_preg_dummy; //indicates if the instruction in MEM stage is dummy, i.e. a flushed instruction, nop.
reg        EXMEM_preg_mret; //driven high when the instruction in MEM stage is MRET.
reg        EXMEM_preg_misaligned; //driven high when the instruction in MEM stage is a misaligned access.
reg [1:0]  EXMEM_preg_addr_bits; //two least-significant bits of data address.
//END EX SIGNALS--------END EX SIGNALS--------END EX SIGNALS--------END EX SIGNALS--------END EX SIGNALS--------END EX SIGNALS

//MEM SIGNALS--------MEM SIGNALS--------MEM SIGNALS--------MEM SIGNALS--------MEM SIGNALS--------MEM SIGNALS--------MEM SIGNALS
//signals from previous stage
wire [6:0]  wb_MEM;
wire [2:0]  mem_MEM;
wire [31:0] aluout_MEM, data2_MEM;
wire [4:0]  rd_MEM;
wire [31:0] imm_MEM;
wire [31:0] memout_MEM;
wire [31:0] pc_MEM;
wire [11:0] csr_addr_MEM;
wire [1:0]  addr_bits_MEM; //two least-significant bits of data address, from previous stage.

wire [31:0] memout; //output of load-store unit
//pipeline registers
reg [4:0]  MEMWB_preg_rd;
reg [31:0] MEMWB_preg_memout;
reg [31:0] MEMWB_preg_aluout, MEMWB_preg_imm;
reg [11:0] MEMWB_preg_csr_addr;
reg [6:0]  MEMWB_preg_wb;
reg        MEMWB_preg_mret;
reg        MEMWB_preg_misaligned;
//END MEM SIGNALS--------END MEM SIGNALS--------END MEM SIGNALS--------END MEM SIGNALS--------END MEM SIGNALS--------END MEM SIGNALS

//WB SIGNALS--------WB SIGNALS--------WB SIGNALS--------WB SIGNALS--------WB SIGNALS--------WB SIGNALS--------WB SIGNALS
//signals from previous stage
wire [4:0]  rd_WB;
wire [6:0]  wb_WB;
wire        load_sign;
wire [1:0]  mem_length_WB;
wire [1:0]  mux_ctrl_WB;
wire        rf_wen_WB, csr_wen_WB;
wire [11:0] csr_addr_WB;
wire [31:0] memout_WB, aluout_WB, imm_WB;
wire        mret_WB;
reg [31:0]  mux_o_WB;
//END WB SIGNALS--------END WB SIGNALS--------END WB SIGNALS--------END WB SIGNALS--------END WB SIGNALS--------END WB SIGNALS

//CSR SIGNALS--------CSR SIGNALS--------CSR SIGNALS--------CSR SIGNALS--------CSR SIGNALS--------CSR SIGNALS
wire csr_if_flush, csr_id_flush, csr_ex_flush, csr_mem_flush;
wire [31:0] csr_pcin_mux1_o, csr_pcin_mux2_o;
reg [31:0] csr_pc_input;
wire [31:0] irq_addr; //interrupt handler address from CSR unit
wire [31:0] mepc; //mepc from CSR unit
wire [31:0] csr_reg_out;

//END CSR SIGNALS--------END CSR SIGNALS--------END CSR SIGNALS--------END CSR SIGNALS--------END CSR SIGNALS
assign csr_pcin_mux1_o = csr_ex_flush ? pc_EX : pc_ID;
assign csr_pcin_mux2_o = csr_mem_flush ? pc_MEM : csr_pcin_mux1_o;

always @(posedge clk_i or negedge reset_i)
begin
	if(!reset_i)
		csr_pc_input <= 32'b0;
	else
		csr_pc_input <= csr_pcin_mux2_o;
end
//instantiate CSR Unit
csr_unit CSR_UNIT(.clk_i(clk_i),
                  .hreset_i(hreset_i),
                  .sreset_i(sreset_i),
                  .pc_i(csr_pc_input),
                  .csr_r_addr_i(IFID_preg_instr[31:20]),
                  .csr_w_addr_i(csr_addr_WB),
                  .csr_reg_i(imm_WB),
                  .csr_wen_i(csr_wen_WB),
                  .meip_i(meip_i),
                  .mtip_i(mtip_i),
                  .msip_i(msip_i),
                  .fast_irq_i(fast_irq_i),
                  .take_branch_i(take_branch),
                  .mret_id_i(mret_ID),
                  .mret_wb_i(mret_WB),
                  .misaligned_ex(IDEX_preg_misaligned),
                  .instr_access_fault_i(instr_access_fault_i),
                  .data_err_i(data_err_i),

                  .csr_reg_o(csr_reg_out),
                  .mepc_o(mepc),
                  .irq_addr_o(irq_addr),
                  .mux1_ctrl_o(mux1_ctrl_IF),
                  .mux2_ctrl_o(mux4_ctrl_IF),
                  .ack_o(irq_ack_o),
                  .mem_wen_i(mem_MEM[0]),
                  .ex_dummy_i(IDEX_preg_dummy),
                  .mem_dummy_i(EXMEM_preg_dummy),
                  .csr_if_flush_o(csr_if_flush),
                  .csr_id_flush_o(csr_id_flush),
                  .csr_ex_flush_o(csr_ex_flush),
                  .csr_mem_flush_o(csr_mem_flush),
                  .illegal_instr_i(ctrl_unit_illegal_instr),
                  .ecall_i(ctrl_unit_ecall),
                  .ebreak_i(ctrl_unit_ebreak),
                  .instr_addr_misaligned_i(instr_addr_misaligned));

assign reset_i = hreset_i & sreset_i;
//IF STAGE---------------------------------------------------------------------------------
assign mux2_ctrl_IF = hazard_stall_IF | misaligned_access;
assign mux3_ctrl_IF = take_branch;

assign mux1_o_IF = mux1_ctrl_IF ? mepc : irq_addr;
assign mux2_o_IF = mux2_ctrl_IF ? pc_o : pc_o + 32'd4; //this mux is responsible for stalling the IF stage.
assign mux3_o_IF = mux3_ctrl_IF ? branch_target_addr : mux2_o_IF; //branch mux
assign mux4_o_IF = mux4_ctrl_IF ? mux3_o_IF : mux1_o_IF;

assign pc_i = reset_i ? mux4_o_IF : reset_vector;
assign instr_addr_o = pc_i;

assign hazard_stall_IF = hazard_stall | muldiv_stall_EX;

always @(posedge clk_i or negedge reset_i)
begin
	if(!reset_i)
	begin
		//reset pc to reset vector.
		pc_o <= reset_vector;
		{IFID_preg_pc, IFID_preg_instr} <= 64'h13; //nop instruction addi x0,x0,0
		IFID_preg_dummy <= 1'b0;
	end

	else if(take_branch | csr_if_flush) //flush IF
	begin
		{IFID_preg_pc, IFID_preg_instr} <= 64'h13;
		pc_o <= pc_i;
		IFID_preg_dummy <= 1'b1;
	end

	else
	begin
		if(!hazard_stall_IF & !misaligned_access) //stall the pipe if necessary
		begin
			IFID_preg_instr <= instr_i;
			IFID_preg_pc <= pc_o;
			IFID_preg_dummy <= 1'b0;
			pc_o <= pc_i;
		end
		/*
		else
			IFID_preg_dummy <= 1'b1;
		*/
	end
end
//END IF STAGE-----------------------------------------------------------------------------

//ID STAGE---------------------------------------------------------------------------------
//assign fields
assign rs1_ID       = IFID_preg_instr[19:15];
assign rs2_ID       = IFID_preg_instr[24:20];
assign rd_ID        = IFID_preg_instr[11:7];
assign pc_ID        = IFID_preg_pc;
assign imm_dec_i    = IFID_preg_instr[31:2];
assign csr_addr_ID  = IFID_preg_instr[31:20];
//assign nets
assign hazard_stall_ID = hazard_stall;
assign mux_ctrl_ID = hazard_stall;

assign mux1_o_ID    = mux_ctrl_ID ? 7'h0c : {ctrl_unit_wb_mux,
                                             ctrl_unit_wb_sign,
                                             ctrl_unit_wb_rf_wen,
                                             ctrl_unit_wb_csr_wen,
                                             ctrl_unit_mem_len};

assign mux2_o_ID    = mux_ctrl_ID ? 3'b1 : {ctrl_unit_mem_len, ctrl_unit_mem_wen};

assign mux3_o_ID    = mux_ctrl_ID ? 22'b0 : {ctrl_unit_op_div,
                                             ctrl_unit_op_mul,
                                             ctrl_unit_muldiv_sel,
                                             ctrl_unit_muldiv_start,
                                             ctrl_unit_B,
                                             ctrl_unit_J,
                                             ctrl_unit_ex_mux7,
                                             ctrl_unit_ex_mux6,
                                             ctrl_unit_ex_mux5,
                                             ctrl_unit_ex_mux3,
                                             ctrl_unit_ex_mux1,
                                             ctrl_unit_alu_func2,
                                             ctrl_unit_alu_func1};

control_unit    CTRL_UNIT   (.muldiv_start(ctrl_unit_muldiv_start),
                             .muldiv_sel(ctrl_unit_muldiv_sel),
                             .op_mul(ctrl_unit_op_mul),
                             .op_div(ctrl_unit_op_div),
                             .instr_i(IFID_preg_instr),
                             .ALU_func1(ctrl_unit_alu_func1),
                             .ALU_func2(ctrl_unit_alu_func2),
                             .EX_mux5(ctrl_unit_ex_mux5),
                             .EX_mux6(ctrl_unit_ex_mux6),
                             .EX_mux7(ctrl_unit_ex_mux7),
                             .EX_mux1(ctrl_unit_ex_mux1),
                             .EX_mux3(ctrl_unit_ex_mux3),
                             .B(ctrl_unit_B),
                             .J(ctrl_unit_J),
                             .MEM_len(ctrl_unit_mem_len),
                             .MEM_wen(ctrl_unit_mem_wen),
                             .WB_rf_wen(ctrl_unit_wb_rf_wen),
                             .WB_csr_wen(ctrl_unit_wb_csr_wen),
                             .WB_mux(ctrl_unit_wb_mux),
                             .WB_sign(ctrl_unit_wb_sign),
                             .illegal_instr(ctrl_unit_illegal_instr),
                             .ecall_o(ctrl_unit_ecall),
                             .ebreak_o(ctrl_unit_ebreak),
                             .mret_o(mret_ID));

imm_decoder     IMM_DEC	    (.instr_in(imm_dec_i), .imm_out(imm_dec_o));

//write to register file
integer i;
always @(negedge clk_i or negedge reset_i)
begin
	if(!reset_i)
	begin
		for(i=0; i < 32; i = i+1)
			register_bank[i] <= 32'b0; //reset all registers to 0.
	end

	else if(!rf_wen_WB)
		register_bank[rd_WB] <= mux_o_WB;
end


always @(posedge clk_i or negedge reset_i)
begin
	if(!reset_i)
	begin
		IDEX_preg_wb <= 7'h0c;
		IDEX_preg_mem <= 3'b1;
		IDEX_preg_csr_addr <= 12'b0;
		IDEX_preg_ex <= 22'b0;
		{IDEX_preg_pc, IDEX_preg_data1, IDEX_preg_data2} <= 96'b0;
		{IDEX_preg_rs1, IDEX_preg_rs2, IDEX_preg_rd} <= 15'b0;
		IDEX_preg_imm  <= 32'b0;
		IDEX_preg_dummy <= 1'b0;
		IDEX_preg_mret <= 1'b0;
		IDEX_preg_misaligned <= 1'b0;
	end

	else if(take_branch | csr_id_flush) //flush the pipe
	begin
		IDEX_preg_wb <= 7'h0c;
		IDEX_preg_mem <= 3'b1;
		IDEX_preg_csr_addr <= 12'b0;
		IDEX_preg_ex <= 22'b0;
		{IDEX_preg_pc, IDEX_preg_data1, IDEX_preg_data2} <= 96'b0;
		{IDEX_preg_rs1, IDEX_preg_rs2, IDEX_preg_rd} <= 15'b0;
		IDEX_preg_imm  <= 32'b0;
		IDEX_preg_dummy <= 1'b1;
		IDEX_preg_mret <= 1'b0;
		IDEX_preg_misaligned <= 1'b0;
	end

	else if(misaligned_access)
	begin
		IDEX_preg_misaligned <= 1'b1;

		if(IDEX_preg_rs1 == 5'b0)
			IDEX_preg_data1 <= 32'b0;
		else
			IDEX_preg_data1 <= register_bank[IDEX_preg_rs1];

		if(IDEX_preg_rs2 == 5'b0)
			IDEX_preg_data2 <= 32'b0;
		else
			IDEX_preg_data2 <= register_bank[IDEX_preg_rs2];
	end

	else if(muldiv_stall_EX)
	begin
	    IDEX_preg_wb <= IDEX_preg_wb;
		IDEX_preg_mem <= IDEX_preg_mem;
		IDEX_preg_csr_addr <= IDEX_preg_csr_addr;
		IDEX_preg_ex <= IDEX_preg_ex;
		{IDEX_preg_pc, IDEX_preg_data1, IDEX_preg_data2} <= {IDEX_preg_pc, IDEX_preg_data1, IDEX_preg_data2};
		{IDEX_preg_rs1, IDEX_preg_rs2, IDEX_preg_rd} <= {IDEX_preg_rs1, IDEX_preg_rs2, IDEX_preg_rd};
		IDEX_preg_imm  <= IDEX_preg_imm;
		IDEX_preg_dummy <= IDEX_preg_dummy;
		IDEX_preg_mret <= IDEX_preg_mret;
		IDEX_preg_misaligned <= IDEX_preg_misaligned;
	end

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
		IDEX_preg_csr_addr <= csr_addr_ID;
		IDEX_preg_mret <= mret_ID;
		IDEX_preg_misaligned <= 1'b0;

		if(!hazard_stall_ID)
			IDEX_preg_dummy <= IFID_preg_dummy;
		else
			IDEX_preg_dummy <= 1'b1;

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
//instantiate the MULDIV


MULDIV_top MULDIV(.clk(clk_i),
                  .start(muldiv_start),
                  .reset(reset_i),
                  .in_A(mux2_o_EX),
                  .in_B(mux4_o_EX),
                  .op_div(op_div),
                  .op_mul(op_mul),
                  .muldiv_sel(muldiv_sel),
                  .R(R_EX),
                  .muldiv_done(muldiv_done_EX));

assign muldiv_stall_EX = muldiv_start & ~muldiv_done_EX;

hazard_detection_unit HZRD_DET_UNIT (.rs1(rs1_ID),
                                     .rs2(rs2_ID),
                                     .opcode(IFID_preg_instr[6:2]),
                                     .funct3(IFID_preg_instr[14]),
                                     .rd_EX(rd_EX),
                                     .L_EX(L),
                                     .hazard_stall(hazard_stall));
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
assign csr_addr_EX = IDEX_preg_csr_addr;
//assign nets
assign alu_func1    = ex_EX[3:0];
assign alu_func2    = ex_EX[5:4];
assign mux1_ctrl_EX = ex_EX[7:6];
assign mux3_ctrl_EX = ex_EX[9:8];
assign mux5_ctrl_EX = ex_EX[10];
assign mux6_ctrl_EX = ex_EX[12:11];
assign mux7_ctrl_EX = ex_EX[13];
assign J            = ex_EX[14]; //jump
assign B            = ex_EX[15]; //branch
assign muldiv_start = ex_EX[16];
assign muldiv_sel   = ex_EX[17];
assign op_mul       = ex_EX[19:18];
assign op_div       = ex_EX[21:20];
assign L            = (!wb_EX[3] && wb_EX[6:5] == 2'b1) ? 1'b1 : 1'b0; //load
assign mem_wen_EX   = muldiv_stall_EX ? 1'b1 : (csr_ex_flush ? 1'b1 : mem_EX[0]);
assign mem_length_EX = mem_EX[2:1];
//muxes
assign mux1_o_EX = mux1_ctrl_EX == 2'b10 ? mux8_o_EX
                 : mux1_ctrl_EX == 2'b01 ? pc_EX
                 : mux2_o_EX;

assign mux2_o_EX = mux2_ctrl_EX == 2'b10 ? aluout_MEM
                 : mux2_ctrl_EX == 2'b01 ? mux_o_WB
                 : data1_EX;

assign mux3_o_EX = mux3_ctrl_EX == 2'b10 ? mux8_o_EX
                 : mux3_ctrl_EX == 2'b01 ? imm_EX
                 : mux4_o_EX;

assign mux4_o_EX = mux4_ctrl_EX == 2'b10 ? data2_EX
                 : mux4_ctrl_EX == 2'b01 ? mux_o_WB
                 : aluout_MEM;

assign mux5_o_EX = mux5_ctrl_EX ? pc_EX	 : mux2_o_EX;
assign mux6_o_EX = mux6_ctrl_EX[1] ? R_EX : (mux6_ctrl_EX[0] ? mux8_o_EX : aluout_EX);
assign mux7_o_EX = mux7_ctrl_EX ? imm_EX : aluout_EX;

assign mux8_o_EX = mux8_ctrl_EX == 2'd0 ? imm_WB
                 : mux8_ctrl_EX == 2'd1 ? imm_MEM
                 : csr_reg_out;

//instantiate the forwarding unit.
forwarding_unit FWD_UNIT(.rs1(rs1_EX),
                         .rs2(rs2_EX),
                         .exmem_rd(rd_MEM),
                         .memwb_rd(rd_WB),
                         .exmem_wb(wb_MEM[3]),
                         .memwb_wb(rf_wen_WB),
                         .mux1_ctrl(mux2_ctrl_EX),
                         .mux2_ctrl(mux4_ctrl_EX),
                         .mux3_ctrl(mux8_ctrl_EX),
                         .csr_addr_EX(csr_addr_EX),
                         .csr_addr_MEM(csr_addr_MEM),
                         .csr_addr_WB(csr_addr_WB),
                         .csr_wen_MEM(wb_MEM[2]),
                         .csr_wen_WB(csr_wen_WB));
//instantiate the ALU
ALU ALU (.src1(mux1_o_EX), .src2(mux3_o_EX), .func1(alu_func1), .func2(alu_func2), .alu_out(aluout_EX));



//branch logic and address calculation
assign take_branch = J | (B & aluout_EX[0]);
assign branch_addr_calc = mux5_o_EX + imm_EX;
assign branch_target_addr[31:1] = branch_addr_calc[31:1];
assign branch_target_addr[0] = (!mux5_ctrl_EX & J) ? 1'b0 : branch_addr_calc[0]; //clear the least-significant bit if the instruction is JALR.
assign instr_addr_misaligned = take_branch & (branch_target_addr[1:0] != 2'd0);

always @(posedge clk_i or negedge reset_i) //clock the outputs to the pipeline register
begin
	if(!reset_i)
	begin
		EXMEM_preg_wb <= 7'h0c;
		EXMEM_preg_mem <= 3'b1;
		EXMEM_preg_csr_addr <= 12'b0;
		{EXMEM_preg_pc, EXMEM_preg_aluout, EXMEM_preg_data2} <= 96'b0;
		EXMEM_preg_rd <= 5'b0;
		EXMEM_preg_imm <= 32'b0;
		EXMEM_preg_dummy <= 1'b0;
		EXMEM_preg_mret <= 1'b0;
		EXMEM_preg_misaligned <= 1'b0;
		EXMEM_preg_addr_bits <= 2'b0;
	end

	else if(muldiv_stall_EX)
	begin
	   EXMEM_preg_wb <= 7'h0c;
	   EXMEM_preg_mem[2:1] <= EXMEM_preg_mem[2:1];
	   EXMEM_preg_mem[0] <= mem_wen_EX;
	   EXMEM_preg_csr_addr <= EXMEM_preg_csr_addr;
	   {EXMEM_preg_pc, EXMEM_preg_aluout, EXMEM_preg_data2} <= {EXMEM_preg_pc, EXMEM_preg_aluout, EXMEM_preg_data2};
	   EXMEM_preg_rd <= EXMEM_preg_rd;
	   EXMEM_preg_imm <= EXMEM_preg_imm;
	   EXMEM_preg_dummy <= EXMEM_preg_dummy;
	   EXMEM_preg_mret <= EXMEM_preg_mret;
	   EXMEM_preg_misaligned <= EXMEM_preg_misaligned;
	   EXMEM_preg_addr_bits <= EXMEM_preg_addr_bits;
	end

	else if(csr_ex_flush)
	begin
		EXMEM_preg_wb <= 7'h0c;
		EXMEM_preg_mem <= 3'b1;
		EXMEM_preg_csr_addr <= 12'b0;
		{EXMEM_preg_pc, EXMEM_preg_aluout, EXMEM_preg_data2} <= 96'b0;
		EXMEM_preg_rd <= 5'b0;
		EXMEM_preg_imm <= 32'b0;
		EXMEM_preg_dummy <= 1'b1;
		EXMEM_preg_mret <= 1'b0;
		EXMEM_preg_misaligned <= 1'b0;
		EXMEM_preg_addr_bits <= 2'b0;
	end

	else
	begin
		EXMEM_preg_imm <= mux7_o_EX;
		EXMEM_preg_rd <= rd_EX;
		EXMEM_preg_pc <= pc_EX;
		EXMEM_preg_data2 <= mux4_o_EX;
		EXMEM_preg_aluout <= mux6_o_EX;
		EXMEM_preg_mem <= {mem_EX[2:1],mem_wen_EX};
		EXMEM_preg_wb[6:4] <= wb_EX[6:4];
		EXMEM_preg_wb[3] <= misaligned_access ? 1'b1 : wb_EX[3];
		EXMEM_preg_wb[2:0] <= wb_EX[2:0];
		EXMEM_preg_csr_addr <= csr_addr_EX;
		EXMEM_preg_dummy <= IDEX_preg_dummy;
		EXMEM_preg_mret <= IDEX_preg_mret;
		EXMEM_preg_misaligned <= IDEX_preg_misaligned;
		EXMEM_preg_addr_bits <= aluout_EX[1:0];
	end
end

//END EX STAGE-----------------------------------------------------------------------------

load_store_unit LS_UNIT (.addr_i(aluout_EX),
                         .data_i(mux4_o_EX),
                         .length_EX_i(mem_length_EX),
                         .load_i(L),
                         .wen_i(mem_wen_EX),
                         .misaligned_EX_i(IDEX_preg_misaligned),
                         .misaligned_MEM_i(EXMEM_preg_misaligned),
                         .read_data_i(data_i),
                         .length_MEM_i(mem_MEM[2:1]),
                         .addr_offset_i(EXMEM_preg_addr_bits),
                         .memout_WB_i(memout_WB[23:0]),
                         .data_o(data_o),
                         .addr_o(data_addr_o),
                         .wmask_o(data_wmask_o),
                         .misaligned_access_o(misaligned_access),
                         .memout_o(memout));

assign data_req_o = L | ~mem_wen_EX; //driven high if there's a load or a store.
assign data_wen_o  = mem_wen_EX;
//MEM STAGE---------------------------------------------------------------------------------
assign wb_MEM 	    = EXMEM_preg_wb;
assign mem_MEM 	    = EXMEM_preg_mem;
assign aluout_MEM   = EXMEM_preg_aluout;
assign data2_MEM    = EXMEM_preg_data2;
assign rd_MEM 	    = EXMEM_preg_rd;
assign pc_MEM       = EXMEM_preg_pc;
assign imm_MEM 	    = EXMEM_preg_imm;
assign csr_addr_MEM = EXMEM_preg_csr_addr;
assign addr_bits_MEM = EXMEM_preg_addr_bits;

always @(posedge clk_i or negedge reset_i)
begin
	if(!reset_i)
	begin
		MEMWB_preg_wb <= 7'h0c;
		MEMWB_preg_csr_addr <= 12'b0;
		MEMWB_preg_rd <= 5'b0;
		MEMWB_preg_memout <= 32'b0;
		MEMWB_preg_aluout <= 32'b0;
		MEMWB_preg_imm <= 32'b0;
		MEMWB_preg_mret <= 1'b0;
		MEMWB_preg_misaligned <= 1'b0;
	end

	else if(csr_mem_flush)
	begin
		MEMWB_preg_wb <= 7'h0c;
		MEMWB_preg_csr_addr <= 12'b0;
		MEMWB_preg_rd <= 5'b0;
		MEMWB_preg_memout <= 32'b0;
		MEMWB_preg_aluout <= 32'b0;
		MEMWB_preg_imm <= 32'b0;
		MEMWB_preg_mret <= 1'b0;
		MEMWB_preg_misaligned <= 1'b0;
	end

	else
	begin
		MEMWB_preg_wb <= wb_MEM;
		MEMWB_preg_rd <= rd_MEM;
		MEMWB_preg_csr_addr <= csr_addr_MEM;
		MEMWB_preg_imm <= imm_MEM;
		MEMWB_preg_aluout <= aluout_MEM;
		MEMWB_preg_memout <= memout;
		MEMWB_preg_mret <= EXMEM_preg_mret;
		MEMWB_preg_misaligned <= EXMEM_preg_misaligned;
	end
end
//END MEM STAGE-----------------------------------------------------------------------------

//WB STAGE---------------------------------------------------------------------------------
//assign fields
assign wb_WB 	   = MEMWB_preg_wb;
assign memout_WB   = MEMWB_preg_memout;
assign rd_WB 	   = MEMWB_preg_rd;
assign csr_addr_WB = MEMWB_preg_csr_addr;
assign imm_WB      = MEMWB_preg_imm;
assign aluout_WB   = MEMWB_preg_aluout;
assign mret_WB     = MEMWB_preg_mret;
//assign nets
assign mem_length_WB = wb_WB[1:0];
assign csr_wen_WB  = wb_WB[2];
assign rf_wen_WB   = wb_WB[3];
assign load_sign   = wb_WB[4];
assign mux_ctrl_WB = wb_WB[6:5];

//WB mux
always @(*)
begin
	if(!reset_i)
		mux_o_WB = 32'b0;

	else if(mux_ctrl_WB == 2'b0)
		mux_o_WB = aluout_WB;

	else if(mux_ctrl_WB == 2'b1) //load instruction
	begin
		if(mem_length_WB == 2'b0)
		begin
			if(load_sign == 1'b1) //signed load, perform sign extension
				mux_o_WB = { {24{memout_WB[7]}}, memout_WB[7:0] };
			else
				mux_o_WB = { 24'b0, memout_WB[7:0] };
		end
		else if(mem_length_WB == 2'b1)
		begin
			if(load_sign == 1'b1) //signed load, perform sign extension
				mux_o_WB = { {16{memout_WB[15]}}, memout_WB[15:0] };
			else
				mux_o_WB = { 16'b0, memout_WB[15:0] };
		end
		else
			mux_o_WB = { memout_WB };
		end

	else
		mux_o_WB = imm_WB;
end

//END WB STAGE-----------------------------------------------------------------------------
endmodule

