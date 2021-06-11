CC32=riscv32-unknown-elf
CC64=riscv64-unknown-elf
CCFLAGS=-march=rv32i -mabi=ilp32 -O2 -T ../linksc.ld -lm -nostartfiles -ffunction-sections -fdata-sections -Wl,--gc-sections -o direct_mode_test.elf

build:
	$(CC32)-gcc direct_mode_test.c ../../lib/irq.c ../crt0.s $(CCFLAGS)
	$(CC32)-objcopy -O binary -j .init -j .text -j .rodata direct_mode_test.elf direct_mode_test.bin
	../rom_generator direct_mode_test.bin
	cp direct_mode_test.data ../memory_contents

multilib:
	$(CC64)-gcc direct_mode_test.c ../../lib/irq.c ../crt0.s $(CCFLAGS)
	$(CC64)-objcopy -O binary -j .init -j .text -j .rodata direct_mode_test.elf direct_mode_test.bin
	../rom_generator direct_mode_test.bin
	cp direct_mode_test.data ../memory_contents