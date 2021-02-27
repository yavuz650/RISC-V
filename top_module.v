`include "/home/ytozlu/projects/BASAK/projectDir/yavuz_digital/riscv/top_module/core.v"
`include "/home/ytozlu/projects/BASAK/projectDir/yavuz_digital/riscv/top_module/mtime_registers.v"
//`include "/home/ytozlu/projects/BASAK/projectDir/yavuz_digital/riscv/top_module/uart.v"
`timescale 1ns/1ps

module top_module(input clk_i,
                  input reset_i,
                  input meip_i,
                  output irq_ack_o);
				  
wire [3:0] wmask0;
wire wen0, mtip_o;
wire [31:0] instr_addr_o, data_addr_o;
wire [31:0] mem_data_o, mem_instr_o, core_data_o, mtime_data_o, core_data_i;
wire sram_csb, mtime_csb;

reg mtime_csb_reg;
reg [31:0] data_addr_o_reg, core_data_o_reg;
reg [3:0] wmask0_reg;
reg wen0_reg;

/*
wire uart_csb, uart_rx_irq;
wire [7:0] uart_data_o;*/

assign sram_csb = data_addr_o[11] | !reset_i;
assign mtime_csb = !data_addr_o[11] | !reset_i;
//assign uart_csb = !data_addr_o_reg[11] | !data_addr_o_reg[4] | !reset_i;

/*
assign core_data_i = !mtime_csb_reg ? mtime_data_o 
                   : !uart_csb ? uart_data_o
                   : mem_data_o;*/
                   
assign core_data_i = !mtime_csb_reg ? mtime_data_o : mem_data_o;                  
               
always @(posedge clk_i or negedge reset_i)
begin
	if(!reset_i)
		mtime_csb_reg <= 1'b1;
	else
		mtime_csb_reg <= mtime_csb;
end

//register the inputs to peripherals
always @(posedge clk_i or negedge reset_i)
begin
	if(!reset_i)
		{data_addr_o_reg,core_data_o_reg,wmask0_reg,wen0_reg} <= 69'b0;
	else
	begin
		data_addr_o_reg <= data_addr_o;
		core_data_o_reg <= core_data_o;
		wmask0_reg <= wmask0;
		wen0_reg <= wen0;
	end
end

core core0(.clk_i(clk_i),
           .reset_i(reset_i),
           .meip_i(meip_i),
           .mtip_i(mtip_o),
           .instr_i(mem_instr_o),
           .data_i(core_data_i),
           .data_o(core_data_o),
           .wmask0_o(wmask0),
           .wen0_o(wen0),
           .instr_addr_o(instr_addr_o),
           .data_addr_o(data_addr_o),
           .irq_ack_o(irq_ack_o));

memory_2rw memory(.clk0(clk_i), .csb0(sram_csb), .web0(wen0), .wmask0(wmask0), .addr0(data_addr_o[10:2]), .din0(core_data_o), .dout0(mem_data_o), //port 0 is for data memory
                  .clk1(clk_i), .csb1(1'b0), .web1(1'b1), .wmask1(4'b1111), .addr1(instr_addr_o[10:2]), .din1(32'b0), .dout1(mem_instr_o)); //port 1 is for instruction memory
                                     
mtime_registers mtime0(.reset_i(reset_i), 
                       .csb_i(mtime_csb_reg), 
                       .wen_i(wen0_reg), 
                       .clk_i(clk_i),
                       .addr_i(data_addr_o_reg[3:0]), 
                       .data_i(core_data_o_reg), 
                       .wmask_i(wmask0_reg), 
                       .mtip_o(mtip_o), 
                       .data_o(mtime_data_o));  
                  
/*uart uart0 (.clk_i(clk_i), .reset_i(reset_i), .rx_i(rx_i),
            .csb_i(uart_csb), .wen_i(wen0_reg),
            .data_i(core_data_o_reg[7:0]),
            .addr_i(data_addr_o_reg[1:0]),
            .tx_o(tx_o), .receive_irq(uart_rx_irq),
            .data_o(uart_data_o));            */              

endmodule

