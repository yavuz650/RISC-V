CC=riscv32-unknown-elf
CCFLAGS=-march=rv32i -mabi=ilp32 -O3 -T ../linksc.ld -lm -nostartfiles -ffunction-sections -fdata-sections -Wl,--gc-sections -o soft_float.elf
	
build:
	riscv32-unknown-elf-gcc soft_float.c ../crt0.s $(CCFLAGS)
	$(CC)-objcopy -O binary -j .init -j .text -j .rodata -j .sdata soft_float.elf soft_float.bin
	../rom_generator soft_float.bin
