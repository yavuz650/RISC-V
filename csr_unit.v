`timescale 1ns/1ps
//state encoding
`define INIT 2'd0
`define STAND_BY 2'd1
`define S1 2'd2
`define S2 2'd3
//bits in the CSR registers
`define mstatus_mie mstatus[3]
`define mstatus_mpie mstatus[7]
`define mie_meie mie[11]
`define mip_meip mip[11]
`define mie_mtie mie[7]
`define mip_mtip mip[7]

module csr_unit(input clk_i, reset_i,
                input [31:0] pc_i,
                input [11:0] csr_r_addr_i,
                input [11:0] csr_w_addr_i,
                input [31:0] csr_reg_i,
                input csr_wen_i, meip_i, mtip_i, muxpc_ctrl_i,
                input mem_wen_i, ex_dummy_i, mem_dummy_i,
                input mret_id_i, mret_wb_i,

                output reg [31:0] csr_reg_o,
                output [31:0] irq_addr_o, mepc_o,
                output mux1_ctrl_o, mux2_ctrl_o,
                output reg ack_o,
                output csr_if_flush_o, csr_id_flush_o, csr_ex_flush_o, csr_mem_flush_o);
                
reg [1:0] STATE;
reg [31:0] mstatus, mie, mip, mcause, mtvec, mepc, mscratch;
wire pending_irq;
wire csr_if_flush, csr_id_flush, csr_ex_flush, csr_mem_flush;

assign pending_irq = (`mie_meie & `mip_meip) | (`mie_mtie & `mip_mtip);
assign csr_if_flush = (`mstatus_mie & pending_irq) | (STATE == `S1) | (mret_id_i & muxpc_ctrl_i);
assign csr_id_flush = csr_ex_flush | (`mstatus_mie & pending_irq);
assign csr_ex_flush = csr_mem_flush | (`mstatus_mie & pending_irq & !ex_dummy_i);
assign csr_mem_flush = `mstatus_mie & pending_irq & mem_wen_i & !mem_dummy_i;

//outputs
assign irq_addr_o = (mtvec >> 2) + (mcause << 2);
assign mux1_ctrl_o = mret_id_i & muxpc_ctrl_i;
assign mux2_ctrl_o = !((STATE == `S1) | (mret_id_i & muxpc_ctrl_i));
assign csr_if_flush_o = csr_if_flush;
assign csr_id_flush_o = csr_id_flush;
assign csr_ex_flush_o = csr_ex_flush;
assign csr_mem_flush_o = csr_mem_flush;
assign mepc_o = mepc;

 
//state transitions are done on the rising edge
always @(posedge clk_i or negedge reset_i)
begin
	if(!reset_i)
	begin
		STATE <= `INIT;
		ack_o <= 1'b0;
	end
	
	else
	begin
		case(STATE)
			`INIT: 
			begin
				STATE <= `STAND_BY;
			end
			
			`STAND_BY:
			begin
				if(`mstatus_mie & `mie_meie & `mip_meip)
				begin
					STATE <= `S1;
					ack_o <= 1'b1;
				end
				
				else if(`mstatus_mie & `mie_mtie & `mip_mtip)
					STATE <= `S1;
			end
			
			`S1:
			begin
				STATE <= `S2;
				ack_o <= 1'b0;
			end
			
			`S2:
			begin
				STATE <= `STAND_BY;
			end
		endcase
	end		
end

always @(posedge clk_i)
begin
	if(!reset_i)
		csr_reg_o <= 32'b0;
	
	else
	begin
		if(csr_r_addr_i == 12'h300) //0x300 - mstatus
			csr_reg_o <= mstatus;
	
		else if(csr_r_addr_i[11:0] == 12'h304) //0x304 - mie
			csr_reg_o <= mie;
			
		else if(csr_r_addr_i[11:0] == 12'h305) //0x305 - mtvec
			csr_reg_o <= mtvec;
			
		else if(csr_r_addr_i[11:0] == 12'h340) //0x340 - mscratch
			csr_reg_o <= mscratch;
				
		else if(csr_r_addr_i[11:0] == 12'h341) //0x341 - mepc
			csr_reg_o <= mepc;
			
		else if(csr_r_addr_i[11:0] == 12'h342) //0x342 - mcause
				csr_reg_o <= mcause;
			
		else if(csr_r_addr_i[11:0] == 12'h344) //0x344 - mip
			csr_reg_o <= mip;
	end
end

always @(negedge clk_i or negedge reset_i)
begin
	if(!reset_i)
		mip <= 32'b0;
	else
	begin
		`mip_meip <= meip_i; //meip bit is set by the interrupt controller
		`mip_mtip <= mtip_i; //timer interrupt bit
	end
end

//assignments are done on the falling edge
always @(negedge clk_i or negedge reset_i)
begin
	if(!reset_i)
	begin
		mepc <= 32'b0;
		mie <= 32'b0;
		mcause <= 32'b0;
		mscratch <= 32'b0;
		mtvec <= 32'b0;
		//unused fields are hardwired to 0
		mstatus[31:13] <= 19'b0; mstatus[10:0] <= 11'b0; 
		//mstatus.mpp 
		mstatus[12:11] <= 2'b11;
	
	end
	
	else
	begin
		if(!csr_wen_i)
		begin
			if(mret_wb_i)
			begin
				`mstatus_mie <= `mstatus_mpie;
				`mstatus_mpie <= 1'b1;				
			end
			
			else if(csr_w_addr_i[11:0] == 12'h300) //0x300 - mstatus
			begin
				`mstatus_mie <= csr_reg_i[3];
				`mstatus_mpie <= csr_reg_i[7];
			end
			
			else if(csr_w_addr_i[11:0] == 12'h304) //0x304 - mie
			begin
				`mie_meie <= csr_reg_i[11];
				`mie_mtie <= csr_reg_i[7];
			end
			
            else if(csr_w_addr_i[11:0] == 12'h305) //0x305 - mtvec
            	mtvec <= csr_reg_i;
			
			else if(csr_w_addr_i[11:0] == 12'h340) //0x340 - mscratch
				mscratch <= csr_reg_i;
				
			else if(csr_w_addr_i[11:0] == 12'h341) //0x341 - mepc
				mepc <= csr_reg_i;
				
			else if(csr_w_addr_i[11:0] == 12'h342) //0x342 - mcause
				mcause <= csr_reg_i;

		end

		else
		begin
			case(STATE)	
				`S1:
				begin
					mepc <= pc_i;
					`mstatus_mpie <= `mstatus_mie;
					`mstatus_mie <= 1'b0;
					mcause[31] <= 1'b1;
					
					if(`mie_meie & `mip_meip) //external interrupt
						mcause[30:0] <= 31'd11;
										
					else if(`mie_mtie & `mip_mtip)//timer interrupt
						mcause[30:0] <= 31'd7;
				end
			endcase
		end
	end
end


endmodule



