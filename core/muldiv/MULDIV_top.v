module MULDIV_top (
    input clk,
    input start,
    input reset,
    input [31:0] in_A,
    input [31:0] in_B,
    input [1:0] op_div,
    input [1:0] op_mul,
    input muldiv_sel,
    output [31:0] R,
    output muldiv_done
	);

    wire [63:0] AB, P, QR, muldiv1, muldiv2;
    wire [31:0] out_A, out_B, out_A_2C, out_B_2C;
    wire [31:0] out_mul, out_div, muldiv_out;
    wire [5:0] AB_status;

    wire div_start, div_rdy;

    wire reg_AB_en, reg_muldiv_en, mux_muldiv_sel, mux_muldiv_out_sel, mux_fastres_sel;

    wire [31:0] fastres;

    reg [63:0] reg_AB, reg_muldiv;


    MULDIV_ctrl MULDIV_ctrl(clk, start, reset, muldiv_sel, AB_status, div_rdy, op_mul, op_div[1], in_A, in_B, out_A_2C, out_B_2C,
    div_start, reg_AB_en, reg_muldiv_en, mux_muldiv_sel, mux_muldiv_out_sel, mux_fastres_sel, fastres, muldiv_done);

    MULDIV_in MULDIV_in(in_A, in_B, op_div[0], op_mul, muldiv_sel,
    AB_status, out_A, out_B, out_A_2C, out_B_2C);

    assign AB = reg_AB;

    multiplier_32 MUL(clk, reset, AB[63:32], AB[31:0], P);
    divider_32 DIV(clk, div_start, reset, AB[63:32], AB[31:0], div_rdy, QR);

    assign muldiv1 = mux_muldiv_sel ? QR : P;

    assign muldiv2 = reg_muldiv;

    MULout MULout(muldiv2, in_A[31], in_B[31], op_mul, out_mul);
    DIVout DIVout(muldiv2[63:32], muldiv2[31:0], in_A[31], out_B, in_B[31], op_div, out_div);

    assign muldiv_out = mux_muldiv_out_sel ? out_div : out_mul;

    assign R = mux_fastres_sel ? fastres : muldiv_out;


    always @ (posedge clk or negedge reset) begin
        if(!reset) begin
            reg_AB <= 63'd0;
            reg_muldiv <= 63'd0;
        end

        else begin
            if(reg_AB_en) begin
                reg_AB[31:0] <= out_B;
                reg_AB[63:32] <= out_A;
            end

            if(reg_muldiv_en)
                reg_muldiv <= muldiv1;
        end
    end


endmodule
