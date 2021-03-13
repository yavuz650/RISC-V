#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <ctype.h>

/*
To compile this program, run "gcc reader.c -o reader".
Then, to compile your C code to RISC-V ISA, run "./reader your_file.c".
You should have RISC-V GNU tools (Newlib version) installed in your system.

The program can accept two options, -s and -O options. -s option determines 
which compilation command will be used. -O option determines the compiler
optimization level. These options can be useful when you have files
that require different compile commands, or optimization levels.
By default, -O2 and -s0 options are used.
*/

int main(int argc, char* argv[])
{
    char cmd[512];
    FILE *infile, *outfile;
    int len;
    uint32_t rom[4096]; //this is where the opcodes are stored, you may need to increase its size if your program is too big.
    int c;
    char *svalue = NULL; //-s option value
    char *Ovalue = NULL; //-O option value
    int index;

    //get options
    opterr = 0;
    while ((c = getopt(argc, argv, "s:O:")) != -1)
        switch (c)
        {
        case 's':
            svalue = optarg;
            break;
        case 'O':
            Ovalue = optarg;
            break;
        case '?':
            if (optopt == 's' || optopt == 'O')
                fprintf(stderr, "Option -%c requires an argument.\n", optopt);
            else if (isprint(optopt))
                fprintf(stderr, "Unknown option `-%c'.\n", optopt);
            else
                fprintf(stderr, "Unknown option character `\\x%x'.\n", optopt);
            return 1;
        default:
            abort();
        }

    //printf ("svalue = %s\nOvalue = %s\n",svalue,Ovalue);

    //start constructing the compilation command
    sprintf(cmd,"riscv32-unknown-elf-gcc ");
    for (index = optind; index < argc; index++)
    {
        //printf ("Non-option argument %s\n", argv[index]);
        strcat(cmd,argv[index]);
        strcat(cmd," ");
    }
    //-O option
    strcat(cmd,"-O");
    if(Ovalue == NULL)
        strcat(cmd,"2");
    else    
        strcat(cmd,Ovalue);
    strcat(cmd," ");
    
    //-s option
    if(svalue == NULL || !strcmp(svalue,"0"))
        strcat(cmd,"-march=rv32i -mabi=ilp32 ../crt0.s -nostartfiles -T ../linksc.ld -o riscapp.elf");
 
    else if(!strcmp(svalue,"1"))
        strcat(cmd,"-march=rv32i -mabi=ilp32 ../crt0.s -nostartfiles -ffunction-sections -fdata-sections -Wl,--gc-sections -T ../linksc.ld -o riscapp.elf");

    else if(!strcmp(svalue,"2"))
        strcat(cmd,"-march=rv32im -mabi=ilp32 ../crt0.s -nostartfiles -T ../linksc.ld -o riscapp.elf");    

    printf("%s\n",cmd);
    //compile the C file to RV32I ISA
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
    //construct the output file name by removing .c and adding .data to the end
    char file_name[64];
    sprintf(file_name,"%s",argv[optind]);
    sprintf(file_name+strlen(argv[optind])-2,".data");

    //write the opcodes to the .data file. you should then use the readmemh command in your verilog testbench to load the opcodes to memory.
    outfile = fopen(file_name,"wb");
    for (int i = 0; i < len/4; i+=1)
    {
        sprintf(cmd,"%08X",rom[i]);
        fwrite(cmd,sizeof(char),strlen(cmd),outfile);
        sprintf(cmd,"\n");
        fwrite(cmd,sizeof(char),1,outfile);
    }

    return 0;    
}
