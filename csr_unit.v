`timescale 1ns/1ps
//state encoding
`define INIT 3'd0
`define STAND_BY 3'd1
`define S1 3'd2
`define S2 3'd3
`define S3 3'd4
`define S4 3'd5
//bits in the CSR registers
`define mstatus_mie mstatus[3]
`define mstatus_mpie mstatus[7]
`define mie_meie mie[11]
`define mip_meip mip[11]


module csr_unit(input clk_i, reset_i,
                input [10:0] pc_i,
                input [29:0] instr_i,
                input [11:0] csr_w_addr_i,
                input [31:0] csr_reg_i,
                input csr_wen_i, meip_i, ifid_wen_i, pipe_rdy_i, muxpc_ctrl_i,

                output reg [31:0] csr_reg_o, mepc_o,
                output [10:0] irq_addr_o,
                output mux1_ctrl_o, mux2_ctrl_o, csr_stall_o, csr_flush_o, ack_o);
                
reg [2:0] STATE;
reg [31:0] mstatus, mie, mip, mcause, mtvec, mepc, mscratch;
wire [11:0] csr_r_addr;
wire mret;

assign mret = instr_i == 30'hc08_001c ? 1'b1 : 1'b0;
assign csr_r_addr = instr_i[29:18];

//outputs
assign irq_addr_o = (mtvec >> 2) + (mcause << 2);
assign mux1_ctrl_o = mret & muxpc_ctrl_i;
assign mux2_ctrl_o = (STATE != `S2) & ~(mret & muxpc_ctrl_i);
assign csr_stall_o = (`mstatus_mie & `mie_meie & `mip_meip & !ifid_wen_i) | (STATE == `S1);
assign csr_flush_o = (STATE == `S1) | (STATE == `S2) | (mret & muxpc_ctrl_i);
assign ack_o = (STATE == `S1) & pipe_rdy_i;

 
//state transitions are done on the rising edge
always @(posedge clk_i or negedge reset_i)
begin
	if(!reset_i)
		STATE <= `INIT;
	
	else
	begin
		case(STATE)
			`INIT: 
			begin
				STATE <= `STAND_BY;
			end
			
			`STAND_BY:
			begin
				if(`mstatus_mie & `mie_meie & `mip_meip & ~ifid_wen_i)
					STATE <= `S1;
				else
					STATE <= `STAND_BY;
			end
			
			`S1:
			begin
				if(pipe_rdy_i)
					STATE <= `S2;
				else
					STATE <= `S1;
			end
			
			`S2:
			begin
				STATE <= `S3;
			end
			
			`S3:
			begin
				if(`mstatus_mie & `mie_meie & `mip_meip & ~ifid_wen_i)
					STATE <= `S1;
				else if(mret & muxpc_ctrl_i)
					STATE <= `S4;
				else
					STATE <= `S3;
			end
			
			`S4:
			begin
				STATE <= `STAND_BY;
			end
		endcase
	end		
end

always @(posedge clk_i)
begin
	if(csr_r_addr == 12'h300) //0x300 - mstatus
		csr_reg_o <= mstatus;
	
	else if(csr_r_addr[11:0] == 12'h304) //0x304 - mie
		csr_reg_o <= mie;
		
	else if(csr_r_addr[11:0] == 12'h305) //0x305 - mtvec
		csr_reg_o <= mtvec;
		
	else if(csr_r_addr[11:0] == 12'h340) //0x340 - mscratch
		csr_reg_o <= mscratch;
		
	else if(csr_r_addr[11:0] == 12'h341) //0x341 - mepc
		csr_reg_o <= mepc;
		
	else if(csr_r_addr[11:0] == 12'h342) //0x342 - mcause
		csr_reg_o <= mcause;
		
	else if(csr_r_addr[11:0] == 12'h344) //0x344 - mip
		csr_reg_o <= mip;
		
	mepc_o <= mepc;
end

//assignments are done on the falling edge
always @(negedge clk_i or negedge reset_i)
begin
	if(!reset_i)
	begin
		mepc[10:0] <= 11'b0;
		`mstatus_mie <= 1'b0;
		`mstatus_mpie <= 1'b0;
		`mie_meie <= 1'b0;
		mcause <= 32'b0;
		mscratch <= 32'b0;
		`mip_meip <= 1'b0;
		
		//unused fields are hardwired to 0
		mstatus[31:13] <= 19'b0; mstatus[10:8] <= 3'b0; mstatus[6:4] <= 3'b0; mstatus[2:0] <= 3'b0; 
		//mstatus.mpp 
		mstatus[12:11] <= 2'b11;
	
		//mie
		mie[31:12] <= 20'b0; mie[10:0] <= 11'b0;

		//mip
		mip[31:12] <= 20'b0; mip[10:0] <= 11'b0;
	
		//mtvec
		mtvec[1:0] <= 2'b1;
		mtvec[31:2] <= 30'd16;
		//mepc
		mepc[31:11] <= 21'b0;
	end
	
	else
	begin
		`mip_meip <= meip_i; //meip bit is set by the interrupt controller
		if(!csr_wen_i)
		begin
			if(csr_w_addr_i[11:0] == 12'h300) //0x300 - mstatus
			begin
				`mstatus_mie <= csr_reg_i[3];
				`mstatus_mpie <= csr_reg_i[7];
			end
			
			else if(csr_w_addr_i[11:0] == 12'h304) //0x304 - mie
				`mie_meie <= csr_reg_i[11];
				
            else if(csr_w_addr_i[11:0] == 12'h305) //0x305 - mtvec
            	mtvec <= csr_reg_i;
			
			else if(csr_w_addr_i[11:0] == 12'h340) //0x340 - mscratch
				mscratch <= csr_reg_i;
				
			else if(csr_w_addr_i[11:0] == 12'h341) //0x341 - mepc
				mepc[10:0] <= csr_reg_i[10:0];
				
			else if(csr_w_addr_i[11:0] == 12'h342) //0x342 - mcause
				mcause <= csr_reg_i;

		end
				
		else
		begin
			case(STATE)
						
				`S2:
				begin
					mepc[10:0] <= pc_i;
					`mstatus_mpie <= `mstatus_mie;
					`mstatus_mie <= 1'b0;
					mcause[31] <= 1'b1;
					mcause[30:0] <= 31'd11;
				end
								
				`S4:
				begin
					`mstatus_mie <= `mstatus_mpie;
					`mstatus_mpie <= 1'b1;
				end
			endcase
		end
	end
end


endmodule



