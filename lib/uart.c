#include "uart.h"

void uart_init(uart *uart_ptr, uint32_t base_addr)
{
    uart_ptr->base_addr = base_addr;
}

void uart_transmit_byte(uart *uart_ptr, const char data)
{
    volatile char *status_ptr = (char*)(uart_ptr->base_addr)+UART_STATUS_ADDR_OFFSET;
    volatile char uart_status;

    while (1)
    {
        uart_status = *status_ptr;
        uart_status = uart_status & 0x2; //extract the second bit
        if(!uart_status)
            break;
    }
    char *tx_ptr = uart_ptr->base_addr;
    *tx_ptr = data;
}

void uart_transmit_string(uart *uart_ptr, char const *data, size_t len)
{
    for (size_t i = 0; i < len; i++)
    {
        uart_transmit_byte(uart_ptr,*data++);
    }
}
