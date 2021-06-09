CC=riscv64-unknown-elf
CCFLAGS=-march=rv32im -mabi=ilp32 -O3 -T linksc.ld -nostartfiles -ffunction-sections -fdata-sections -Wl,--gc-sections -o muldiv_main.elf
	
build:
	riscv64-unknown-elf-gcc muldiv_main.c ../../../lib/uart.c ../../../lib/irq.c crt0.s $(CCFLAGS)
	$(CC)-objcopy -O binary -j .init -j .text -j .rodata -j .sdata muldiv_main.elf muldiv_main.bin
	../../../test/rom_generator muldiv_main.bin
