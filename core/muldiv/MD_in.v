`timescale 1ns/1ps

module MD_in
    # (
    parameter DATA_WIDTH = 32
    )
    (
    input [DATA_WIDTH - 1:0] X_i,
    input [DATA_WIDTH - 1:0] Y_i,
    input [3:0] md_op_i, //hardwire md_op_i[3] to zero if the core is RV32
   
    output [DATA_WIDTH - 1:0] X_o,
    output [DATA_WIDTH - 1:0] Y_o,
    
    output reg [DATA_WIDTH - 1:0] d_exception_result_o,
    output reg d_exception_o
	);

    
    wire [DATA_WIDTH - 1:0] X_2C, Y_2C;           // 2's complemented operands
    wire [DATA_WIDTH - 1:0] X_US, Y_US;           // unsigned version of the signed operands

      
    ////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////
    
    // 2's Complemented operands assignemnt
    assign X_2C = ~X_i + 1;
    assign Y_2C = ~Y_i + 1;

    // unsigned Operands
    assign X_US = X_i[DATA_WIDTH - 1] ? X_2C : X_i;
    assign Y_US = Y_i[DATA_WIDTH - 1] ? Y_2C : Y_i;

    // output assignment w.r.t. current instruction
    assign X_o = (md_op_i[3] && DATA_WIDTH == 64) ?
    (md_op_i[2] ? (md_op_i[0] ? {32'd0, X_i[31:0]} : {32'd0, X_US[31:0]}) : {32'd0, X_US[31:0]}) :
    (md_op_i[2] ? (md_op_i[0] ? X_i : X_US) : 
    (md_op_i[1] ? (md_op_i[0] ? X_i : X_US) : X_US));
    
    assign Y_o = (md_op_i[3] && DATA_WIDTH == 64) ?
    (md_op_i[2] ? (md_op_i[0] ? {32'd0, Y_i[31:0]} : {32'd0, Y_US[31:0]}) : {32'd0, Y_US[31:0]}) :
    (md_op_i[2] ? (md_op_i[0] ? Y_i : Y_US) : 
    (md_op_i[1] ? Y_i : Y_US));
	
	always @* begin	
        if(Y_i == {DATA_WIDTH{1'b0}}) begin
            d_exception_o = 1'b1;
            if(md_op_i[1] == 2'b1)
                d_exception_result_o = X_i;
            else if(md_op_i[1:0] == 2'b00)
                d_exception_result_o = {DATA_WIDTH{1'b1}};
            else if(md_op_i[1:0] == 2'b01) begin
                if(md_op_i[3] == 1'b1) begin
                    d_exception_result_o = 64'h00000000ffffffff;
                end else begin
                    d_exception_result_o = -64'd1;            
                end
            end
            else begin
                d_exception_result_o = {DATA_WIDTH{1'b0}};
            end                                  
        end
        else if((md_op_i[3] == 1'b0) && (X_i == {{1'b1}, {DATA_WIDTH{1'b0}}}) && (Y_i == {DATA_WIDTH{1'b1}})) begin
            d_exception_o = 1'b1;
            if(md_op_i[1] == 1'b0)
                d_exception_result_o = {{1'b1}, {DATA_WIDTH{1'b0}}}; 
            else begin
                d_exception_result_o = {DATA_WIDTH{1'b0}};  
            end
        end
        else if(((md_op_i[3] == 1'b1) && (X_i[31:0] == 32'h80000000) && (Y_i[31:0] == -32'd1)) && DATA_WIDTH == 64)  begin
            d_exception_o = 1'b1;
            if(md_op_i[1] == 1'b0)
                d_exception_result_o = 64'hffffffff80000000; 
            else 
                d_exception_result_o = 64'd0; 
        end
        else begin
            d_exception_o = 1'b0;
            d_exception_result_o = {DATA_WIDTH{1'b0}};    
        end
    end                                                 
endmodule