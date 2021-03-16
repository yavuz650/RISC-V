#set_db lib_search_path /work/kits/tsmc/lib/40lp/TSMCHOME/digital/Front_End/timing_power_noise/NLDM/tcbn40lpbwp_200a
#set_db library {tcbn40lpbwpbc.lib} 
#set_db lib_search_path {/home/ytozlu/projects/BASAK/projectDir/yavuz_digital/riscv/memory}
set_db library {/vlsi/kits/tsmc/lib/90gp/TSMCHOME/digital/Front_End/timing_power_noise/NLDM/tcbn90gbwp14t_220a/tcbn90gbwp14ttc.lib}  
#/home/ytozlu/projects/BASAK/projectDir/yavuz_digital/riscv/memory/sram_1rw1r_32_512_8_freepdk45_TT_1p0V_25C.lib}
#gscl45nm.lib

set_db information_level 11
set_db delete_unloaded_insts false
set_db delete_unloaded_seqs false
#set_db write_vlog_preserve_net_name true
#set_db hdl_preserve_unused_flop true
#set_db hdl_preserve_unused_latch true
#set_db hdl_preserve_unused_registers true
#set_db optimize_merge_flops false
#set_db optimize_merge_latches false
#set_db optimize_constant_0_flops false
#set_db optimize_constant_1_flops false
#set_db optimize_constant_feedback_seqs false
#set_db control_logic_optimization none
#set_db auto_ungroup none
#set_db hdl_preserve_async_sr_priority_logic true
#set_db delete_flops_on_preserved_net false
#set_db hdl_ff_keep_feedback true

# Reading Verilog Codes and Elaborating
read_hdl -v2001 {uart_top.v}
elaborate uart_top

# Defining Time Constraints - ns
create_clock -period 10 -name clkin1 -domain domain_1 clk_i
set_clock_latency -max 1 clkin1
# CLOCK UNCERTAINTY (JITTER) 
set_clock_uncertainty -setup 1 clkin1
set_clock_uncertainty -hold 1 clkin1
# DELAY FROM INPUT PIN TO CLOCK                                           
set_input_delay -clock clkin1 -clock_rise 1 [all_inputs]
set_output_delay -clock clkin1 -clock_rise 1 [all_outputs]

set_driving_cell reset_i meip_i -cell BUFFPD12BWP14T
set_load 1 irq_ack_o

# Synthesizing
#set_db operating_conditions BCCOM
set_db syn_generic_effort high
set_db syn_map_effort high
set_db syn_opt_effort high
syn_generic uart_top
syn_map uart_top
syn_opt uart_top


# Writing Report Files
report timing > report_time.txt
report gates > report_gates.txt
report area > report_area.txt

# Writing Design Files
write_hdl uart_top -language v2001 > syn_uart_top.v
write_sdf -edges check_edge -design uart_top > uart_top.sdf

#add timescale directive
file rename syn_uart_top.v syn_orig.v
set fin [open syn_orig.v r]
set fout [open syn_uart_top.v w]

puts $fout "`timescale 1ns/1ps"
fcopy $fin $fout

close $fin
close $fout
file delete syn_orig.v

