module debug_interface_wb(input         wb_cyc_i,
                          input         wb_stb_i,
                          input         wb_we_i,
                          input [31:0]  wb_adr_i,
                          input [31:0]  wb_dat_i,
                          input [3:0]   wb_sel_i,
                          output        wb_stall_o,
                          output        wb_ack_o,
                          output [31:0] wb_dat_o,
                          output        wb_err_o,
                          input         wb_rst_i,
                          input         wb_clk_i);

assign wb_stall_o = 1'b0;
assign wb_dat_o = 32'b0;
assign wb_err_o = 1'b0;
reg ack;
always @(posedge wb_clk_i or posedge wb_rst_i) 
begin
    if(wb_rst_i)
        ack <= 1'b0;
    else
        ack <= wb_stb_i;  
end
assign wb_ack_o = ack;

always @(posedge wb_clk_i or posedge wb_rst_i)
begin
	if(wb_rst_i) begin end

	else
	begin
		if(wb_cyc_i && wb_stb_i && wb_we_i)
		begin
			if(wb_dat_i == 32'b1)
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
