CC=riscv32-unknown-elf
CCFLAGS=-march=rv32i -mabi=ilp32 -O3 -T linksc.ld -nostartfiles -o uart_main.elf
build:
	$(CC)-gcc uart_main.c ../../../lib/uart.c crt0.s $(CCFLAGS)
	$(CC)-objcopy -O binary -j .init -j .text -j .rodata uart_main.elf uart_main.bin
	../../../test/rom_generator uart_main.bin
