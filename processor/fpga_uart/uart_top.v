`timescale 1ns/1ps

module uart_top(input M100_clk_i,
                input reset_i,
                input rx_i,
                output tx_o,
                output irq_ack_o,
                output led1,led2,led3,led4);

parameter SYS_CLK_FREQ = 50000000;

wire clk_i, locked;
clk_wiz_0 clkwiz0
(
// Clock out ports
       .clk_out1(clk_i),
// Status and control signals
       .reset(1'b0),
       .locked(locked),
// Clock in ports
       .clk_in1(M100_clk_i)
);

wire [3:0] data_wmask;
wire data_wen, mtip_o;
wire [31:0] instr_addr_o, data_addr_o;
wire [31:0] mem_data_o, mem_instr_o, core_data_o, mtime_data_o, core_data_i;
wire data_req;
wire sram_csb, mtime_csb, loader_csb;

reg [31:0] data_addr_o_reg, core_data_o_reg;
reg [3:0] data_wmask_reg;
reg data_wen_reg;

wire uart_csb, uart_rx_irq;
wire [31:0] uart_data_o;

wire loader_reset_o;
wire [31:0] loader_reg_o;

wire reset;

assign reset = loader_reset_o & reset_i;

assign sram_csb = !(data_addr_o[31:15] == 19'b0) | !reset; //0x0000_0000 to 0x0000_7FFF
assign mtime_csb = !(data_addr_o_reg[31:4] == 28'h0000_800) | !reset; //0x0000_8000 to 0x0000_800F
assign uart_csb = !(data_addr_o_reg[31:2] == 30'h0000_2004) | !reset; //0x0000_8010 to 0x0000_8013
assign loader_csb = !(data_addr_o_reg[31:0] == 30'h0000_8014) | !reset; //0x0000_8014

assign core_data_i = !mtime_csb ? mtime_data_o
                   : !uart_csb ? uart_data_o
                   : !loader_csb ? loader_reg_o
                   : mem_data_o;

//register the inputs to peripherals
always @(posedge clk_i or negedge reset)
begin
	if(!reset)
		{data_addr_o_reg,core_data_o_reg,data_wmask_reg,data_wen_reg} <= 69'b0;
	else
	begin
		data_addr_o_reg <= data_addr_o;
		core_data_o_reg <= core_data_o;
		data_wmask_reg <= data_wmask;
		data_wen_reg <= data_wen;
	end
end

core #(.reset_vector(32'h7400)) core0(.clk_i(clk_i),
                                      .reset_i(reset),
                                      .meip_i(1'b0),
                                      .mtip_i(mtip_o),
                                      .msip_i(1'b0),
                                      .fast_irq_i({15'b0,uart_rx_irq}),
                                      .instr_i(mem_instr_o),
                                      .data_i(core_data_i),
                                      .data_o(core_data_o),
                                      .data_wmask_o(data_wmask),
                                      .data_wen_o(data_wen),
                                      .data_req_o(data_req),
                                      .data_err_i(1'b0),
                                      .instr_addr_o(instr_addr_o),
                                      .instr_access_fault_i(1'b0),
                                      .data_addr_o(data_addr_o),
                                      .irq_ack_o(irq_ack_o));

fpga_memory #(.ADDR_WIDTH(13)) memory (.clk0(clk_i), //port 0 is for data memory
                                       .csb0(sram_csb),
                                       .web0(data_wen),
                                       .wmask0(data_wmask),
                                       .addr0(data_addr_o[14:2]),
                                       .din0(core_data_o),
                                       .dout0(mem_data_o),
                                       .clk1(clk_i), //port 1 is for instruction memory
                                       .csb1(1'b0),
                                       .web1(1'b1),
                                       .wmask1(4'b1111),
                                       .addr1(instr_addr_o[14:2]),
                                       .din1(32'b0),
                                       .dout1(mem_instr_o));

mtime_registers mtime0(.reset_i(reset),
                       .csb_i(mtime_csb),
                       .wen_i(data_wen_reg),
                       .clk_i(clk_i),
                       .addr_i(data_addr_o_reg[3:0]),
                       .data_i(core_data_o_reg),
                       .wmask_i(data_wmask_reg),
                       .mtip_o(mtip_o),
                       .data_o(mtime_data_o));

uart #(.SYS_CLK_FREQ(SYS_CLK_FREQ), .BAUD(9600)) uart0
           (.clk_i(clk_i), .reset_i(reset), .rx_i(rx_i),
            .csb_i(uart_csb), .wen_i(data_wen_reg),
            .data_i(core_data_o_reg[7:0]),
            .wmask_i(data_wmask_reg),
            .tx_o(tx_o), .receive_irq(uart_rx_irq),
            .data_o(uart_data_o));

loader #(.SYS_CLK_FREQ(SYS_CLK_FREQ)) loader0
              (.clk_i(clk_i),
               .reset_i(reset_i),
               .uart_rx_irq(uart_rx_irq),
               .uart_rx_byte(uart_data_o[15:8]),
               .reset_o(loader_reset_o),
               .reset_cause_reg(loader_reg_o),
               .led1(led1),
               .led2(led2),
               .led3(led3),
               .led4(led4));

endmodule

