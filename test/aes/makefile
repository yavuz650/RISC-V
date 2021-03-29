CC=riscv32-unknown-elf
CCFLAGS=-march=rv32i -mabi=ilp32 -O3 -T ../linksc.ld -nostartfiles -ffunction-sections -fdata-sections -Wl,--gc-sections -o aes_test.elf
	
build:
	riscv32-unknown-elf-gcc aes_test.c aes.c ../crt0.s $(CCFLAGS)
	$(CC)-objcopy -O binary -j .init -j .text -j .rodata aes_test.elf aes_test.bin
	../rom_generator aes_test.bin
