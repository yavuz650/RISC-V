`timescale 1ns/1ps

module core_wb(input reset_i, //active-low reset
               input clk_i,

               //Wishbone interface for data memory
               output        data_wb_cyc_o,
               output        data_wb_stb_o,
               output        data_wb_we_o,
               output [31:0] data_wb_adr_o,
               output [31:0] data_wb_dat_o,
               output [3:0]  data_wb_sel_o,
               input         data_wb_stall_i,
               input         data_wb_ack_i,
               input [31:0]  data_wb_dat_i,
               input         data_wb_err_i,
               input         data_wb_rst_i,
               input         data_wb_clk_i,

               //Wishbone interface for instruction memory
               output        inst_wb_cyc_o,
               output        inst_wb_stb_o,
               output        inst_wb_we_o,
               output [31:0] inst_wb_adr_o,
               output [31:0] inst_wb_dat_o,
               output [3:0]  inst_wb_sel_o,
               input         inst_wb_stall_i,
               input         inst_wb_ack_i,
               input [31:0]  inst_wb_dat_i,
               input         inst_wb_err_i,
               input         inst_wb_rst_i,
               input         inst_wb_clk_i,

               //Interrupts
               input meip_i,
               input mtip_i,
               input msip_i,
               input [15:0] fast_irq_i,
               output irq_ack_o); //Interrupt acknowledge signal. driven high for one cycle when an external interrupt is handled.

parameter reset_vector = 32'h0;

wire [31:0] data_addr_o;
wire [31:0] data_i;
wire [31:0] data_o;
wire [3:0]  data_wmask_o;
wire        data_wen_o;
wire        data_req_o;
wire        data_stall_i;
wire        data_err_i;

wire [31:0] instr_addr_o;
wire [31:0] instr_i;
wire        instr_access_fault_i;

core    #(.reset_vector(reset_vector))
        core0(
        //Clock and reset signals.
        .clk_i(clk_i),
        .reset_i(reset_i), //active-low, asynchronous reset

        //Data memory interface
        .data_addr_o(data_addr_o),
        .data_i(data_i),
        .data_o(data_o),
        .data_wmask_o(data_wmask_o),
        .data_wen_o(data_wen_o), //active-low
        .data_req_o(data_req_o),
        .data_stall_i(data_stall_i),
        .data_err_i(data_err_i),

        //Instruction memory interface
        .instr_addr_o(instr_addr_o),
        .instr_i(instr_i),
        .instr_access_fault_i(instr_access_fault_i),

        //Interrupts
        .meip_i(meip_i),
        .mtip_i(mtip_i),
        .msip_i(msip_i),
        .fast_irq_i(fast_irq_i),
        .irq_ack_o(irq_ack_o));

reg data_cyc;
always @(posedge data_wb_clk_i or posedge data_wb_rst_i)
begin
    if(data_wb_rst_i)
        data_cyc <= 1'b0;
    else if(data_req_o)
        data_cyc <= 1'b1;
    else if(data_wb_ack_i || data_wb_err_i)
        data_cyc <= 1'b0;
end

assign data_wb_cyc_o = data_req_o | data_cyc;
assign data_wb_stb_o = data_req_o;
assign data_wb_we_o  = ~data_wen_o;
assign data_wb_adr_o = data_addr_o;
assign data_wb_dat_o = data_o;
assign data_wb_sel_o = data_wmask_o;
assign data_i       = data_wb_dat_i;
assign data_stall_i = data_wb_stall_i;
assign data_err_i   = data_wb_err_i;

assign inst_wb_cyc_o = 1'b1;
assign inst_wb_stb_o = 1'b1;
assign inst_wb_we_o  = 1'b0;
assign inst_wb_adr_o = instr_addr_o;
assign inst_wb_dat_o = 32'b0;
assign inst_wb_sel_o = 4'hf;
assign instr_i = inst_wb_dat_i;
assign instr_access_fault_i = inst_wb_err_i;

endmodule
