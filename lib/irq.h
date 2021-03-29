#define ENABLE_GLOBAL_IRQ() __asm__("csrsi mstatus,0x8\n"); //enables interrupts globally by setting the mie bit in mstatus register.
#define DISABLE_GLOBAL_IRQ() __asm__("csrci mstatus,0x8\n"); //disables interrupts globally by clearing the mie bit in mstatus register.

//interrupt routines for vectored mode.
void mei_handler() __attribute__ (( interrupt ("machine")));
void mti_handler() __attribute__ (( interrupt ("machine")));
void exc_handler() __attribute__ (( interrupt ("machine")));
//trap handler for direct mode.
void direct_trap_handler() __attribute__ (( interrupt ("machine")));

//sets mtvec's value to the beginning of the vector table, and set the LSB.
static inline void SET_MTVEC_VECTOR_MODE()
{
    int base_addr;
    __asm__ volatile ("la %[base_addr],exc" :[base_addr] "=r" (base_addr): );
    base_addr |= 0x1; //vector mode
    __asm__ volatile ("csrw mtvec,%[base_addr]" :: [base_addr] "r" (base_addr));
}

//sets mtvec's value to the address of the trap handler function.
static inline void SET_MTVEC_DIRECT_MODE()
{
    int base_addr;
    base_addr = &direct_trap_handler;
    __asm__ volatile ("csrw mtvec,%[base_addr]" :: [base_addr] "r" (base_addr));
}

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

