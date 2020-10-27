#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

//to compile this program, run "gcc reader.c -o reader" .
//then, to compile your C code to RISC-V ISA, run "./reader your_file.c".
//you should have RISC-V GNU tools (Newlib version) installed in your system.

//pass the C file as an argument to the program.
int main(int argc, char* argv[])
{
    char cmd[512];
    FILE *infile, *outfile;
    int len;
    uint32_t rom[512];

    if (argc < 2)
	{
		fprintf(stderr, "input C file not specified!\n");
		return 1;
	}
	//compile the C file to RV32I ISA
    sprintf(cmd,"riscv32-unknown-elf-gcc -march=rv32i -mabi=ilp32 %s crt0.s -nostartfiles -T linksc.ld -o riscapp.elf",argv[1]);
    if (system(cmd) != 0)
	{
		return -1;
	}
	//generate .bin file
    sprintf(cmd,"riscv32-unknown-elf-objcopy -O binary --remove-section .eh_frame riscapp.elf riscapp.bin");
    if (system(cmd) != 0)
	{
		return -1;
	}
	//read and copy the instruction opcodes from .bin file to "rom" array
    infile = fopen("riscapp.bin", "rb");
	fseek(infile, 0, SEEK_END);
	len = ftell(infile);
	fseek(infile, 0, SEEK_SET);

 	if (fread(rom, 4, len/4, infile) != len/4)
	{
		printf("Assembled file read error!\n");
		fclose(infile);
		return -1;
	}

    outfile = fopen("riscapp.memory","wb");

	//write the instructions to "riscapp.memory" file. you should then copy the contents of that file to your verilog testbench.
    for (int i = 0; i < len/4; i+=1)
    {
        sprintf(cmd,"instr_i = 32'h%08X; addr_i = 11'd%d; #100; ",rom[i],4*i);
        fwrite(cmd,sizeof(char),strlen(cmd),outfile);
        sprintf(cmd,"\n");
        fwrite(cmd,sizeof(char),1,outfile);
    }

    return 0;    
}