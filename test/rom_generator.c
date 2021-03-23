#include <stdio.h>
#include <stdint.h>
#include <string.h>

int main(int argc, char *argv[])
{
    if(argc != 2)
    {
        printf("Error! Expected a .bin file only.\n");
        return -1;
    }
    char cmd[512];
    FILE *infile, *outfile;
    int len;
    uint32_t rom[4096]; //this is where the opcodes are stored, you may need to increase its size if your program is too big.

    //read and copy the instruction opcodes from .bin file to "rom" array
    infile = fopen(argv[1], "rb");
	fseek(infile, 0, SEEK_END);
	len = ftell(infile);
	fseek(infile, 0, SEEK_SET);

 	if (fread(rom, 4, len/4, infile) != len/4)
	{
		printf("Assembled file read error!\n");
		fclose(infile);
		return -1;
	}
    //construct the output file name by removing .bin and adding .data to the end
    char file_name[64];
    sprintf(file_name,"%s",argv[1]);
    sprintf(file_name+strlen(argv[1])-4,".data");

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

  