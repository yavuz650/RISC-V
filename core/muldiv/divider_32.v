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
	wire A;
	wire [31:0] Rin, Rout, R;
	wire Q;

	//Control Signals
	wire [4:0] mux_A_sel;
	wire mux_Rin_sel;
	wire reg_Rin_en;
	wire reg_Q_en;


	//Registers
	reg [31:0] reg_R, reg_Q;


	div_control div_control(start, clk, reset, mux_A_sel, mux_Rin_sel, reg_Rin_en, reg_Q_en, rdy);

	div_block div_block(A, divisor, Rin, Rout, Q);

	assign A = dividend[31-mux_A_sel];
	
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
                    reg_Q[31:1] <= reg_Q[30:0];
                    reg_Q[0] <= Q;
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
	input A,
	input [31:0] B,
	input [31:0] Rin,
	output [31:0] Rout,
	output Q);

    div_array row_0({Rin[30:0], A}, B, Rout, Q);

endmodule


module div_control(
	input start,
	input clk,
	input reset,
	output reg [4:0] mux_A_sel,
	output reg mux_Rin_sel,
	output reg reg_Rin_en,
	output reg reg_Q_en,
	output reg rdy);

	parameter R1 = 1'b0, Rounds = 1'b1;

	reg current_state;
	reg next_state;
	reg [4:0] round_count;
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
			round_count <= 5'b0;
		else
		begin
			if(start_count)
				round_count <= round_count + 1;
			else
				round_count <= 5'b0;			
		end
	end

	always @* begin

    	case(current_state)
	    	R1: begin

	       		mux_A_sel = 5'b0;
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
	       		if(round_count != 5'd31) begin

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
	           	mux_A_sel = 5'b0;
	           	rdy_b4_delay = 0;
	           	mux_Rin_sel = 0;
	           	reg_Rin_en = 0;
	           	reg_Q_en = 0;
	       	end

        endcase
	end
endmodule
