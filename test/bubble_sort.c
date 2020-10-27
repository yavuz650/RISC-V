//#include <stdio.h>

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
    sorter(myarr,7);
    /*for(int i=0;i<5;i++)
    {
        printf("%d ",*(myarr+i));
    }
    printf("\n");*/
    return 0;
}