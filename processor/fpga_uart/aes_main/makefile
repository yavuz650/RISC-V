CC=riscv32-unknown-elf
CCFLAGS=-march=rv32i -mabi=ilp32 -O3 -T linksc.ld -nostartfiles -ffunction-sections -fdata-sections -Wl,--gc-sections -o aes_main.elf
	
build:
	riscv32-unknown-elf-gcc aes_main.c ../../../lib/uart.c ../../../test/aes/aes.c crt0.s $(CCFLAGS)
	$(CC)-objcopy -O binary -j .init -j .text -j .rodata aes_main.elf aes_main.bin
	../../../test/rom_generator aes_main.bin
