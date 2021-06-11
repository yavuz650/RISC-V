CC32=riscv32-unknown-elf
CC64=riscv64-unknown-elf
CCFLAGS=-march=rv32im -mabi=ilp32 -O3 -T ../linksc.ld -nostartfiles -ffunction-sections -fdata-sections -Wl,--gc-sections -o muldiv.elf

build:
	$(CC32)-gcc muldiv.c ../crt0.s $(CCFLAGS)
	$(CC32)-objcopy -O binary -j .init -j .text -j .rodata -j .sdata muldiv.elf muldiv.bin
	../rom_generator muldiv.bin
	cp muldiv.data ../memory_contents

multilib:
	$(CC64)-gcc muldiv.c ../crt0.s $(CCFLAGS)
	$(CC64)-objcopy -O binary -j .init -j .text -j .rodata -j .sdata muldiv.elf muldiv.bin
	../rom_generator muldiv.bin
	cp muldiv.data ../memory_contents
