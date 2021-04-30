CC=riscv32-unknown-elf
CCFLAGS=-march=rv32i -mabi=ilp32 -O3 -nostartfiles -ffunction-sections -fdata-sections  -T linksc.ld -o bootloader.elf
build:
	$(CC)-gcc bootloader.c ../../../lib/uart.c ../../../lib/irq.c crt0.s $(CCFLAGS)
	$(CC)-objcopy -O binary -j .init -j .text -j .rodata bootloader.elf bootloader.bin
	../../../test/rom_generator bootloader.bin
