CC=riscv32-unknown-elf
CCFLAGS=-march=rv32im -mabi=ilp32 -O3 -T ../linksc.ld -nostartfiles -ffunction-sections -fdata-sections -Wl,--gc-sections -o muldiv.elf
	
build:
	riscv32-unknown-elf-gcc muldiv.c ../crt0.s $(CCFLAGS)
	$(CC)-objcopy -O binary -j .init -j .text -j .rodata -j .sdata muldiv.elf muldiv.bin
	../rom_generator muldiv.bin
	cp muldiv.data ../memory_contents
	
asm:
	riscv32-unknown-elf-gcc muldiv.s -march=rv32im -mabi=ilp32 -T ../linksc.ld -nostartfiles -o muldiv.elf
	$(CC)-objcopy -O binary -j .init -j .text -j .rodata -j .sdata muldiv.elf muldiv.bin
	../rom_generator muldiv.bin
	cp muldiv.data ../memory_contents	
