CC32=riscv32-unknown-elf
CC64=riscv64-unknown-elf
CCFLAGS=-march=rv32i -mabi=ilp32 -O3 -T linksc.ld -nostartfiles -o uart_main.elf

build:
	$(CC32)-gcc uart_main.c ../../../lib/uart.c crt0.s $(CCFLAGS)
	$(CC32)-objcopy -O binary -j .init -j .text -j .rodata uart_main.elf uart_main.bin
	../../../test/rom_generator uart_main.bin
	mv uart_main.data uart_main.mem 

multilib:
	$(CC64)-gcc uart_main.c ../../../lib/uart.c crt0.s $(CCFLAGS)
	$(CC64)-objcopy -O binary -j .init -j .text -j .rodata uart_main.elf uart_main.bin
	../../../test/rom_generator uart_main.bin
	mv uart_main.data uart_main.mem 
