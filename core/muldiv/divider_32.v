`timescale 1ns / 1ps

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
	wire [3:0] A;
	wire [31:0] Rin, Rout, R;
	wire [3:0] Q;
	
	//Control Signals	
	wire [2:0] mux_A_sel;	
	wire mux_Rin_sel;
	wire reg_Rin_en;
	wire reg_Q_en;

	
	//Registers	
	reg [31:0] reg_R, reg_Q;
		
	
	div_control div_control(start, clk, mux_A_sel, mux_Rin_sel, reg_Rin_en, reg_Q_en, rdy);
	
	div_block div_block(A, divisor, Rin, Rout, Q);
	
	assign A = mux_A_sel == 3'd0 ? dividend[31:28]
			 : mux_A_sel == 3'd1 ? dividend[27:24]
			 : mux_A_sel == 3'd2 ? dividend[23:20]
			 : mux_A_sel == 3'd3 ? dividend[19:16]
			 : mux_A_sel == 3'd4 ? dividend[15:12]
			 : mux_A_sel == 3'd5 ? dividend[11:8]
			 : mux_A_sel == 3'd6 ? dividend[7:4]
			 : dividend[3:0];
	
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
                    
                if (reg_Q_en == 1) begin
                    reg_Q[31:4] <= reg_Q[27:0];
                    reg_Q[3:0] <= Q;
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
	
	assign r_temp = a - b;
	
	assign q = ~r_temp[32];
	
	assign r = q ? r_temp[31:0] : a;
	
endmodule

module div_block(
	input [3:0] A,
	input [31:0] B,
	input [31:0] Rin,  
	output [31:0] Rout,
	output [3:0] Q);
	
	wire [31:0] r[0:2];
		
	div_array row_0({Rin[30:0], A[3]}, B, r[0], Q[3]);
	div_array row_1({r[0][30:0], A[2]}, B, r[1], Q[2]);
	div_array row_2({r[1][30:0], A[1]}, B, r[2], Q[1]);
	div_array row_3({r[2][30:0], A[0]}, B, Rout, Q[0]);

endmodule
		

module div_control(
	input start,
	input clk,
	output reg [2:0] mux_A_sel,
	output reg mux_Rin_sel,
	output reg reg_Rin_en,
	output reg reg_Q_en,
	output reg rdy);
	
	parameter R1 = 3'h0, R2 = 3'h1, R3 = 3'h2, R4 = 3'h3,
	          R5 = 3'h4, R6 = 3'h5, R7 = 3'h6, R8 = 3'h7; 
	
	reg [2:0] current_state;
	reg [2:0] next_state;
	reg rdy_b4_delay;
	
	always @ (posedge clk) begin
	   current_state <= next_state;
	   rdy <= rdy_b4_delay;  
	end
	   
	always @ (current_state, start) begin      
	
        case(current_state)
	       R1: begin
	           mux_A_sel = 3'b000;
	           mux_Rin_sel = 0;
	           rdy_b4_delay = 0;
	           
	           if(start) begin
	               next_state = R2;
	               reg_Rin_en = 1;
	               reg_Q_en = 1;
	           end
	           
	           else begin
	               next_state = R1;
	               reg_Rin_en = 0;
	               reg_Q_en = 0;
	           end
	       end
	       
	       R2: begin
	           next_state = R3;
	           mux_A_sel = 3'b001;
	           mux_Rin_sel = 1;
	           reg_Rin_en = 1;
	           reg_Q_en = 1;
	           rdy_b4_delay = 0;
	       end
	       
	       R3: begin
	           next_state = R4;
	           mux_A_sel = 3'b010;
	           mux_Rin_sel = 1;
	           reg_Rin_en = 1;
	           reg_Q_en = 1;
	           rdy_b4_delay = 0;
	       end
	       
	       R4: begin
	           next_state = R5;
	           mux_A_sel = 3'b011;
	           mux_Rin_sel = 1;
	           reg_Rin_en = 1;
	           reg_Q_en = 1;
	           rdy_b4_delay = 0;
	       end
	       
	       R5: begin
	           next_state = R6;
	           mux_A_sel = 3'b100;
	           mux_Rin_sel = 1;
	           reg_Rin_en = 1;
	           reg_Q_en = 1;
	           rdy_b4_delay = 0;
	       end
	       
	       R6: begin
	           next_state = R7;
	           mux_A_sel = 3'b101;
	           mux_Rin_sel = 1;
	           reg_Rin_en = 1;
	           reg_Q_en = 1;
	           rdy_b4_delay = 0;
	       end
	       
	       R7: begin
	           next_state = R8;
	           mux_A_sel = 3'b110;
	           mux_Rin_sel = 1;
	           reg_Rin_en = 1;
	           reg_Q_en = 1;
	           rdy_b4_delay = 0;
	       end
	       
	       R8: begin
	           next_state = R1;
	           mux_A_sel = 3'b111;
	           rdy_b4_delay = 1;
	           mux_Rin_sel = 1;
	           reg_Rin_en = 1;
	           reg_Q_en = 1;
	       end
	       
	       default: begin
	           next_state = R1;
	           mux_A_sel = 3'b000;
	           rdy_b4_delay = 0;
	           mux_Rin_sel = 0;
	           reg_Rin_en = 0;
	           reg_Q_en = 0;
	       end

        endcase 
		
	end
	
endmodule


