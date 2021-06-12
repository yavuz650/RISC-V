CC32=riscv32-unknown-elf
CC64=riscv64-unknown-elf
CCFLAGS=-march=rv32i -mabi=ilp32 -O3 -T ../linksc.ld -lm -nostartfiles -ffunction-sections -fdata-sections -Wl,--gc-sections -o soft_float.elf

build:
	$(CC32)-gcc soft_float.c ../crt0.s $(CCFLAGS)
	$(CC32)-objcopy -O binary -j .init -j .text -j .rodata -j .sdata soft_float.elf soft_float.bin
	../rom_generator soft_float.bin
	cp soft_float.data ../memory_contents

multilib:
	$(CC64)-gcc soft_float.c ../crt0.s $(CCFLAGS)
	$(CC64)-objcopy -O binary -j .init -j .text -j .rodata -j .sdata soft_float.elf soft_float.bin
	../rom_generator soft_float.bin
	cp soft_float.data ../memory_contents
