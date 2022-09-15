`timescale 1ns/1ps

module M_1
    # (
    parameter DATA_WIDTH = 32
    )
    (
    input [DATA_WIDTH - 1:0] X_i,
    input [DATA_WIDTH - 1:0] Y_i,
    output [DATA_WIDTH * 4 - 1:0] PPs_o
    );
    
    wire [DATA_WIDTH - 1:0] PPLL, PPLH, PPHL, PPHH;
    wire [DATA_WIDTH / 2 - 1:0] XL, XH, YL, YH;
    
    assign XL = X_i[DATA_WIDTH / 2 - 1:0];
    assign XH = X_i[DATA_WIDTH - 1:DATA_WIDTH / 2];
    assign YL = Y_i[DATA_WIDTH / 2 - 1:0];
    assign YH = Y_i[DATA_WIDTH - 1:DATA_WIDTH / 2];
    
    generate
        case(DATA_WIDTH)
            32: begin
                multiplier_16 LL(XL, YL, PPLL);
                multiplier_16 LH(XL, YH, PPLH);
                multiplier_16 HL(XH, YL, PPHL);
                multiplier_16 HH(XH, YH, PPHH);   
            end
            64: begin
                multiplier_32 LL(XL, YL, PPLL);
                multiplier_32 LH(XL, YH, PPLH);
                multiplier_32 HL(XH, YL, PPHL);
                multiplier_32 HH(XH, YH, PPHH);  
            end 
        endcase
    endgenerate   
    
    assign PPs_o = {PPHH, PPHL, PPLH, PPLL};
    
endmodule

module M_2
    # (
    parameter DATA_WIDTH = 32
    )
    (
    input [DATA_WIDTH * 4 - 1:0] PPs_i,
    output [DATA_WIDTH * 2 - 1:0] P_o
    );
    
    wire [DATA_WIDTH:0] PPLL, PPLH, PPHL, PPHH;
    
    assign PPLL = PPs_i[DATA_WIDTH - 1:0];
    assign PPLH = PPs_i[DATA_WIDTH * 2 - 1:DATA_WIDTH];
    assign PPHL = PPs_i[DATA_WIDTH * 3 - 1:DATA_WIDTH * 2];
    assign PPHH = PPs_i[DATA_WIDTH * 4 - 1:DATA_WIDTH * 3];
    
    assign P_o = (PPHH << DATA_WIDTH) + ((PPLH + PPHL) << (DATA_WIDTH / 2)) + PPLL;
    
endmodule

module M
    # (
    parameter DATA_WIDTH = 32
    )
    (
    input clk_i,
    input reset_i,
    input [DATA_WIDTH - 1:0] X_i,
    input [DATA_WIDTH - 1:0] Y_i,
    output [2 * DATA_WIDTH - 1:0] P_o
    );
    
    wire [DATA_WIDTH:0] PPLL, PPLH, PPHL, PPHH;
    wire [DATA_WIDTH / 2 - 1:0] XL, XH, YL, YH;
    reg [DATA_WIDTH:0] PPLL_reg, PPLH_reg, PPHL_reg, PPHH_reg;
    
    assign XL = X_i[DATA_WIDTH / 2 - 1:0];
    assign XH = X_i[DATA_WIDTH - 1:DATA_WIDTH / 2];
    assign YL = Y_i[DATA_WIDTH / 2 - 1:0];
    assign YH = Y_i[DATA_WIDTH - 1:DATA_WIDTH / 2];
    
    generate
        case(DATA_WIDTH)
            32: begin
                multiplier_16 LL(XL, YL, PPLL);
                multiplier_16 LH(XL, YH, PPLH);
                multiplier_16 HL(XH, YL, PPHL);
                multiplier_16 HH(XH, YH, PPHH);   
            end
            64: begin
                multiplier_32 LL(XL, YL, PPLL);
                multiplier_32 LH(XL, YH, PPLH);
                multiplier_32 HL(XH, YL, PPHL);
                multiplier_32 HH(XH, YH, PPHH);  
            end 
        endcase
    endgenerate   
    
    assign P_o = (PPHH_reg << DATA_WIDTH) + ((PPLH_reg + PPHL_reg) << (DATA_WIDTH / 2)) + PPLL_reg;
    
    always @ (posedge clk_i)
    begin
        if (reset_i == 0) begin
            PPLL_reg <= {DATA_WIDTH{1'b0}};
            PPLH_reg <= {DATA_WIDTH{1'b0}};
            PPHL_reg <= {DATA_WIDTH{1'b0}};
            PPHH_reg <= {DATA_WIDTH{1'b0}};
        end
        else begin
            PPLL_reg <= PPLL;
            PPLH_reg <= PPLH;
            PPHL_reg <= PPHL;
            PPHH_reg <= PPHH;          
        end
    end
    
endmodule
