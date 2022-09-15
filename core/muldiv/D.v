`timescale 1ns/1ps

module divider_array
	# (
    parameter DATA_WIDTH = 32
    )
	(
	input [DATA_WIDTH - 1:0] x,
	input [DATA_WIDTH - 1:0] y,
	output [DATA_WIDTH - 1:0] r,
	output q);

	wire [DATA_WIDTH:0] r_temp;
	wire q_temp;

	assign r_temp = x - y;

	assign q_temp = ~r_temp[DATA_WIDTH];

	assign r = q_temp ? r_temp[DATA_WIDTH - 1:0] : x;

	assign q = q_temp;

endmodule

module divider_block_64
	# (
    parameter DATA_WIDTH = 32
    )
	(
	input X,
	input [DATA_WIDTH - 1:0] Y,
	input [DATA_WIDTH - 1:0] Rin,
	output [DATA_WIDTH - 1:0] Rout,
	output Q);

    divider_array # (
    	.DATA_WIDTH(DATA_WIDTH)
    ) row_0({Rin[DATA_WIDTH - 2:0], X}, Y, Rout, Q);

endmodule


module div_control(
	input start,
	input clk,
	input reset,
	input [6:0] div_count,
	output reg [4:0] mux_A_sel,
	output reg mux_Rin_sel,
	output reg mux_smaller_X,
	output reg reg_Rin_en,
	output reg reg_Q_en,
	output reg rdy);

	parameter R1 = 1'b0, Rounds = 1'b1;

	reg state_reg, state_next;
	reg [6:0] counter_reg, counter_next;
	reg rdy_next;
	
       
	always @ (posedge clk) begin
		if(!reset) begin
			state_reg <= 1'b0;
			rdy <= 1'b0;
			counter_reg <= 7'd0;
		end
		else begin
			if(start) begin
			state_reg <= state_next;
			rdy <= rdy_next;
			counter_reg <= counter_next;	
			end else begin
				state_reg <= 1'b0;
				rdy <= 1'b0;
				counter_reg <= 7'd0;
			end		
		end
	end


	always @* begin
    	case(state_reg)
	    	R1: begin
	       		mux_A_sel = div_count;
	           	mux_Rin_sel = 1'b0;	           	
	    		if(start == 1'b1) begin
                    if(div_count[6] == 1'b1) begin
                        counter_next = 7'd0;
                        rdy_next = 1'b1;
                        reg_Rin_en = 1'b0;
	               	    reg_Q_en = 1'b0;
                        mux_smaller_X = 1'b1;
                        state_next = R1;     
                    end
                    else begin
                        rdy_next = 1'b0;
                        counter_next = div_count - 1;
                        reg_Rin_en = 1'b1;
                        reg_Q_en = 1'b1;
                        mux_smaller_X = 1'b0;
                        state_next = Rounds;
	               	end
	           	end
	           	else begin
    	           	counter_next = 7'd0;
	           	    rdy_next = 1'b0;                  
	               	reg_Rin_en = 1'b0;
	               	reg_Q_en = 1'b0;
	               	mux_smaller_X = 1'b0;
	               	state_next = R1;
	           	end
	       	end

	       	Rounds: begin
	       		if(counter_reg != 7'd0) begin
			   		mux_A_sel = counter_reg;
			   		counter_next = counter_reg - 1;
			   		rdy_next = 1'b0;
			   		mux_Rin_sel = 1'b1;
			       	reg_Rin_en = 1'b1;
			       	reg_Q_en = 1'b1;		       	
			       	mux_smaller_X = 1'b0;
			       	state_next = Rounds;
	           	end

	           	else begin
	           		mux_A_sel = counter_reg;
                    counter_next = 7'd0;
                    rdy_next = 1'b1;
			   		mux_Rin_sel = 1'b1;
			       	reg_Rin_en = 1'b1;
			       	reg_Q_en = 1'b1;			       	
			       	mux_smaller_X = 1'b0;
			       	state_next = R1;
	           	end
	       	end


	       	default: begin
	           	counter_next = 7'd0;
	           	mux_A_sel = 5'b0;
	           	rdy_next = 0;
	           	mux_Rin_sel = 0;
	           	reg_Rin_en = 0;
	           	reg_Q_en = 0;
	           	mux_smaller_X = 1'b0;
	           	state_next = R1;
	       	end

        endcase
	end
endmodule

module D
	# (
    parameter DATA_WIDTH = 32
    )
	(
	input clk_i,	
	input reset_i,
	input start_i,
	input [DATA_WIDTH - 1:0] X_i,
	input [DATA_WIDTH - 1:0] Y_i,
	output rdy_o,
	output [DATA_WIDTH * 2 - 1:0] QR_o);

	wire [DATA_WIDTH - 1:0] Q_final;
	wire rdy;

	//DividerBlock Signals
	wire X_1;
	wire [DATA_WIDTH - 1:0] Rin, Rout, R;
	wire Q;

	//Control Signals
	wire [4:0] mux_A_sel;
	wire mux_Rin_sel;
	wire reg_Rin_en;
	wire reg_Q_en;
	wire mux_smaller_X;

	wire [DATA_WIDTH - 1:0] X, Y; 

	//Registers
	reg [DATA_WIDTH - 1:0] reg_R, reg_Q;
	reg [DATA_WIDTH - 1:0] reg_X, reg_Y;
	reg delayed_start;

	// first_one signals
    wire [6:0] first_one_X, first_one_Y;
    wire [6:0] div_count;
    
    // first one
    first_one inst_first_one_X(.in((DATA_WIDTH == 64) ? X : {{32{1'b0}}, X}), .out(first_one_X));
    first_one inst_first_one_Y(.in((DATA_WIDTH == 64) ? Y : {{32{1'b0}}, Y}), .out(first_one_Y));
    
    assign div_count = first_one_X - first_one_Y;

	assign X = delayed_start ? reg_X : X_i;
	assign Y = delayed_start ? reg_Y : Y_i;

	div_control div_control(start_i, clk_i, reset_i, div_count, mux_A_sel, mux_Rin_sel, mux_smaller_X, reg_Rin_en, reg_Q_en, rdy);

	divider_block_64 # (
    	.DATA_WIDTH(DATA_WIDTH)
    ) divider_block(X_1, Y, Rin, Rout, Q);

	assign X_1 = X[mux_A_sel];
	
	assign Rin = mux_Rin_sel ? reg_R : (X >> (div_count + 1));

	assign Q_final = reg_Q;

	assign R = reg_R;

	assign QR_o = mux_smaller_X ? {{DATA_WIDTH{1'b0}}, Y} : {Q_final, R};
	
	assign rdy_o = mux_smaller_X ? 1'b1 : rdy;


	always @ (negedge clk_i) begin
		if(!reset_i) begin
			reg_X <= {DATA_WIDTH{1'b0}};
           	reg_Y <= {DATA_WIDTH{1'b0}};
		end else begin
			if(delayed_start) begin
				reg_X <= reg_X;
				reg_Y <= reg_Y;
			end else begin
				reg_X <= X_i;
				reg_Y <= Y_i;
			end
		end
	end

	always @ (posedge clk_i) begin
	   	if(!reset_i) begin
	       reg_R <= {DATA_WIDTH{1'b0}};
           reg_Q <= {DATA_WIDTH{1'b0}};
		   delayed_start <= 1'b0;
	   	end

	   	else begin
			delayed_start <= start_i;
			if (start_i == 0) begin
                reg_R <= {DATA_WIDTH{1'b0}};
                reg_Q <= {DATA_WIDTH{1'b0}};
            end

            else begin
                if (reg_Rin_en == 1)
                    reg_R <= Rout;
                else
                	reg_R <= reg_R;

                if (reg_Q_en == 1) begin
                    reg_Q[DATA_WIDTH - 1:1] <= reg_Q[DATA_WIDTH - 2:0];
                    reg_Q[0] <= Q;
                end else
                    reg_Q <= reg_Q;
            end
        end
	end

endmodule

