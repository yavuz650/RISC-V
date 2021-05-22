#include "string.h"
#define DEBUG_IF_ADDR 0x00002010

int main() 
{
    volatile int a = 532;
    volatile int b = 18;
    volatile int c = a*b;

    int *addr_ptr = DEBUG_IF_ADDR;
    if(c == 9576)
    {
        //success
        *addr_ptr = 1;
    }
    else
    {
        //failure
        *addr_ptr = 0;
    }
    return 0;
}
