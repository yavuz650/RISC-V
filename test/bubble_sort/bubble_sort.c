#include "string.h"
#define DEBUG_IF_ADDR 0x00002010

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
    int myarr[] = {195,14,176,103,54,32,128};
    int sorter_arr[] = {14,32,54,103,128,176,195};
    sorter(myarr,7);

    int *addr_ptr = DEBUG_IF_ADDR;

    if(!memcmp((char*) sorter_arr, (char*) myarr, 7))
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