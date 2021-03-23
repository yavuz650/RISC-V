#include <stdlib.h>
#include <stdint.h>
#define UART_RX_ADDR_OFFSET 0x1
#define UART_STATUS_ADDR_OFFSET 0x2

typedef struct uart
{
    uint32_t *base_addr;
}uart;


void uart_init(uart *uart_ptr, uint32_t base_addr);
void uart_transmit_byte(uart *uart_ptr, const char data);
void uart_transmit_string(uart *uart_ptr, char const *data, size_t len);

