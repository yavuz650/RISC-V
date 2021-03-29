CC=riscv32-unknown-elf
CCFLAGS=-march=rv32i -mabi=ilp32 -O2 -T ../linksc.ld -lm -nostartfiles -ffunction-sections -fdata-sections -Wl,--gc-sections -o bubble_sort_irq.elf
	
build:
	riscv32-unknown-elf-gcc bubble_sort_irq.c ../crt0.s $(CCFLAGS)
	$(CC)-objcopy -O binary -j .init -j .text -j .rodata bubble_sort_irq.elf bubble_sort_irq.bin
	../rom_generator bubble_sort_irq.bin
