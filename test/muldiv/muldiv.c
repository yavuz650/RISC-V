#include "string.h"
#include "stdint.h"
#define DEBUG_IF_ADDR 0x00002010

volatile int64_t mul_res[10];
volatile int div_res[10];

int main() 
{
    const volatile int a[10] = {-619183,616959,263374,-3035621,-4968369,4637756,-935330,2832102,-4746714,6051886};
    const volatile int b[10] = {747432,902274,-1767403,5589605,-6251467,5605882,5520004,6582310,-4458287,4367400};
    const volatile int64_t c[10] = {-462797188056,556666064766,-465487997722,-16967922319705,31059594847323,25998712880792,-5163025341320,18641773315620,21162213318918,26431006916400};

    for (int i = 0; i < 10; i++)
    {
        mul_res[i] = (int64_t)a[i] * b[i];
    }

    for (int i = 0; i < 10; i++)
    {
        div_res[i] = c[i] / b[i];
    }
    
    int *addr_ptr = DEBUG_IF_ADDR;

    if(memcmp(mul_res,c,80) == 0 && memcmp(div_res,a,40) == 0)
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
