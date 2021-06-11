#include "../../lib/irq.h"
#define MTIME_ADDR 0x00002000
#define MTIMECMP_ADDR 0x00002008
#define DEBUG_IF_ADDR 0x00002010
int dum;

void bubble_sort(int* arr, int len)
{
    int sort_num;
    do
    {
        sort_num = 0;
        for(int i=0;i<len-1;i++)
        {
            if(*(arr+i) > *(arr+i+1))
            {
                int tmp = *(arr+i);
                *(arr+i) = *(arr+i+1);
                *(arr+i+1) = tmp;
                sort_num++;
            }
        } 
    }
    while(sort_num!=0);
}

int main() 
{
    dum=0;
    SET_MTVEC_VECTOR_MODE();
    ENABLE_GLOBAL_IRQ();
    ENABLE_MTI();
    ENABLE_MEI();
    int unsorted_arr[] = {195,14,176,103,54,32,128};
    int sorted_arr[] = {14,32,54,103,128,176,195};
    bubble_sort(unsorted_arr,7);
    int *addr_ptr = DEBUG_IF_ADDR;
    if(!memcmp((char*) sorted_arr, (char*) unsorted_arr, 28))
    {
        *addr_ptr = 1; //success
    }
    else
    {
        //failure
        *addr_ptr = 0;
    }
    return 0;
}

void mti_handler()
{
    dum++;
    if(dum == 30)
        DISABLE_MTI();
        
    int *mtime_addr_ptr = MTIME_ADDR;
    int *mtimecmp_addr_ptr = MTIMECMP_ADDR;
    int mtime = *mtime_addr_ptr;
    *mtimecmp_addr_ptr = mtime+25; //mtimecmp = mtime+25;
}

void mei_handler()
{
    dum--;
}

void exc_handler() {}
