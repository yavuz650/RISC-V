# Core
This directory contains the Verilog source files of the core.

## Integrating the core
In order to integrate Hornet core into your design, you need to instantiate it in your source file as follows,

```
core    //Program counter will be set to reset_vector when a reset occurs. By default, it is 0.
        #(.reset_vector())
        core0(
        //Clock and reset signals.
        .clk_i(),
        .reset_i(), //active-low, asynchronous reset

        //Data memory interface
        .data_addr_o(),
        .data_i(),
        .data_o(),
        .data_wmask_o(),
        .data_wen_o(), //active-low
        .data_req_o(),
        .data_err_i(),

        //Instruction memory interface
        .instr_addr_o(),
        .instr_i(),
        .instr_access_fault_i(),

        //Interrupts
        .meip_i(),
        .mtip_i(),
        .msip_i(),
        .fast_irq_i(),
        .irq_ack_o());
```

Of course, you need to include all the source files in this directory to your project, and set `core.v` as your top module. 

See the `processor` directory for examples of integration.
