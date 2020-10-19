`timescale 1ns/10ps

`include  "/vlsi/kits/tsmc/lib/40lp/TSMCHOME/digital/Front_End/verilog/tcbn40lpbwp_200a/tcbn40lpbwp.v"

module top_module_tb();

reg reset_i, clk_i;
wire [55:0] mems;

top_module uut(.reset_i(reset_i), .clk_i(clk_i));
initial $sdf_annotate("top_module.sdf", uut, , ,  "maximum");

always begin
clk_i = 1'b0; #10; clk_i = 1'b1; #10;
end

initial begin
reset_i = 1'b1; #10; reset_i = 1'b0; #20; reset_i = 1'b1;
end

endmodule
