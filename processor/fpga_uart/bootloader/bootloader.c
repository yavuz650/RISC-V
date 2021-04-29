#include "../../../lib/uart.h"
#include "../../../lib/irq.h"

int ram_index;
uart uart0;

int main()
{
    ram_index=0;
    SET_MTVEC_VECTOR_MODE();
    
    uart_init(&uart0,0x00008010);
    uart_transmit_string(&uart0,"Waiting for opcodes...\n",23);

    ENABLE_GLOBAL_IRQ();
    ENABLE_FAST_IRQ(0);

    while(1);
}

void mti_handler() {}
void mei_handler() {}
void msi_handler() {}
void exc_handler() {}

void fast_irq0_handler()
{
    char *rx_ptr = (char*)(uart0.base_addr)+UART_RX_ADDR_OFFSET;
    char rx_byte = *rx_ptr;
    *((char*)(0x00000000 + ram_index)) = rx_byte;
    ram_index++;
}

void fast_irq1_handler() {}
