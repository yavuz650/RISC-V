module MULDIV_in(
    input [31:0] in_A,
    input [31:0] in_B,
    input op_div0,
    input [1:0] op_mul,
    input muldiv_sel,
    output [5:0] AB_status,
    output [31:0] out_A,
    output [31:0] out_B,
    output [31:0] out_A_2C,
	output [31:0] out_B_2C
	);

    wire [31:0] A_2C, B_2C, A_s, B_s;
    wire [31:0] Dividend, Divisor, M_inA, M_inB;
    reg A0, B0, A1, B1, Am1, Bm1;

    assign A_2C = ~in_A + 1;
    assign B_2C = ~in_B + 1;

    assign A_s = in_A[31] ? A_2C : in_A;
    assign B_s = in_B[31] ? B_2C : in_B;

    assign Dividend = op_div0 ? in_A : A_s;
    assign Divisor = op_div0 ? in_B : B_s;

    assign M_inA = op_mul[1] ? (op_mul[0] ? in_A : A_s) : A_s;
    assign M_inB = op_mul[1] ? in_B : B_s;

    assign out_A = muldiv_sel ? Dividend : M_inA;
    assign out_B = muldiv_sel ? Divisor : M_inB;

	assign out_A_2C = A_2C;
	assign out_B_2C = B_2C;


	always @* begin
		case(in_A)
			32'd0: begin
				A0 = 1'b1;
				A1 = 1'b0;
				Am1 = 1'b0;
	       end

			32'd1: begin
				A0 = 1'b0;
				A1 = 1'b1;
				Am1 = 1'b0;
			end

			32'hffffffff: begin
			    A0 = 1'b0;
				A1 = 1'b0;
				if(muldiv_sel) begin
					if(op_div0)
						Am1 = 1'b0;
					else
						Am1 = 1'b1;
				end
				else begin
					if(op_mul != 2'b11)
						Am1 = 1'b1;
					else
						Am1 = 1'b0;
				end
			end

			default: begin
				A0 = 1'b0;
				A1 = 1'b0;
				Am1 = 1'b0;
			end
		endcase
	end

	always @* begin
		case(in_B)
			32'd0: begin
				B0 = 1'b1;
				B1 = 1'b0;
				Bm1 = 1'b0;
	       end

			32'd1: begin
				B0 = 1'b0;
				B1 = 1'b1;
				Bm1 = 1'b0;
			end

			32'hffffffff: begin
			    B0 = 1'b0;
				B1 = 1'b0;
				if(muldiv_sel) begin
					if(op_div0)
						Bm1 = 1'b0;
					else
						Bm1 = 1'b1;
				end
				else begin
					if(op_mul == 2'b00 || op_mul == 2'b01)
						Bm1 = 1'b1;
					else
						Bm1 = 1'b0;
				end
			end

			default: begin
				B0 = 1'b0;
				B1 = 1'b0;
				Bm1 = 1'b0;
			end
		endcase
	end


    assign AB_status = {Bm1, B1, B0, Am1, A1, A0};

endmodule
