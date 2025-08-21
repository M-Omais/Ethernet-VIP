vlib work
vlog +acc ./rtl/*
vlog +acc arp_function.sv udp_test.sv
vsim -wlfdeleteonquit -sv_lib  my_dpi work.udp_test
add wave -position insertpoint sim:/udp_test/dut/clk
add wave -position insertpoint sim:/udp_test/dut/s_eth*
add wave -position insertpoint sim:/udp_test/dut/m_ip*
# add wave -position insertpoint sim:/udp_test/dut/m_ip_payload_axis_tready*
#add wave -position insertpoint sim:/udp_test/dut/ip_complete_64_inst/ip_inst/s*
# add wave -position insertpoint udp_test/dut/ip_complete_64_inst/ip_inst/ip_eth_rx_64_inst/s_eth*
# add wave -position insertpoint udp_test/dut/ip_complete_64_inst/m_ip_payload_axis_tready*
# add wave -position insertpoint udp_test/dut/ip_complete_64_inst/ip_inst/m_ip_payload_axis_tready*
# add wave -position insertpoint udp_test/dut/ip_complete_64_inst/ip_inst/ip_eth_rx_64_inst/*
#add wave -position insertpoint sim:/udp_test/dut/m_eth*

run 700
