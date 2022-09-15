`timescale 1ns/1ps
/* verilator lint_off UNOPTFLAT */
module wallace_8(
    input  [7:0]  X, 
    input  [7:0]  Y,
    output [15:0] P
    );
    
    wire [15:0] S [0:5];
    wire [15:0] C [0:5];
    wire [15:0] XY [0:7];
    wire [15:0] X_15;
    
    assign X_15 = {8'd0, X};
    
    genvar i;
    for (i = 0; i < 8; i = i + 1) begin
        assign XY[i] = Y[i] ? (X_15 << i) : 15'd0;
    end 
    
    csa_16 csa_1(.x(XY[0]),     .y(XY[1]),      .z(XY[2]),      .s(S[0]), .c(C[0]));
    csa_16 csa_2(.x(XY[3]),     .y(XY[4]),      .z(XY[5]),      .s(S[1]), .c(C[1]));
    csa_16 csa_3(.x(S[0]),      .y(C[0]<<1),    .z(S[1]),       .s(S[2]), .c(C[2]));
    csa_16 csa_4(.x(C[1]<<1),   .y(XY[6]),      .z(XY[7]),      .s(S[3]), .c(C[3]));
    csa_16 csa_5(.x(S[2]),      .y(C[2]<<1),    .z(S[3]),       .s(S[4]), .c(C[4]));
    csa_16 csa_6(.x(S[4]),      .y(C[4]<<1),    .z(C[3]<<1),    .s(S[5]), .c(C[5]));
    
    
    
    assign P = S[5] + (C[5]<<1);
endmodule
