module divider_32(
	input clk,
	input start,
	input reset,
	input [31:0] dividend,
	input [31:0] divisor,
	output rdy,
	output [63:0] div_out);

	wire [31:0] Q32;

	//DividerBlock Signals
	wire [1:0] A;
	wire [31:0] Rin, Rout, R;
	wire [1:0] Q;

	//Control Signals
	wire [3:0] mux_A_sel;
	wire mux_Rin_sel;
	wire reg_Rin_en;
	wire reg_Q_en;


	//Registers
	reg [31:0] reg_R, reg_Q;


	div_control div_control(start, clk, reset, mux_A_sel, mux_Rin_sel, reg_Rin_en, reg_Q_en, rdy);

	div_block div_block(A, divisor, Rin, Rout, Q);

	assign A = mux_A_sel == 4'd0 ? dividend[31:30]
			 : mux_A_sel == 4'd1 ? dividend[29:28]
			 : mux_A_sel == 4'd2 ? dividend[27:26]
			 : mux_A_sel == 4'd3 ? dividend[25:24]
			 : mux_A_sel == 4'd4 ? dividend[23:22]
			 : mux_A_sel == 4'd5 ? dividend[21:20]
			 : mux_A_sel == 4'd6 ? dividend[19:18]
			 : mux_A_sel == 4'd7 ? dividend[17:16]
			 : mux_A_sel == 4'd8 ? dividend[15:14]
			 : mux_A_sel == 4'd9 ? dividend[13:12]
			 : mux_A_sel == 4'd10 ? dividend[11:10]
			 : mux_A_sel == 4'd11 ? dividend[9:8]
			 : mux_A_sel == 4'd12 ? dividend[7:6]
			 : mux_A_sel == 4'd13 ? dividend[5:4]
			 : mux_A_sel == 4'd14 ? dividend[3:2]
			 : dividend[1:0];

	assign Rin = mux_Rin_sel ? reg_R : 32'd0;

	assign Q32 = reg_Q;

	assign R = reg_R;

	assign div_out = {Q32, R};

	always @ (posedge clk or negedge reset) begin

	   if(!reset) begin
	       reg_R <= 32'd0;
           reg_Q <= 32'd0;
	   end

	   else begin
            if (start == 0) begin
                reg_R <= 32'd0;
                reg_Q <= 32'd0;
            end

            else begin
                if (reg_Rin_en == 1)
                    reg_R <= Rout;
                else
                	reg_R <= reg_R;

                if (reg_Q_en == 1) begin
                    reg_Q[31:2] <= reg_Q[29:0];
                    reg_Q[1:0] <= Q;
                end else
                    reg_Q <= reg_Q;
            end
        end
	end

endmodule


module div_array(
	input [31:0] a,
	input [31:0] b,
	output [31:0] r,
	output q);

	wire [32:0] r_temp;
	wire q_temp;

	assign r_temp = a - b;

	assign q_temp = ~r_temp[32];

	assign r = q_temp ? r_temp[31:0] : a;

	assign q = q_temp;

endmodule

module div_block(
	input [1:0] A,
	input [31:0] B,
	input [31:0] Rin,
	output [31:0] Rout,
	output [1:0] Q);

	wire [31:0] r;

	div_array row_0({Rin[30:0], A[1]}, B, r, Q[1]);
	div_array row_1({r[30:0], A[0]}, B, Rout, Q[0]);

endmodule


module div_control(
	input start,
	input clk,
	input reset,
	output reg [3:0] mux_A_sel,
	output reg mux_Rin_sel,
	output reg reg_Rin_en,
	output reg reg_Q_en,
	output reg rdy);

	parameter R1 = 1'b0, Rounds = 1'b1;

	reg current_state;
	reg next_state;
	reg [3:0] round_count;
	reg start_count, rdy_b4_delay;

	always @ (posedge clk or negedge reset) begin
		if(!reset) begin
			current_state <= 1'b0;
			rdy <= 1'b0;	
		end
		else begin
			current_state <= next_state;
			rdy <= rdy_b4_delay;			
		end
	end

	always @ (posedge clk or negedge reset) begin
		if(!reset)
			round_count <= 4'b0;
		else
		begin
			if(start_count)
				round_count <= round_count + 1;
			else
				round_count <= 4'b0;			
		end
	end

	always @* begin

    	case(current_state)
	    	R1: begin

	       		mux_A_sel = 4'b0;
	           	mux_Rin_sel = 1'b0;
	           	rdy_b4_delay = 1'b0;

	    		if(start) begin
	           	   	start_count = 1'b1;
	               	reg_Rin_en = 1'b1;
	               	reg_Q_en = 1'b1;
	               	next_state = Rounds;
	           	end

	           	else begin
	           		start_count = 1'b0;
	               	reg_Rin_en = 1'b0;
	               	reg_Q_en = 1'b0;
	               	next_state = R1;
	           	end
	       	end

	       	Rounds: begin
	       		if(round_count != 4'b1111) begin

			   		mux_A_sel = round_count;
			   		start_count = 1'b1;
			   		mux_Rin_sel = 1'b1;
			       	reg_Rin_en = 1'b1;
			       	reg_Q_en = 1'b1;
			       	rdy_b4_delay = 1'b0;
			       	next_state = Rounds;
	           	end

	           	else begin
	           		mux_A_sel = round_count;
	           		start_count = 1'b0;
			   		mux_Rin_sel = 1'b1;
			       	reg_Rin_en = 1'b1;
			       	reg_Q_en = 1'b1;
			       	rdy_b4_delay = 1'b1;
			       	next_state = R1;
	           	end
	       	end


	       	default: begin
	           	next_state = R1;
	           	mux_A_sel = 4'b0;
	           	rdy_b4_delay = 0;
	           	mux_Rin_sel = 0;
	           	reg_Rin_en = 0;
	           	reg_Q_en = 0;
	       	end

        endcase
	end
endmodule
