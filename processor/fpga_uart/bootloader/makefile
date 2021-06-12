CC32=riscv32-unknown-elf
CC64=riscv64-unknown-elf
CCFLAGS=-march=rv32i -mabi=ilp32 -O3 -nostartfiles -ffunction-sections -fdata-sections  -T linksc.ld -o bootloader.elf

build:
	$(CC32)-gcc bootloader.c ../../../lib/uart.c ../../../lib/irq.c crt0.s $(CCFLAGS)
	$(CC32)-objcopy -O binary -j .init -j .text -j .rodata bootloader.elf bootloader.bin
	../../../test/rom_generator bootloader.bin
	mv bootloader.data bootloader.mem 

multilib:
	$(CC64)-gcc bootloader.c ../../../lib/uart.c ../../../lib/irq.c crt0.s $(CCFLAGS)
	$(CC64)-objcopy -O binary -j .init -j .text -j .rodata bootloader.elf bootloader.bin
	../../../test/rom_generator bootloader.bin
	mv bootloader.data bootloader.mem 

