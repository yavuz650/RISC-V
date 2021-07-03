.globl _start
_start:
li t1, 0x8014
lw t2, 0(t1)
beqz t2, 0
j 0x7500
