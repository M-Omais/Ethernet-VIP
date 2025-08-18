vlib work
vlog +acc ./rtl/*
vlog +acc arp_function.sv arp_test.sv
vsim -sv_lib my_dpi work.arp_test
add wave -position insertpoint  \
sim:/arp_test/* 
run 1000
