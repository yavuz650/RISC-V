`timescale 1ns/1ps
/* verilator lint_off UNOPTFLAT */
module first_one (
    input [63:0]in,
    output [6:0]out
    );

    wire [6:0]out_stage[0:64];
    assign out_stage[0] = 7'b1000000; 
    
    generate genvar i;
        for(i=0; i<64; i=i+1) begin
            assign out_stage[i+1] = in[i] ? i : out_stage[i];
        end
    endgenerate
    assign out = out_stage[63];

endmodule