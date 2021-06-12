CC32=riscv32-unknown-elf
CC64=riscv64-unknown-elf
CCFLAGS=-march=rv32i -mabi=ilp32 -O3 -T linksc.ld -nostartfiles -o reset_handler.elf

build:
	$(CC32)-gcc reset_handler.s $(CCFLAGS)
	$(CC32)-objcopy -O binary -j .init -j .text -j .rodata reset_handler.elf reset_handler.bin
	../../../test/rom_generator reset_handler.bin
	mv reset_handler.data reset_handler.mem 

multilib:
	$(CC64)-gcc reset_handler.s $(CCFLAGS)
	$(CC64)-objcopy -O binary -j .init -j .text -j .rodata reset_handler.elf reset_handler.bin
	../../../test/rom_generator reset_handler.bin
	mv reset_handler.data reset_handler.mem 