CC32=riscv32-unknown-elf
CC64=riscv64-unknown-elf
CCFLAGS=-march=rv32i -mabi=ilp32 -O2 -T ../linksc.ld -lm -nostartfiles -ffunction-sections -fdata-sections -Wl,--gc-sections -o bubble_sort_irq.elf

build:
	$(CC32)-gcc bubble_sort_irq.c ../../lib/irq.c ../crt0.s $(CCFLAGS)
	$(CC32)-objcopy -O binary -j .init -j .text -j .rodata bubble_sort_irq.elf bubble_sort_irq.bin
	../rom_generator bubble_sort_irq.bin
	cp bubble_sort_irq.data ../memory_contents

multilib:
	$(CC64)-gcc bubble_sort_irq.c ../../lib/irq.c ../crt0.s $(CCFLAGS)
	$(CC64)-objcopy -O binary -j .init -j .text -j .rodata bubble_sort_irq.elf bubble_sort_irq.bin
	../rom_generator bubble_sort_irq.bin
	cp bubble_sort_irq.data ../memory_contents