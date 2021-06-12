CC32=riscv32-unknown-elf
CC64=riscv64-unknown-elf
CCFLAGS=-march=rv32i -mabi=ilp32 -O2 -T ../linksc.ld -lm -nostartfiles -ffunction-sections -fdata-sections -Wl,--gc-sections -o direct_mode.elf

build:
	$(CC32)-gcc direct_mode.c ../../lib/irq.c ../crt0.s $(CCFLAGS)
	$(CC32)-objcopy -O binary -j .init -j .text -j .rodata direct_mode.elf direct_mode.bin
	../rom_generator direct_mode.bin
	cp direct_mode.data ../memory_contents

multilib:
	$(CC64)-gcc direct_mode.c ../../lib/irq.c ../crt0.s $(CCFLAGS)
	$(CC64)-objcopy -O binary -j .init -j .text -j .rodata direct_mode.elf direct_mode.bin
	../rom_generator direct_mode.bin
	cp direct_mode.data ../memory_contents
