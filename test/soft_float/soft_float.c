#define DEBUG_IF_ADDR 0x00002010
int main()
{
    volatile float a = 773495.367;
    volatile float b = 253.0538;
    volatile float c = a/b;

    int *addr_ptr = DEBUG_IF_ADDR;
    if(c == 3056.644043f)
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
