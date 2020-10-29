`timescale 1ns/10ps

module top_module(input clk_i,
				  input reset_i,
				  input wen_i,
				  input [10:0] addr_i,
				  input [31:0] instr_i);
				  
wire [3:0] wmask0, wmask1;
wire wen0;
wire [10:0] instr_addr_o, data_addr_o;
wire [31:0] mem_data_o, mem_instr_o, data_o;
wire [10:0] mux_addr_o;

assign mux_addr_o = wen_i ? instr_addr_o : addr_i;
	    	
core core0(.clk_i(clk_i), .reset_i(reset_i), .instr_i(mem_instr_o), .data_i(mem_data_o), .data_o(data_o), .wmask0_o(wmask0), .wen0_o(wen0), .instr_addr_o(instr_addr_o), .data_addr_o(data_addr_o) );

sram_1rw1r_32_512_8_freepdk45 memory(.clk0(clk_i), .csb0(!reset_i), .web0(wen0), .wmask0(wmask0), .addr0(data_addr_o[10:2]), .din0(data_o), .dout0(mem_data_o), //port 0 is for data memory
	 								 .clk1(clk_i), .csb1(1'b0), .web1(wen_i), .wmask1(4'b1111), .addr1(mux_addr_o[10:2]), .din1(instr_i), .dout1(mem_instr_o)); //port 1 is for instruction memory

endmodule
