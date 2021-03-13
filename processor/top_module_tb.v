`timescale 1ns/1ps

module top_module_tb();

reg reset_i, clk_i;
wire irq_ack_o;
reg meip_i;

top_module uut(.reset_i(reset_i), .clk_i(clk_i), .meip_i(meip_i), .irq_ack_o(irq_ack_o));

always begin
clk_i = 1'b0; #5; clk_i = 1'b1; #5;
end

initial begin
//$readmemh("../memory_contents/bubble_sort_irq.data",uut.memory.mem);
//$readmemh("../memory_contents/bubble_sort.data",uut.memory.mem);
$readmemh("../memory_contents/aes_test.data",uut.memory.mem);

reset_i = 1'b0; meip_i = 1'b0;
#200;
reset_i = 1'b1;

#2100; meip_i=1'b1; 
#400;  meip_i=1'b1; 
#400;  meip_i=1'b1; 
#400;  meip_i=1'b1;
#850;  meip_i=1'b1;
#316;  meip_i=1'b1;
#763;  meip_i=1'b1;
#152;  meip_i=1'b1;
#761;  meip_i=1'b1;
#252;  meip_i=1'b1;
end


always @(posedge clk_i)
begin
	if(irq_ack_o)
		meip_i = 1'b0;
end

endmodule

