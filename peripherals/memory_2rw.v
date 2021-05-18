
module memory_2rw(
// Port 0: RW
    clk0,csb0,web0,wmask0,addr0,din0,dout0,
// Port 1: RW
    clk1,csb1,web1,wmask1,addr1,din1,dout1
  );

  parameter NUM_WMASKS = 4 ;
  parameter DATA_WIDTH = 32 ;
  parameter ADDR_WIDTH = 9 ;
  parameter RAM_DEPTH = 1 << ADDR_WIDTH;
  parameter DELAY = 3 ;

  input  clk0; // clock
  input   csb0; // active low chip select
  input  web0; // active low write control
  input [NUM_WMASKS-1:0]   wmask0; // write mask
  input [ADDR_WIDTH-1:0]  addr0;
  input [DATA_WIDTH-1:0]  din0;
  output reg [DATA_WIDTH-1:0] dout0;
  input  clk1; // clock
  input   csb1; // active low chip select
  input  web1; // active low write control
  input [NUM_WMASKS-1:0]   wmask1; // write mask
  input [ADDR_WIDTH-1:0]  addr1;
  input [DATA_WIDTH-1:0]  din1;
  output reg [DATA_WIDTH-1:0] dout1;


reg [DATA_WIDTH-1:0]    mem [0:RAM_DEPTH-1] /*verilator public*/;
  // Memory Write Block Port 0
  // Write Operation : When web0 = 0, csb0 = 0
  always @ (posedge clk0)
  begin
    if ( !csb0 && !web0 ) begin
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
  // Read Operation : When web0 = 1, csb0 = 0
  always @ (posedge clk0)
  begin
    if (!csb0 && web0)
       dout0 <= mem[addr0];
  end

  // Memory Write Block Port 1
  // Write Operation : When web1 = 0, csb1 = 0
  always @ (posedge clk1)
  begin
    if ( !csb1 && !web1 ) begin
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
  // Read Operation : When web1 = 1, csb1 = 0
  always @ (posedge clk1)
  begin : MEM_READ1
    if (!csb1 && web1)
       dout1 <= mem[addr1];
  end
  
   /* specify
        (posedge clk0 *> (dout0 : din0)) = (1.0, 1.0);
        (posedge clk1 *> (dout1 : clk1)) = (1.0, 1.0);
        (negedge clk0 *> (dout0 : clk0)) = (1.0, 1.0);
        (negedge clk1 *> (dout1 : din1)) = (1.0, 1.0);
  endspecify*/

endmodule
