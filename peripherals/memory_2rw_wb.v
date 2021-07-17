module memory_2rw_wb(
input         port0_wb_cyc_i,
input         port0_wb_stb_i,
input         port0_wb_we_i,
input [31:0]  port0_wb_adr_i,
input [31:0]  port0_wb_dat_i,
input [3:0]   port0_wb_sel_i,
output        port0_wb_stall_o,
output        port0_wb_ack_o,
output [31:0] port0_wb_dat_o,
output        port0_wb_err_o,
input         port0_wb_rst_i,
input         port0_wb_clk_i,

input         port1_wb_cyc_i,
input         port1_wb_stb_i,
input         port1_wb_we_i,
input [31:0]  port1_wb_adr_i,
input [31:0]  port1_wb_dat_i,
input [3:0]   port1_wb_sel_i,
output        port1_wb_stall_o,
output        port1_wb_ack_o,
output [31:0] port1_wb_dat_o,
output        port1_wb_err_o,
input         port1_wb_rst_i,
input         port1_wb_clk_i);

parameter NUM_WMASKS = 4 ;
parameter DATA_WIDTH = 32 ;
parameter ADDR_WIDTH = 9 ;
parameter RAM_DEPTH = 1 << ADDR_WIDTH;

wire clk0; // clock
wire csb0; // active low chip select
wire web0; // active low write control
wire [NUM_WMASKS-1:0] wmask0; // write mask
wire [ADDR_WIDTH-1:0] addr0;
wire [DATA_WIDTH-1:0] din0;
wire [DATA_WIDTH-1:0] dout0;
wire clk1; // clock
wire csb1; // active low chip select
wire web1; // active low write control
wire [NUM_WMASKS-1:0] wmask1; // write mask
wire [ADDR_WIDTH-1:0] addr1;
wire [DATA_WIDTH-1:0] din1;
wire [DATA_WIDTH-1:0] dout1;

assign clk0 = port0_wb_clk_i;
assign csb0 = ~port0_wb_stb_i;
assign web0 = ~port0_wb_we_i;
assign wmask0 = port0_wb_sel_i;
assign addr0 = port0_wb_adr_i[ADDR_WIDTH+1 : 2];
assign din0 = port0_wb_dat_i;
assign port0_wb_dat_o = dout0;
assign port0_wb_stall_o = 1'b0;
reg port0_ack;
always @(posedge port0_wb_clk_i or posedge port0_wb_rst_i) 
begin
    if(port0_wb_rst_i)
        port0_ack <= 1'b0;
    else if(port0_wb_cyc_i)
        port0_ack <= port0_wb_stb_i;  
end
assign port0_wb_ack_o = port0_ack;
assign port0_wb_err_o = 1'b0;

assign clk1 = port1_wb_clk_i;
assign csb1 = ~port1_wb_stb_i;
assign web1 = ~port1_wb_we_i;
assign wmask1 = port1_wb_sel_i;
assign addr1 = port1_wb_adr_i[ADDR_WIDTH+1 : 2];
assign din1 = port1_wb_dat_i;
assign port1_wb_dat_o = dout1;
assign port1_wb_stall_o = 1'b0;
reg port1_ack;
always @(posedge port1_wb_clk_i or posedge port1_wb_rst_i) 
begin
    if(port1_wb_rst_i)
        port1_ack <= 1'b0;
    else if(port1_wb_cyc_i)
        port1_ack <= port1_wb_stb_i;  
end
assign port1_wb_ack_o = port1_ack;
assign port1_wb_err_o = 1'b0;

memory_2rw #(.NUM_WMASKS(NUM_WMASKS),
             .DATA_WIDTH(DATA_WIDTH),
             .ADDR_WIDTH(ADDR_WIDTH),
             .RAM_DEPTH(RAM_DEPTH))
      memory(.clk0(clk0), .csb0(csb0), .web0(web0), .wmask0(wmask0), .addr0(addr0), .din0(din0), .dout0(dout0),
             .clk1(clk1), .csb1(csb1), .web1(web1), .wmask1(wmask1), .addr1(addr1), .din1(din1), .dout1(dout1));



endmodule
