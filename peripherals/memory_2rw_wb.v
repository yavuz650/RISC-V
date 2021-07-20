
module memory_2rw_wb(
input         port0_wb_cyc_i,
input         port0_wb_stb_i,
input         port0_wb_we_i,
input [31:0]  port0_wb_adr_i,
input [31:0]  port0_wb_dat_i,
input [3:0]   port0_wb_sel_i,
output        port0_wb_stall_o,
output        port0_wb_ack_o,
output reg [31:0] port0_wb_dat_o,
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
output reg [31:0] port1_wb_dat_o,
output        port1_wb_err_o,
input         port1_wb_rst_i,
input         port1_wb_clk_i);

parameter NUM_WMASKS = 4 ;
parameter DATA_WIDTH = 32 ;
parameter ADDR_WIDTH = 9 ;
parameter RAM_DEPTH = 1 << ADDR_WIDTH;

wire clk0; // clock
wire cs0; // active low chip select
wire we0; // active low write control
wire [NUM_WMASKS-1:0] wmask0; // write mask
wire [ADDR_WIDTH-1:0] addr0;
wire [DATA_WIDTH-1:0] din0;
wire [DATA_WIDTH-1:0] dout0;
wire clk1; // clock
wire cs1; // active low chip select
wire we1; // active low write control
wire [NUM_WMASKS-1:0] wmask1; // write mask
wire [ADDR_WIDTH-1:0] addr1;
wire [DATA_WIDTH-1:0] din1;
wire [DATA_WIDTH-1:0] dout1;

assign clk0 = port0_wb_clk_i;
assign cs0 = ~port0_wb_stb_i;
assign we0 = ~port0_wb_we_i;
assign wmask0 = port0_wb_sel_i;
assign addr0 = port0_wb_adr_i[ADDR_WIDTH+1 : 2];
assign din0 = port0_wb_dat_i;
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
assign cs1 = ~port1_wb_stb_i;
assign we1 = ~port1_wb_we_i;
assign wmask1 = port1_wb_sel_i;
assign addr1 = port1_wb_adr_i[ADDR_WIDTH+1 : 2];
assign din1 = port1_wb_dat_i;
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

reg [DATA_WIDTH-1:0] mem [0:RAM_DEPTH-1] /*verilator public*/;

`ifdef FPGA_READMEM
initial $readmemh("reset_handler.mem",mem,7424,7487);
initial $readmemh("bootloader.mem",mem,7488,8191);
`endif

  // Memory Write Block Port 0
  // Write Operation : When we0 = 0, cs0 = 0
always @ (posedge clk0)
begin
    if ( !cs0 && !we0 )
    begin
        if (wmask0[0])
            mem[addr0][7:0] = din0[7:0];
        if (wmask0[1])
            mem[addr0][15:8] = din0[15:8];
        if (wmask0[2])
            mem[addr0][23:16] = din0[23:16];
        if (wmask0[3])
            mem[addr0][31:24] = din0[31:24];
    end
end

  // Memory Read Block Port 0
  // Read Operation : When we0 = 1, cs0 = 0
always @ (posedge clk0)
begin
    if (!cs0 && we0)
        port0_wb_dat_o <= mem[addr0];
end

  // Memory Write Block Port 1
  // Write Operation : When we1 = 0, cs1 = 0
always @ (posedge clk1)
begin
    if ( !cs1 && !we1 ) begin
        if (wmask1[0])
            mem[addr1][7:0] = din1[7:0];
        if (wmask1[1])
            mem[addr1][15:8] = din1[15:8];
        if (wmask1[2])
            mem[addr1][23:16] = din1[23:16];
        if (wmask1[3])
            mem[addr1][31:24] = din1[31:24];
    end
end

  // Memory Read Block Port 1
  // Read Operation : When we1 = 1, cs1 = 0
always @ (posedge clk1)
begin : MEM_READ1
    if (!cs1 && we1)
        port1_wb_dat_o <= mem[addr1];
end

endmodule
