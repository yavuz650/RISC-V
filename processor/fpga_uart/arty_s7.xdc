#Constraints for Arty-S7 FPGA Board

#100MHz input clock
set_property -dict { PACKAGE_PIN R2    IOSTANDARD SSTL135 } [get_ports { M100_clk_i }]; #IO_L12P_T1_MRCC_34 Sch=ddr3_clk[200]
#Reset input from switch
set_property -dict { PACKAGE_PIN H14   IOSTANDARD LVCMOS33 } [get_ports { reset_i }]; #IO_L20N_T3_A19_15 Sch=sw[0]
#Uart RX
set_property -dict { PACKAGE_PIN V12   IOSTANDARD LVCMOS33 } [get_ports { rx_i }]; #IO_0_14 Sch=ck_io[0]
#Uart TX
set_property -dict { PACKAGE_PIN R12   IOSTANDARD LVCMOS33 } [get_ports { tx_o }]; #IO_L6N_T0_D08_VREF_14   Sch=ck_io[1]

#Debug leds
set_property -dict { PACKAGE_PIN E18   IOSTANDARD LVCMOS33 } [get_ports { led1 }]; #IO_L16N_T2_A27_15 Sch=led[2]
set_property -dict { PACKAGE_PIN F13   IOSTANDARD LVCMOS33 } [get_ports { led2 }]; #IO_L17P_T2_A26_15 Sch=led[3]
set_property -dict { PACKAGE_PIN H15   IOSTANDARD LVCMOS33 } [get_ports { led4 }]; #IO_L18P_T2_A24_15 Sch=led[5]

