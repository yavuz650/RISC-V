#include "../itucore.h"

int dum;

void sorter(int* arr, int len)
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
    int myarr[] = {195,14,176,103,54,32,128};
    sorter(myarr,7);
    return 0;
}

void mti_handler()
{
    dum++;
    if(dum == 10)
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
