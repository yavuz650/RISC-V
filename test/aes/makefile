CC32=riscv32-unknown-elf
CC64=riscv64-unknown-elf
CCFLAGS=-march=rv32i -mabi=ilp32 -O3 -T ../linksc.ld -nostartfiles -ffunction-sections -fdata-sections -Wl,--gc-sections -o aes_test.elf
	
build:
	$(CC32)-gcc aes_test.c aes.c ../crt0.s $(CCFLAGS)
	$(CC32)-objcopy -O binary -j .init -j .text -j .rodata aes_test.elf aes_test.bin
	../rom_generator aes_test.bin
	cp aes_test.data ../memory_contents

multilib:
	$(CC64)-gcc aes_test.c aes.c ../crt0.s $(CCFLAGS)
	$(CC64)-objcopy -O binary -j .init -j .text -j .rodata aes_test.elf aes_test.bin
	../rom_generator aes_test.bin
	cp aes_test.data ../memory_contents
