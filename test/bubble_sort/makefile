CC=riscv32-unknown-elf
CCFLAGS=-march=rv32i -mabi=ilp32 -O3 -T ../linksc.ld -nostartfiles -ffunction-sections -fdata-sections -Wl,--gc-sections -o bubble_sort.elf
	
build:
	riscv32-unknown-elf-gcc bubble_sort.c ../crt0.s $(CCFLAGS)
	$(CC)-objcopy -O binary -j .init -j .text -j .rodata bubble_sort.elf bubble_sort.bin
	../rom_generator bubble_sort.bin
	cp bubble_sort.data ../memory_contents
