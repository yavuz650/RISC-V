`timescale 1ns/1ps

module multiplier_16(
    input [15:0] X,
    input [15:0] Y,
    output [31:0] P
    );
    
    wire [15:0] PP16LL, PP16LH, PP16HL, PP16HH;
    wire [7:0] XL, XH, YL, YH;
    
    assign XL = X[7:0];
    assign XH = X[15:8];
    assign YL = Y[7:0];
    assign YH = Y[15:8];
    
    wallace_8 LL(XL, YL, PP16LL);
    wallace_8 LH(XL, YH, PP16LH);
    wallace_8 HL(XH, YL, PP16HL);
    wallace_8 HH(XH, YH, PP16HH);
    
    assign P = (PP16HH << 16) + ((PP16LH + PP16HL) << 8) + PP16LL;
    
endmodule
