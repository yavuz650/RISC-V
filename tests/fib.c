
int main()
{
    int a=1,b=0,c=0,d;
    
    for (int i = 0; i < 10; i++)
    {
        d=b;
        c=a;
        a=a+b;
        b=c;
    }
}