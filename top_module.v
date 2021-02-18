`include "/home/ytozlu/projects/BASAK/projectDir/yavuz_digital/riscv/top_module/core.v"
`include "/home/ytozlu/projects/BASAK/projectDir/yavuz_digital/riscv/top_module/mtime_registers.v"

`timescale 1ns/1ps

module top_module(input clk_i,
                  input reset_i,
                  input wen_i, meip_i,
                  input [31:0] addr_i,
                  input [31:0] instr_i,
                  output irq_ack_o);
				  
wire [3:0] wmask0, wmask1;
wire wen0, mtip_o;
wire [31:0] instr_addr_o, data_addr_o;
wire [31:0] mem_data_o, mem_instr_o, data_o, mtime_reg_data_o, core_data_i;
wire [31:0] mux_addr_o;
wire sram_csb, mtime_csb;

reg csb_reg;

assign sram_csb = data_addr_o[11] | !reset_i;
assign mtime_csb = !data_addr_o[11] | !reset_i;
assign mux_addr_o = wen_i ? instr_addr_o : addr_i;

always @(posedge clk_i or negedge reset_i)
begin
	if(!reset_i)
		csb_reg <= 1'b0;
	else
		csb_reg <= sram_csb;
end
assign core_data_i = csb_reg ? mtime_reg_data_o : mem_data_o;
core core0(.clk_i(clk_i), 
           .reset_i(reset_i), 
           .meip_i(meip_i), 
           .mtip_i(mtip_o), 
           .instr_i(mem_instr_o), 
           .data_i(core_data_i), 
           .data_o(data_o), 
           .wmask0_o(wmask0), 
           .wen0_o(wen0), 
           .instr_addr_o(instr_addr_o), 
           .data_addr_o(data_addr_o), 
           .irq_ack_o(irq_ack_o));

memory_2rw memory(.clk0(clk_i), .csb0(sram_csb), .web0(wen0), .wmask0(wmask0), .addr0(data_addr_o[10:2]), .din0(data_o), .dout0(mem_data_o), //port 0 is for data memory
                  .clk1(clk_i), .csb1(1'b0), .web1(wen_i), .wmask1(4'b1111), .addr1(mux_addr_o[10:2]), .din1(instr_i), .dout1(mem_instr_o)); //port 1 is for instruction memory
                                     
mtime_registers mtime0(.reset_i(reset_i), .csb_i(mtime_csb), .wen_i(wen0), .clk_i(clk_i),
                .addr_i(data_addr_o[3:0]), .data_i(data_o), .wmask_i(wmask0), .mtip_o(mtip_o), .data_o(mtime_reg_data_o));                                     

endmodule
