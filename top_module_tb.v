`timescale 1ns/10ps

module top_module_tb();

reg reset_i, clk_i;

top_module uut(.reset_i(reset_i), .clk_i(clk_i));

always begin
clk_i = 1'b0; #10; clk_i = 1'b1; #10;
end

initial begin
reset_i = 1'b1; #10; reset_i = 1'b0; #20; reset_i = 1'b1;
end

endmodule
