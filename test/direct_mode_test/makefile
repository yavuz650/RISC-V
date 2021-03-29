CC=riscv32-unknown-elf
CCFLAGS=-march=rv32i -mabi=ilp32 -O2 -T ../linksc.ld -lm -nostartfiles -ffunction-sections -fdata-sections -Wl,--gc-sections -o direct_mode_test.elf
	
build:
	riscv32-unknown-elf-gcc direct_mode_test.c ../crt0.s $(CCFLAGS)
	$(CC)-objcopy -O binary -j .init -j .text -j .rodata direct_mode_test.elf direct_mode_test.bin
	../rom_generator direct_mode_test.bin
