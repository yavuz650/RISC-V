

module debug_interface(input         reset_i,
                       input         clk_i,
                       input         csb_i,

                       input  [31:0] data_i,      //data memory input
                       input         data_wen_i); //data memory write enable output

always @(posedge clk_i or negedge reset_i)
begin
	if(!reset_i) begin end

	else
	begin
		if(!csb_i && !data_wen_i)
		begin
			if(data_i == 32'b1)
			begin
				$display("Success!");
				$finish;
			end
				
			else
			begin
				$display("Failure!");
				$finish;
			end
		end
	end
end

endmodule
