`timescale 1ns/1ps

module barebones_top(input clk_i,
                     input reset_i,
                     input meip_i,
                     input [15:0] fast_irq_i,
                     output irq_ack_o);

//core data interface
wire [31:0] core_data_addr;
wire [31:0] core_data_out;
wire [31:0] core_data_in;
wire [3:0]  core_data_wmask;
wire        core_data_wen;
wire        core_data_req;
wire        core_data_err;
//core instruction interface
wire [31:0] core_instr_addr;
wire [31:0] core_instr_in;
wire        core_instr_access_fault;
//registered interface signals
reg [31:0] core_data_addr_reg;
reg [31:0] core_data_out_reg;
reg [3:0]  core_data_wmask_reg;
reg        core_data_wen_reg;
reg        core_data_req_reg;
reg [31:0] core_instr_addr_reg;

//memory data port
wire [31:0] mem_data_in;
wire [31:0] mem_data_out;
wire [31:0] mem_data_addr;
wire        mem_data_wen;
wire        mem_data_csb;
wire [3:0]  mem_data_wmask;
//memory instruction port
wire [31:0] mem_instr_out;
wire [31:0] mem_instr_addr;

//timer register signals
wire [31:0] mtime_data_out;

//chip-select signals, all active-low
wire ram_csb; //Read-Write region of memory
wire rom_csb; //Read-only region of memory
wire mem_csb; //Combination of RAM and ROM regions
wire mtime_csb; //Timer registers
wire debug_if_csb; //Debug interface 
reg ram_csb_reg;
reg rom_csb_reg;
reg mem_csb_reg;
reg mtime_csb_reg;
reg debug_if_csb_reg;

//timer interrupt signal
wire mtip;

//internal nets
wire masked_wen;
reg masked_wen_reg;

//0x0000_0000 to 0x0000_1DFF is ROM
assign rom_csb = !((core_data_addr[31:13] == 19'b0) & (core_data_addr[12:9] != 4'hf)) | !reset_i;
//0x0000_1E00 to 0x0000_1FFF is RAM
assign ram_csb = !((core_data_addr[31:13] == 19'b0) & (core_data_addr[12:9] == 4'hf)) | !reset_i;
assign mem_csb = ram_csb & rom_csb;
//0x0000_2000 to 0x0000_200F is mtime and mtimecmp, in order.
assign mtime_csb = !(core_data_addr[31:4] == 28'h200) | !reset_i;
//0x0000_2010 is debug interface
assign debug_if_csb = !(core_data_addr == 32'h0000_2010);

//if the instruction address falls outside of ROM, then the instruction access failed.
assign core_instr_access_fault = !((core_instr_addr_reg[31:13] == 19'b0) & (core_instr_addr_reg[12:9] != 4'hf));
//attempting to write to ROM will raise an error.
assign core_data_err = core_data_req_reg & ~rom_csb_reg & ~core_data_wen_reg;
//writes are only allowed in RAM region
assign masked_wen = ram_csb | core_data_wen;

assign core_data_in = !mtime_csb_reg ? mtime_data_out : mem_data_out;
assign core_instr_in = mem_instr_out;

assign mem_data_in = core_data_out;
assign mem_data_addr = core_data_addr;
assign mem_data_wen = masked_wen;
assign mem_data_csb = mem_csb;
assign mem_data_wmask = core_data_wmask;
assign mem_instr_addr = core_instr_addr;

//register the interface signals
always @(posedge clk_i or negedge reset_i)
begin
    if(!reset_i)
    begin
        core_data_addr_reg <= 32'b0;
        core_data_out_reg <= 32'b0;
        core_data_wmask_reg <= 4'b0;
        core_data_wen_reg <= 1'b1;
        core_data_req_reg <= 1'b0;
        core_instr_addr_reg <= 32'b0;
        rom_csb_reg <= 1'b1;
        ram_csb_reg <= 1'b1;
        mem_csb_reg <= 1'b1;
        debug_if_csb_reg <= 1'b1;
        mtime_csb_reg <= 1'b1;
        masked_wen_reg <= 1'b1;
    end

	else
	begin
        core_data_addr_reg <= core_data_addr;
        core_data_out_reg <= core_data_out;
        core_data_wmask_reg <= core_data_wmask;
        core_data_wen_reg <= core_data_wen;
        core_data_req_reg <= core_data_req;
        core_instr_addr_reg <= core_instr_addr;
        rom_csb_reg <= rom_csb;
        ram_csb_reg <= ram_csb;
        mem_csb_reg <= mem_csb;
        debug_if_csb_reg <= debug_if_csb;
        mtime_csb_reg <= mtime_csb;
        masked_wen_reg <= masked_wen;
	end
end

core core0(.clk_i(clk_i),
           .hreset_i(reset_i),
           .sreset_i(1'b1),

           .data_addr_o(core_data_addr),
           .data_i(core_data_in),
           .data_o(core_data_out),
           .data_wmask_o(core_data_wmask),
           .data_wen_o(core_data_wen),
           .data_req_o(core_data_req),
           .data_err_i(core_data_err),

           .instr_addr_o(core_instr_addr),
           .instr_i(core_instr_in),
           .instr_access_fault_i(core_instr_access_fault),

           .meip_i(meip_i),
           .mtip_i(mtip),
           .msip_i(1'b0),
           .fast_irq_i(fast_irq_i),
           .irq_ack_o(irq_ack_o));

memory_2rw #(.ADDR_WIDTH(11)) memory(.clk0(clk_i),
                  .csb0(mem_data_csb),
                  .web0(mem_data_wen),
                  .wmask0(mem_data_wmask),
                  .addr0(mem_data_addr[12:2]),
                  .din0(mem_data_in),
                  .dout0(mem_data_out), //port 0 is for data memory
                  .clk1(clk_i),
                  .csb1(1'b0),
                  .web1(1'b1),
                  .wmask1(4'b1111),
                  .addr1(mem_instr_addr[12:2]),
                  .din1(32'b0),
                  .dout1(mem_instr_out)); //port 1 is for instruction memory

mtime_registers mtime0(.reset_i(reset_i),
                       .csb_i(mtime_csb_reg),
                       .wen_i(core_data_wen_reg),
                       .clk_i(clk_i),
                       .addr_i(core_data_addr_reg[3:0]),
                       .data_i(core_data_out_reg),
                       .wmask_i(core_data_wmask_reg),
                       .mtip_o(mtip),
                       .data_o(mtime_data_out));

debug_interface debug_if(.reset_i(reset_i),
                         .csb_i(debug_if_csb_reg),
                         .data_i(core_data_out_reg),      //data memory input
                         .data_wen_i(core_data_wen_reg)); //data memory write enable output

endmodule
