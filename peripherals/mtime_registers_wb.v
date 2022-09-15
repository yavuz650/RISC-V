`timescale 1ns/1ps

module mtime_registers_wb(input         wb_cyc_i,
                          input         wb_stb_i,
                          input         wb_we_i,
                          input [31:0]  wb_adr_i,
                          input [31:0]  wb_dat_i,
                          input [3:0]   wb_sel_i,
                          output        wb_stall_o,
                          output        wb_ack_o,
                          output reg [31:0] wb_dat_o,
                          output        wb_err_o,
                          input         wb_rst_i,
                          input         wb_clk_i,
                          
                          output mtip_o);

//Register addresses - to be overridden in the top module
parameter mtime_adr    = 32'h0000_2010;
parameter mtimecmp_adr = 32'h0000_2018;

reg [63:0] mtime, mtimecmp;

wire e_h, l_h, l_l; //Equal and Less-than for the upper and lower 32 bits (high and low).

wire clk, rst;
reg stb, we;
reg [3:0] sel;
reg [31:0] adr,dat;

assign clk = wb_clk_i;
assign rst = ~wb_rst_i;

assign wb_err_o = 1'b0;
assign wb_stall_o = 1'b0;
assign wb_ack_o = stb & wb_cyc_i;

//input registers
always @(posedge clk or negedge rst)
begin
    if(!rst)
        {stb,we,sel,adr,dat} <= 69'b0;
    else
    begin
        stb <= wb_stb_i;
        we <= wb_we_i;
        sel <= wb_sel_i;
        adr <= wb_adr_i;
        dat <= wb_dat_i;
    end
end

always @(posedge clk or negedge rst)
begin
    if(!rst)
        mtime <= 64'b0;
    else if(wb_cyc_i && stb && we)
    begin
        if(adr == mtime_adr) //lower 32-bits
        begin
            if(sel[3])
                mtime[31:24] <= dat[31:24];

            if(sel[2])
                mtime[23:16] <= dat[23:16];

            if(sel[1])
                mtime[15:8] <= dat[15:8];

            if(sel[0])
                mtime[7:0] <= dat[7:0];
        end

        else if(adr == mtime_adr + 32'd4) //higher 32-bits
        begin
            if(sel[3])
                mtime[63:56] <= dat[31:24];

            if(sel[2])
                mtime[55:48] <= dat[23:16];

            if(sel[1])
                mtime[47:40] <= dat[15:8];

            if(sel[0])
                mtime[39:32] <= dat[7:0];
        end
    end
    else
    begin
        mtime[31:0] <= mtime[31:0] + 32'd1;
        if(mtime[31:0] == 32'hffff_ffff)
            mtime[63:32] <= mtime[63:32] + 32'd1;
    end
end

always @(posedge clk or negedge rst)
begin
    if(!rst)
        mtimecmp <= 64'b0;
    else if(wb_cyc_i && stb && we)
    begin
        if(adr == mtimecmp_adr) //lower 32-bits
        begin
            if(sel[3])
                mtimecmp[31:24] <= dat[31:24];

            if(sel[2])
                mtimecmp[23:16] <= dat[23:16];

            if(sel[1])
                mtimecmp[15:8] <= dat[15:8];

            if(sel[0])
                mtimecmp[7:0] <= dat[7:0];
        end

        else if(adr == mtimecmp_adr + 32'd4) //higher 32-bits
        begin
            if(sel[3])
                mtimecmp[63:56] <= dat[31:24];

            if(sel[2])
                mtimecmp[55:48] <= dat[23:16];

            if(sel[1])
                mtimecmp[47:40] <= dat[15:8];

            if(sel[0])
                mtimecmp[39:32] <= dat[7:0];
        end
    end
end

always @(*)
begin
    if(adr == mtime_adr)
        wb_dat_o = mtime[31:0];

    else if(adr == mtime_adr + 32'd4)
        wb_dat_o = mtime[63:32];

    else if(adr == mtimecmp)
        wb_dat_o = mtimecmp[31:0];

    else
        wb_dat_o = mtimecmp[63:32];
end

assign e_h = mtime[63:32] == mtimecmp[63:32];
assign l_h = mtime[63:32] < mtimecmp[63:32];
assign l_l = mtime[31:0] < mtimecmp[31:0];

assign mtip_o = !(l_h | (e_h & l_l));

endmodule
