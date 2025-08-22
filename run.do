vlib work
vlog +acc ./rtl/*
vlog +acc arp_function.sv udp_test_tx.sv
vsim -wlfdeleteonquit -sv_lib  my_dpi work.udp_test_tx
add wave -position insertpoint sim:/udp_test_tx/dut/clk
add wave -position insertpoint sim:/udp_test_tx/dut/ip_rx_error_invalid_checksum
add wave -position insertpoint sim:/udp_test_tx/dut/s_eth*
add wave -position insertpoint sim:/udp_test_tx/dut/m_eth*
add wave -position insertpoint sim:/udp_test_tx/dut/m_ip*
# add wave -position insertpoint sim:/udp_test_tx/dut/ip_complete_64_inst/arp_inst/*
# add wave -position insertpoint sim:/udp_test_tx/dut/ip_complete_64_inst/eth_arb_mux_inst/s*
# add wave -position insertpoint sim:/udp_test_tx/dut/ip_complete_64_inst/eth_arb_mux_inst/m*
# add wave -position insertpoint sim:/udp_test_tx/dut/m_ip_payload_axis_tready*
# add wave -position insertpoint sim:/udp_test_tx/dut/ip_complete_64_inst/ip_inst/*
# add wave -position insertpoint udp_test_tx/dut/ip_complete_64_inst/ip_inst/ip_eth_rx_64_inst/s_eth*
# add wave -position insertpoint udp_test_tx/dut/ip_complete_64_inst/m_ip_payload_axis_tready*
# add wave -position insertpoint udp_test_tx/dut/ip_complete_64_inst/ip_inst/m_ip_payload_axis_tready*
# add wave -position insertpoint udp_test_tx/dut/ip_complete_64_inst/ip_inst/ip_eth_rx_64_inst/*
#add wave -position insertpoint sim:/udp_test_tx/dut/m_eth*
# add wave -position insertpoint sim:/udp_test_tx/dut/ip_complete_64_inst/arp_inst/*

run 700
