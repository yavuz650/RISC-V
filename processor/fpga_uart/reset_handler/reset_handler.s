.globl _start
_start:
csrr t2, mcause
beqz t2, 0
j 0x7500
