# Testing Hornet via Simulations
This directory contains several test programs. As Hornet is not formally verified, we developed simple C programs to verify the functionality of the core.

You can also find a C runtime routine (crt0.s) and a default linker script (linksc.ld) to work with. The crt routine initialies the stack pointer and jumps to `main`. The linker script defines the following memory regions, which you can change as you wish,
*    `ROM(RX)   : ORIGIN = 0x00000000, LENGTH = 0x00001E00`
*    `RAM(WAIL) : ORIGIN = 0x00001E00, LENGTH = 0x000001FC`

The `rom_generator.c` simply generates the opcodes for the ROM in .data file format. You can load that .data file to your main memory to simulate the program. See `/processor/barebones` folder to learn how exactly you can do that.

Each test folder has a `makefile` that compiles the program appropriately, and generates the ROM. 