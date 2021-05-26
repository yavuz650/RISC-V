`timescale 1ns / 1ps

module DIVout(
    input [31:0] Q,
    input [31:0] R,
    input Dividend32,
    input [31:0] Divisor_2C,
    input Divisor32,
    input [1:0] op_div,
    output [31:0] out_div);

    wire [31:0] Q_1C, Q_2C, Q_plus_1, Divisor_minus_R, out_Rs, out_Qs, out_Q, out_R;
    wire [1:0] signs;

    assign Q_1C = ~Q;
    assign Q_2C = Q_1C + 1;
    assign Q_plus_1 = Q + 1;
    assign Divisor_minus_R = Divisor_2C - R;

    assign signs = {Divisor32, Dividend32};
    assign out_Qs = signs[1] ? (signs[0] ? Q_plus_1 : Q_2C) : (signs[0] ? Q_1C : Q);
    assign out_Q = op_div[0] ? Q : out_Qs;

    assign out_Rs = signs[1] ? Divisor_minus_R : (signs[0] ? Divisor_minus_R : R);
    assign out_R = op_div[0] ? R : out_Rs;

    assign out_div = op_div[1] ? out_R : out_Q;

endmodule

module MULout(
    input [63:0] P,
    input M_inA32,
    input M_inB32,
    input [1:0] op_mul,
    output [31:0] out_mul
    );

    wire [63:0] P_2C, P_s, P_su;
    wire [1:0] signs;

    assign P_2C = ~P + 1;

    assign signs = {M_inA32, M_inB32};

    assign P_s = signs[1] ? (signs[0] ? P : P_2C) : (signs[0] ? P_2C : P);
    assign P_su = signs[1] ? P_2C : P;


    assign out_mul = op_mul[1] ? (op_mul[0] ? P[63:32] : P_su[63:32]) : (op_mul[0] ? P_s[63:32] : P_s[31:0]);

endmodule
