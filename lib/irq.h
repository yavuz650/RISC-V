#define ENABLE_GLOBAL_IRQ() __asm__("csrsi mstatus,0x8\n"); //enables interrupts globally by setting the mie bit in mstatus register.
#define DISABLE_GLOBAL_IRQ() __asm__("csrci mstatus,0x8\n"); //disables interrupts globally by clearing the mie bit in mstatus register.

//interrupt routines for vectored mode.
void mei_handler() __attribute__ (( weak, interrupt ("machine")));
void mti_handler() __attribute__ (( weak, interrupt ("machine")));
void msi_handler() __attribute__ (( weak, interrupt ("machine")));
void exc_handler() __attribute__ (( weak, interrupt ("machine")));
void fast_irq0_handler() __attribute__ (( weak, interrupt ("machine")));
void fast_irq1_handler() __attribute__ (( weak, interrupt ("machine")));
//trap handler for direct mode.
void direct_trap_handler() __attribute__ (( weak, interrupt ("machine")));

//sets mtvec's value to the beginning of the vector table, and sets the LSB.
void SET_MTVEC_VECTOR_MODE();

//sets mtvec's value to the address of the trap handler function.
void SET_MTVEC_DIRECT_MODE();

//enables machine level timer interrupts by setting the mtie bit in mie register.
static inline void ENABLE_MTI()
{
    int mask = 0x80;
    __asm__ volatile ("csrs mie,%[mask]" :: [mask] "r" (mask));
}

//disables machine level timer interrupts by clearing the mtie bit in mie register.
static inline void DISABLE_MTI()
{
    int mask = 0x80;
    __asm__ volatile ("csrc mie,%[mask]" :: [mask] "r" (mask));
}

//enables machine level external interrupts by setting the meie bit in mie register.
static inline void ENABLE_MEI()
{
    int mask = 0x800;
    __asm__ volatile ("csrs mie,%[mask]" :: [mask] "r" (mask));
}
//disables machine level external interrupts by clearing the meie bit in mie register.
static inline void DISABLE_MEI()
{
    int mask = 0x800;
    __asm__ volatile ("csrc mie,%[mask]" :: [mask] "r" (mask));
}

//enables fast interrupts by setting the associated bit in mie register.
static inline void ENABLE_FAST_IRQ(int irq_index)
{
    int mask = 0x1 << (irq_index+16);
    __asm__ volatile ("csrs mie,%[mask]" :: [mask] "r" (mask));
}
//disables fast interrupts by clearing the associated bit in mie register.
static inline void DISABLE_FAST_IRQ(int irq_index)
{
    int mask = 0x1 << (irq_index+16);
    __asm__ volatile ("csrc mie,%[mask]" :: [mask] "r" (mask));
}
