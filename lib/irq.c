#include "irq.h"
//weak interrupt handler function definitions, to be overriden by the user.
void mei_handler() {}
void mti_handler() {}
void msi_handler() {}
void exc_handler() {}
void fast_irq0_handler() {}
void fast_irq1_handler() {}
void direct_trap_handler() {}

void SET_MTVEC_VECTOR_MODE()
{
    int base_addr;
    __asm__ volatile ("la %[base_addr],exc" :[base_addr] "=r" (base_addr): );
    base_addr |= 0x1; //vector mode
    __asm__ volatile ("csrw mtvec,%[base_addr]" :: [base_addr] "r" (base_addr));
}

void SET_MTVEC_DIRECT_MODE()
{
    int base_addr;
    base_addr = &direct_trap_handler;
    __asm__ volatile ("csrw mtvec,%[base_addr]" :: [base_addr] "r" (base_addr));
}

__asm__("exc: j exc_handler\n");
__asm__("ssi: nop\n");
__asm__("hsi: nop\n");
__asm__("msi: j msi_handler\n");
__asm__("uti: nop\n");
__asm__("sti: nop\n");
__asm__("hti: nop\n");
__asm__("mti: j mti_handler\n");
__asm__("uei: nop\n");
__asm__("sei: nop\n");
__asm__("hei: nop\n");
__asm__("mei: j mei_handler\n");
__asm__("nop\n");
__asm__("nop\n");
__asm__("nop\n");
__asm__("nop\n");
__asm__("fast_irq0: j fast_irq0_handler\n");
__asm__("fast_irq1: j fast_irq1_handler\n");
