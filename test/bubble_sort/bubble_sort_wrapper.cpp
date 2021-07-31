#include <verilated.h>
#include <iostream>
#include <fstream>
#include "Vbarebones_wb_top.h"
#include "Vbarebones_wb_top_memory_2rw_wb__Ab.h"
#include "Vbarebones_wb_top_barebones_wb_top.h"
#include "verilated_vcd_c.h"

Vbarebones_wb_top *barebones_wb_top;
vluint64_t main_time = 0;

int main(int argc, char** argv) 
{
    std::ifstream bin_file("../bubble_sort.bin",std::ifstream::binary);
    Verilated::commandArgs(argc, argv);
	Verilated::traceEverOn(true);
	VerilatedVcdC* tfp = new VerilatedVcdC;
    barebones_wb_top = new Vbarebones_wb_top;

    bin_file.seekg(0,bin_file.end);
    int len = bin_file.tellg();
    bin_file.seekg(0,bin_file.beg);

    bin_file.read(reinterpret_cast<char*>(barebones_wb_top->barebones_wb_top->memory->mem),len);

    barebones_wb_top->trace(tfp, 99);
    tfp->open("simx.vcd");
	barebones_wb_top->reset_i = 1;
    barebones_wb_top->meip_i = 0;
    barebones_wb_top->clk_i = 0;
    barebones_wb_top->fast_irq_i = 0;
    barebones_wb_top->eval();
    tfp->dump(main_time);    
    main_time++;
    barebones_wb_top->reset_i = 0;
    while (!Verilated::gotFinish())
    {
    	if (main_time > 10) {
            barebones_wb_top->reset_i = 1;
        }
        if ((main_time % 10) == 6) {
            barebones_wb_top->clk_i = 1;
        }
        if ((main_time % 10) == 1) {
            barebones_wb_top->clk_i = 0;
        }
		barebones_wb_top->eval();
        tfp->dump(main_time);
        main_time++;
        if(main_time > 50000)
        {
            std::cout << "Failure - Time out...\n";
            break;
        }
    }

    barebones_wb_top->final();
    tfp->close();
    delete barebones_wb_top;
}

