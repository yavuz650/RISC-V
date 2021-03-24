#include "../../../lib/uart.h"
int main()
{
    uart uart0;
    uart_init(&uart0,0x00008010);
    while(1)
    {
        uart_transmit_string(&uart0,"Hello world!\n",13);
        for (int i = 0; i < 4000000; i++){} 
    }
}
