# Software Libraries
This directory contains useful libraries to help you get started with Hornet. 

`irq.h` provides the essential functions to utilize interrupts in Hornet. You just need to include `irq.h` in your source file, and compile `irq.c` with it. You can then define your interrupt handler routines in your source file. For example, if you wanted to use timer interrupts, you would define the `mti_handler()` function in your source file. See the examples in the `test` folder for more details.

`uart.h` provides simple UART data transmission functions. However, note that this library will only work with the UART module provided in the `peripherals` directory.