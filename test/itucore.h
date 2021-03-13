#define MTIME_ADDR 0x00000800
#define MTIMECMP_ADDR 0x00000808

#define ENABLE_GLOBAL_IRQ() __asm__("csrrsi zero,0x300,0x8\n"); //enables interrupts globally by setting the mie bit in mstatus register.
#define DISABLE_GLOBAL_IRQ() __asm__("csrrci zero,0x300,0x8\n"); //disables interrupts globally by clearing the mie bit in mstatus register.

//sets mtvec's value to the beginning of the vector table.
static inline void SET_MTVEC_VECTOR_MODE()
{
    __asm__ volatile(
            "addi sp,sp,-4\n"
            "sw t0,0(sp)\n"
            "la t0, exc\n" 
            "slli t0,t0,2\n" 
            "ori t0,t0,1\n" 
            "csrrw zero,0x305,t0\n"
            "lw t0,0(sp)\n"
            "addi sp,sp,4\n");
}

//enables machine level timer interrupts by setting the mtie bit in mie register.
static inline void ENABLE_MTI()
{
    volatile int mask = 0x80;
    __asm__ volatile ("csrrs zero,0x304,%[mask]" :: [mask] "r" (mask));
}

//disables machine level timer interrupts by clearing the mtie bit in mie register.
static inline void DISABLE_MTI()
{
    volatile int mask = 0x80;
    __asm__ volatile ("csrrc zero,0x304,%[mask]" :: [mask] "r" (mask));
}

//enables machine level external interrupts by setting the meie bit in mie register.
static inline void ENABLE_MEI()
{
    volatile int mask = 0x800;
    __asm__ volatile ("csrrs zero,0x304,%[mask]" :: [mask] "r" (mask));
}
//disables machine level external interrupts by clearing the meie bit in mie register.
static inline void DISABLE_MEI()
{
    volatile int mask = 0x800;
    __asm__ volatile ("csrrc zero,0x304,%[mask]" :: [mask] "r" (mask));
}

void mei_handler() __attribute__ (( interrupt ("machine")));
void mti_handler() __attribute__ (( interrupt ("machine")));
void exc_handler() __attribute__ (( interrupt ("machine")));


__asm__("exc: j exc_handler\n");
__asm__("ssi: nop\n");
__asm__("hsi: nop\n");
__asm__("msi: nop\n");
__asm__("uti: nop\n");
__asm__("sti: nop\n");
__asm__("hti: nop\n");
__asm__("mti: j mti_handler\n");
__asm__("uei: nop\n");
__asm__("sei: nop\n");
__asm__("hei: nop\n");
__asm__("mei: j mei_handler\n");
