#include "../../../lib/uart.h"
#include "../../../test/aes/aes.h"
#include "../../../lib/irq.h"
#define ECB 1
#include <stdint.h>
volatile int count;
volatile uint8_t input_array[16];
uart uart0;
int main()
{
    SET_MTVEC_VECTOR_MODE();
	count = 0;
	uint8_t key[] = { 0x2b, 0x7e, 0x15, 0x16, 0x28, 0xae, 0xd2, 0xa6, 0xab, 0xf7, 0x15, 0x88, 0x09, 0xcf, 0x4f, 0x3c };
	struct AES_ctx ctx;
    AES_init_ctx(&ctx, key);
    
    uart_init(&uart0,0x00008010);
    while(1)
    {
        uart_transmit_string(&uart0,"Send 16 bytes of input block!\n",30);
        ENABLE_GLOBAL_IRQ();
        ENABLE_FAST_IRQ(0);
        while(count!=16);
        AES_ECB_encrypt(&ctx, input_array);
        uart_transmit_string(&uart0,input_array,16);
        count = 0;
    }
}

void mti_handler() {}
void exc_handler() {}
void mei_handler() {}
void msi_handler() {}
void fast_irq0_handler()
{
	char *rx_ptr = (char*)(uart0.base_addr)+UART_RX_ADDR_OFFSET;
    char rx_byte = *rx_ptr;
    input_array[count]=rx_byte;
    count++;
    if(count == 16)
        DISABLE_GLOBAL_IRQ();
}

void fast_irq1_handler() {}
