`timescale 1ns/1ps

module uart_top_tb();

reg reset_i, clk_i;
wire irq_ack_o;
wire tx_o;
reg rx_i;
uart_top uut(.reset_i(reset_i), .clk_i(clk_i), .tx_o(tx_o), .rx_i(rx_i), .irq_ack_o(irq_ack_o));

always begin
clk_i = 1'b0; #5; clk_i = 1'b1; #5;
end

initial begin

$readmemh("../../memory_contents/uart_test.data",uut.memory.mem);

reset_i = 1'b0; rx_i = 1'b1;
#200;
reset_i = 1'b1;

end

endmodule

