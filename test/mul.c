//#include <stdio.h>

int mul(int a, int b)
{
    int result = 0, shamt = 1;
    for (unsigned int mask = 1; mask < 2147483648;)
    {
        if(b & mask)
        {
            result += a << (shamt-1);
        }
        mask = mask << 1;
        shamt++;
        if(mask > b)
            break;
    }
    return result;    
}

int main()
{
    int x = 7258, y = 1463;
    int z = mul(x,y);

    //printf("%d\n",z);
}