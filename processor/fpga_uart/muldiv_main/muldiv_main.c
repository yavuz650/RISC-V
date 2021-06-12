#include "string.h"
#include "stdint.h"
#include "../../../lib/uart.h"
#include "../../../lib/irq.h"

volatile int64_t mul_res;
volatile int div_res;

char tx_string[30];

uart uart0;

int main() 
{
    const volatile int a[10] = {-619183,616959,263374,-3035621,-4968369,4637756,-935330,2832102,-4746714,6051886};
    const volatile int b[10] = {747432,902274,-1767403,5589605,-6251467,5605882,5520004,6582310,-4458287,4367400};
    const volatile int64_t c[10] = {-462797188056,556666064766,-465487997722,-16967922319705,31059594847323,25998712880792,-5163025341320,18641773315620,21162213318918,26431006916400};

    uart_init(&uart0,0x00008010);

    //TODO: Add MUL operations

    for (int i = 0; i < 10; i++)
    {
        div_res = c[i] / b[i];
        itoa(div_res,tx_string,10);
        uart_transmit_string(&uart0,tx_string,strlen(tx_string));
        uart_transmit_byte(&uart0,'\n');
    }

    while(1)
    {

    }
    return 0;
}
