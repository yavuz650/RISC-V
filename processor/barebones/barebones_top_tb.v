`timescale 1ns/1ps

module barebones_top_tb();

reg reset_i, clk_i;
wire irq_ack_o;
reg meip_i;
reg [15:0] fast_irq_i;

barebones_top uut(.reset_i(reset_i), .clk_i(clk_i), .meip_i(meip_i), .fast_irq_i(fast_irq_i), .irq_ack_o(irq_ack_o));

always begin
clk_i = 1'b0; #5; clk_i = 1'b1; #5;
end

initial begin
//$readmemh("../../test/memory_contents/bubble_sort_irq.data",uut.memory.mem);
//$readmemh("../../test/memory_contents/bubble_sort.data",uut.memory.mem);
$readmemh("../../test/memory_contents/aes_test.data",uut.memory.mem);
//$readmemh("../../test/memory_contents/soft_float.data",uut.memory.mem);
reset_i = 1'b0; fast_irq_i = 16'b0; meip_i = 1'b0;
#200;
reset_i = 1'b1;

//interrupt signals, arbitrarily generated.
/*
#2100; fast_irq_i=1'b1; 
#400;  fast_irq_i=1'b1;
#400;  fast_irq_i=1'b1; 
#400;  fast_irq_i=1'b1;
#850;  fast_irq_i=1'b1;
#316;  fast_irq_i=1'b1;
#763;  fast_irq_i=1'b1;
#152;  fast_irq_i=1'b1;
#761;  fast_irq_i=1'b1;
#252;  fast_irq_i=1'b1;*/
fast_irq_i = 16'h1; #10; fast_irq_i = 16'h0; 
end

/*
always @(posedge clk_i)
begin
	if(irq_ack_o)
		fast_irq_i = 1'b0;
end*/

endmodule

