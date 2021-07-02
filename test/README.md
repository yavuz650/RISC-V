# Testing Hornet via Simulations
This directory contains several test programs. As Hornet is not formally verified, we developed simple C programs to verify the functionality of the core.

You can also find a C runtime routine (crt0.s) and a default linker script (linksc.ld) to work with. The crt routine initialies the stack pointer and jumps to `main`. The linker script defines the following memory regions, which you can change as you wish,
*    `ROM(RX)   : ORIGIN = 0x00000000, LENGTH = 0x00001E00`
*    `RAM(WAIL) : ORIGIN = 0x00001E00, LENGTH = 0x000001FC`

The `rom_generator.c` simply generates the opcodes for the ROM in .data file format. You can load that .data file to your main memory to simulate the program. See `/processor/barebones` folder to learn how exactly you can do that.

Each test folder has a `makefile` that compiles the program appropriately, and generates the ROM. 

There are many ways to simulate Hornet. Essentially, you could use any Verilog simulator to test the core.

## Simulating with Verilator
Simulating with Verilator is very simple if you are working on a Linux machine. First, make sure you have Verilator installed in your system. For Ubuntu, you can install it with the command below,

`sudo apt-get install verilator`

Then, once you are in the `test` directory, you can simply execute the `run_tests` script to automatically simulate all the test programs in the directory.

`./run_tests`

You should now see the output of the tests, hopefully they all succeed. This automated testing scheme is particularly useful when you make some changes to the design and then want to see if you broke anything.

 You can also simulate each program separately by changing to its directory and running the test script that's in there. For example, if you wanted to test `bubble_sort`, you would do the following,

`cd bubble_sort` \
`./bubble_sort_script`

Note that, with Verilator, we do not use Verilog testbenches. Instead, the .cpp wrapper file becomes your testbench.

You can also use GTKWave to view waveforms that Verilator generates. First, install GTKWave in your system if you haven't already,

`sudo apt-get install gtkwave`

Now, for example, if you wanted to view the waveform of `bubble_sort` test program, you would do the following,

`cd obj_dir` \
`gtkwave simx.vcd`

You should now see GTKWave opening up.

## Simulating with Xilinx Vivado
Vivado is the program you want to use when working with FPGAs. Fortunately, you can easily simulate Hornet in Vivado.

First, create a new project in Vivado and import all the Verilog source files in the `core`, `peripherals`, and `processor/barebones` directory. Everything except `barebones_top_tb.v` should be added as a design source. The testbench file should be added as a simulation source, obviously. Next, you also need to add the `.data` files in the `memory_contents` directory. We will use those files to initialize the ROM. Vivado should infer that those files are memory initialization files and group them accordingly.

Your environment should be ready for simulation now. Simply go into the testbench file and uncomment whichever `$readmem` command you want. Finally, you can run a behavioral simulation. You can also run post-synthesis or post-implementation simulations, but these would take forever to simulate.

## Simulating with Cadence Xcelium
Xcelium is like a Ferrari, whereas Verilator is like a Honda. You can absolutely simulate Hornet using Xcelium, if you are lucky enough to get your hands on this simulator. 

First, change your directory to `processor/barebones`. There, compile the source files with the command below,

```
xmvlog ../../core/core.v ../../core/ALU.v ../../core/control_unit.v ../../core/forwarding_unit.v ../../core/hazard_detection_unit.v \
../../core/imm_decoder.v ../../core/load_store_unit.v ../../core/csr_unit.v \
../../peripherals/memory_2rw.v ../../peripherals/mtime_registers.v \
../../core/muldiv/divider_32.v ../../core/muldiv/multiplier_32.v ../../core/muldiv/MULDIV_ctrl.v ../../core/muldiv/MULDIV_in.v \
../../core/muldiv/MUL_DIV_out.v ../../core/muldiv/MULDIV_top.v ../../peripherals/debug_interface.v \
barebones_top.v barebones_top_tb.v

```
You could also use `` `include `` command in the source files to avoid this verbose command. Now, elaborate the design with the command below,

`xmelab -access rwc barebones_top_tb`

Finally, launch the simulator,

`xmsim -gui barebones_top_tb`

## Adding new tests
Adding new tests is quite straightforward. You would need to create a new folder and write your C/C++ code, a makefile, and a .cpp wrapper if you are using Verilator.
