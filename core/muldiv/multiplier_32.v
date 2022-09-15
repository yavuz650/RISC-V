`timescale 1ns/1ps

module multiplier_32(
    input [31:0] X,
    input [31:0] Y,
    output [63:0] P
    );
    
    wire [31:0] PP32LL, PP32LH, PP32HL, PP32HH;
    wire [15:0] XL, XH, YL, YH;
    
    assign XL = X[15:0];
    assign XH = X[31:16];
    assign YL = Y[15:0];
    assign YH = Y[31:16];
    
    multiplier_16 LL(XL, YL, PP32LL);
    multiplier_16 LH(XL, YH, PP32LH);
    multiplier_16 HL(XH, YL, PP32HL);
    multiplier_16 HH(XH, YH, PP32HH);
    
    assign P = (PP32HH << 32) + ((PP32LH + PP32HL) << 16) + PP32LL;
    
endmodule
