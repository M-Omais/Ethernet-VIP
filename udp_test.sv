`include "arp_function.sv"
`timescale 1ps / 1ps
module udp_test ();
    logic        clk, rst;

		// Ethernet frame
		logic        s_eth_hdr_valid, s_eth_hdr_ready;
		logic [47:0] s_eth_dest_mac, s_eth_src_mac;
		logic [15:0] s_eth_type;
		logic [63:0] s_eth_payload_axis_tdata;
		logic [7:0]  s_eth_payload_axis_tkeep;
		logic        s_eth_payload_axis_tvalid, s_eth_payload_axis_tready, s_eth_payload_axis_tlast, s_eth_payload_axis_tuser;

		/*
		* Ethernet frame
		*/
		logic        m_eth_hdr_valid, m_eth_hdr_ready;
		logic [47:0] m_eth_dest_mac, m_eth_src_mac;
		logic [15:0] m_eth_type;
		logic [63:0] m_eth_payload_axis_tdata;
		logic [7:0]  m_eth_payload_axis_tkeep;
		logic        m_eth_payload_axis_tvalid, m_eth_payload_axis_tready, m_eth_payload_axis_tlast, m_eth_payload_axis_tuser;

		/*
		* IP
		*/
		logic        s_ip_hdr_valid, s_ip_hdr_ready;
		logic [5:0]  s_ip_dscp;
		logic [1:0]  s_ip_ecn;
		logic [15:0] s_ip_length;
		logic [7:0]  s_ip_ttl, s_ip_protocol;
		logic [31:0] s_ip_source_ip, s_ip_dest_ip;
		logic [63:0] s_ip_payload_axis_tdata;
		logic [7:0]  s_ip_payload_axis_tkeep;
		logic        s_ip_payload_axis_tvalid, s_ip_payload_axis_tready, s_ip_payload_axis_tlast, s_ip_payload_axis_tuser;

		/*
		* IP (master)
		*/
		logic        m_ip_hdr_valid, m_ip_hdr_ready;
		logic [47:0] m_ip_eth_dest_mac, m_ip_eth_src_mac;
		logic [15:0] m_ip_eth_type;
		logic [3:0]  m_ip_version, m_ip_ihl;
		logic [5:0]  m_ip_dscp;
		logic [1:0]  m_ip_ecn;
		logic [15:0] m_ip_length, m_ip_identification;
		logic [2:0]  m_ip_flags;
		logic [12:0] m_ip_fragment_offset;
		logic [7:0]  m_ip_ttl, m_ip_protocol;
		logic [15:0] m_ip_header_checksum;
		logic [31:0] m_ip_source_ip, m_ip_dest_ip;
		logic [63:0] m_ip_payload_axis_tdata;
		logic [7:0]  m_ip_payload_axis_tkeep;
		logic        m_ip_payload_axis_tvalid, m_ip_payload_axis_tready;
		logic        m_ip_payload_axis_tlast,  m_ip_payload_axis_tuser;

		/*
		* UDP (slave)
		*/
		logic        s_udp_hdr_valid, s_udp_hdr_ready;
		logic [5:0]  s_udp_ip_dscp;
		logic [1:0]  s_udp_ip_ecn;
		logic [7:0]  s_udp_ip_ttl;
		logic [31:0] s_udp_ip_source_ip, s_udp_ip_dest_ip;
		logic [15:0] s_udp_source_port, s_udp_dest_port;
		logic [15:0] s_udp_length, s_udp_checksum;
		logic [63:0] s_udp_payload_axis_tdata;
		logic [7:0]  s_udp_payload_axis_tkeep;
		logic        s_udp_payload_axis_tvalid, s_udp_payload_axis_tready;
		logic        s_udp_payload_axis_tlast,  s_udp_payload_axis_tuser;
		/*
		* UDP  
		*/
		logic        m_udp_hdr_valid, m_udp_hdr_ready;
		logic [47:0] m_udp_eth_dest_mac, m_udp_eth_src_mac;
		logic [15:0] m_udp_eth_type;
		logic [3:0]  m_udp_ip_version, m_udp_ip_ihl;
		logic [5:0]  m_udp_ip_dscp;
		logic [1:0]  m_udp_ip_ecn;
		logic [15:0] m_udp_ip_length, m_udp_ip_identification;
		logic [2:0]  m_udp_ip_flags;
		logic [12:0] m_udp_ip_fragment_offset;
		logic [7:0]  m_udp_ip_ttl, m_udp_ip_protocol;
		logic [15:0] m_udp_ip_header_checksum;
		logic [31:0] m_udp_ip_source_ip, m_udp_ip_dest_ip;
		logic [15:0] m_udp_source_port, m_udp_dest_port, m_udp_length, m_udp_checksum;
		logic [63:0] m_udp_payload_axis_tdata;
		logic [7:0]  m_udp_payload_axis_tkeep;
		logic        m_udp_payload_axis_tvalid, m_udp_payload_axis_tready,
					m_udp_payload_axis_tlast, m_udp_payload_axis_tuser;

		/*
		* Status
		*/
		logic ip_rx_busy, ip_tx_busy, udp_rx_busy, udp_tx_busy;
		logic ip_rx_error_header_early_termination, ip_rx_error_payload_early_termination;
		logic ip_rx_error_invalid_header, ip_rx_error_invalid_checksum;
		logic ip_tx_error_payload_early_termination, ip_tx_error_arp_failed;
		logic udp_rx_error_header_early_termination, udp_rx_error_payload_early_termination;
		logic udp_tx_error_payload_early_termination;

		/*
		* Configuration
		*/
		logic [47:0] local_mac;
		logic [31:0] local_ip, gateway_ip, subnet_mask;
		logic        clear_arp_cache;
		logic 	ip_rx_error_header_early_termination_asserted,
				ip_rx_error_payload_early_termination_asserted,
				ip_rx_error_invalid_header_asserted,
				ip_rx_error_invalid_checksum_asserted,
				ip_tx_error_payload_early_termination_asserted,
				ip_tx_error_arp_failed_asserted,
				udp_rx_error_header_early_termination_asserted,
				udp_rx_error_payload_early_termination_asserted,
				udp_tx_error_payload_early_termination_asserted;


	ETH eth_source, eth_sink;
	IP ip_source, ip_sink;
	logic [63:0] payload [3];  // 32-byte payload
	udp_complete_64#( 
		.ARP_CACHE_ADDR_WIDTH(2),
		.ARP_REQUEST_RETRY_COUNT(4),
		.ARP_REQUEST_RETRY_INTERVAL(150),
		.ARP_REQUEST_TIMEOUT(400),
		.UDP_CHECKSUM_GEN_ENABLE(1),
		.UDP_CHECKSUM_PAYLOAD_FIFO_DEPTH(2048),
		.UDP_CHECKSUM_HEADER_FIFO_DEPTH(8)) dut (
						.clk(clk),
						.rst(rst),
						.s_eth_hdr_valid(s_eth_hdr_valid),
						.s_eth_hdr_ready(s_eth_hdr_ready),
						.s_eth_dest_mac(s_eth_dest_mac),
						.s_eth_src_mac(s_eth_src_mac),
						.s_eth_type(s_eth_type),
						.s_eth_payload_axis_tdata(s_eth_payload_axis_tdata),
						.s_eth_payload_axis_tkeep(s_eth_payload_axis_tkeep),
						.s_eth_payload_axis_tvalid(s_eth_payload_axis_tvalid),
						.s_eth_payload_axis_tready(s_eth_payload_axis_tready),
						.s_eth_payload_axis_tlast(s_eth_payload_axis_tlast),
						.s_eth_payload_axis_tuser(s_eth_payload_axis_tuser),
						.m_eth_hdr_valid(m_eth_hdr_valid),
						.m_eth_hdr_ready(m_eth_hdr_ready),
						.m_eth_dest_mac(m_eth_dest_mac),
						.m_eth_src_mac(m_eth_src_mac),
						.m_eth_type(m_eth_type),
						.m_eth_payload_axis_tdata(m_eth_payload_axis_tdata),
						.m_eth_payload_axis_tkeep(m_eth_payload_axis_tkeep),
						.m_eth_payload_axis_tvalid(m_eth_payload_axis_tvalid),
						.m_eth_payload_axis_tready(m_eth_payload_axis_tready),
						.m_eth_payload_axis_tlast(m_eth_payload_axis_tlast),
						.m_eth_payload_axis_tuser(m_eth_payload_axis_tuser),
						.s_ip_hdr_valid(s_ip_hdr_valid),
						.s_ip_hdr_ready(s_ip_hdr_ready),
						.s_ip_dscp(s_ip_dscp),
						.s_ip_ecn(s_ip_ecn),
						.s_ip_length(s_ip_length),
						.s_ip_ttl(s_ip_ttl),
						.s_ip_protocol(s_ip_protocol),
						.s_ip_source_ip(s_ip_source_ip),
						.s_ip_dest_ip(s_ip_dest_ip),
						.s_ip_payload_axis_tdata(s_ip_payload_axis_tdata),
						.s_ip_payload_axis_tkeep(s_ip_payload_axis_tkeep),
						.s_ip_payload_axis_tvalid(s_ip_payload_axis_tvalid),
						.s_ip_payload_axis_tready(s_ip_payload_axis_tready),
						.s_ip_payload_axis_tlast(s_ip_payload_axis_tlast),
						.s_ip_payload_axis_tuser(s_ip_payload_axis_tuser),
						.m_ip_hdr_valid(m_ip_hdr_valid),
						.m_ip_hdr_ready(m_ip_hdr_ready),
						.m_ip_eth_dest_mac(m_ip_eth_dest_mac),
						.m_ip_eth_src_mac(m_ip_eth_src_mac),
						.m_ip_eth_type(m_ip_eth_type),
						.m_ip_version(m_ip_version),
						.m_ip_ihl(m_ip_ihl),
						.m_ip_dscp(m_ip_dscp),
						.m_ip_ecn(m_ip_ecn),
						.m_ip_length(m_ip_length),
						.m_ip_identification(m_ip_identification),
						.m_ip_flags(m_ip_flags),
						.m_ip_fragment_offset(m_ip_fragment_offset),
						.m_ip_ttl(m_ip_ttl),
						.m_ip_protocol(m_ip_protocol),
						.m_ip_header_checksum(m_ip_header_checksum),
						.m_ip_source_ip(m_ip_source_ip),
						.m_ip_dest_ip(m_ip_dest_ip),
						.m_ip_payload_axis_tdata(m_ip_payload_axis_tdata),
						.m_ip_payload_axis_tkeep(m_ip_payload_axis_tkeep),
						.m_ip_payload_axis_tvalid(m_ip_payload_axis_tvalid),
						.m_ip_payload_axis_tready(m_ip_payload_axis_tready),
						.m_ip_payload_axis_tlast(m_ip_payload_axis_tlast),
						.m_ip_payload_axis_tuser(m_ip_payload_axis_tuser),
						.s_udp_hdr_valid(s_udp_hdr_valid),
						.s_udp_hdr_ready(s_udp_hdr_ready),
						.s_udp_ip_dscp(s_udp_ip_dscp),
						.s_udp_ip_ecn(s_udp_ip_ecn),
						.s_udp_ip_ttl(s_udp_ip_ttl),
						.s_udp_ip_source_ip(s_udp_ip_source_ip),
						.s_udp_ip_dest_ip(s_udp_ip_dest_ip),
						.s_udp_source_port(s_udp_source_port),
						.s_udp_dest_port(s_udp_dest_port),
						.s_udp_length(s_udp_length),
						.s_udp_checksum(s_udp_checksum),
						.s_udp_payload_axis_tdata(s_udp_payload_axis_tdata),
						.s_udp_payload_axis_tkeep(s_udp_payload_axis_tkeep),
						.s_udp_payload_axis_tvalid(s_udp_payload_axis_tvalid),
						.s_udp_payload_axis_tready(s_udp_payload_axis_tready),
						.s_udp_payload_axis_tlast(s_udp_payload_axis_tlast),
						.s_udp_payload_axis_tuser(s_udp_payload_axis_tuser),
						.m_udp_hdr_valid(m_udp_hdr_valid),
						.m_udp_hdr_ready(m_udp_hdr_ready),
						.m_udp_eth_dest_mac(m_udp_eth_dest_mac),
						.m_udp_eth_src_mac(m_udp_eth_src_mac),
						.m_udp_eth_type(m_udp_eth_type),
						.m_udp_ip_version(m_udp_ip_version),
						.m_udp_ip_ihl(m_udp_ip_ihl),
						.m_udp_ip_dscp(m_udp_ip_dscp),
						.m_udp_ip_ecn(m_udp_ip_ecn),
						.m_udp_ip_length(m_udp_ip_length),
						.m_udp_ip_identification(m_udp_ip_identification),
						.m_udp_ip_flags(m_udp_ip_flags),
						.m_udp_ip_fragment_offset(m_udp_ip_fragment_offset),
						.m_udp_ip_ttl(m_udp_ip_ttl),
						.m_udp_ip_protocol(m_udp_ip_protocol),
						.m_udp_ip_header_checksum(m_udp_ip_header_checksum),
						.m_udp_ip_source_ip(m_udp_ip_source_ip),
						.m_udp_ip_dest_ip(m_udp_ip_dest_ip),
						.m_udp_source_port(m_udp_source_port),
						.m_udp_dest_port(m_udp_dest_port),
						.m_udp_length(m_udp_length),
						.m_udp_checksum(m_udp_checksum),
						.m_udp_payload_axis_tdata(m_udp_payload_axis_tdata),
						.m_udp_payload_axis_tkeep(m_udp_payload_axis_tkeep),
						.m_udp_payload_axis_tvalid(m_udp_payload_axis_tvalid),
						.m_udp_payload_axis_tready(m_udp_payload_axis_tready),
						.m_udp_payload_axis_tlast(m_udp_payload_axis_tlast),
						.m_udp_payload_axis_tuser(m_udp_payload_axis_tuser),
						.ip_rx_busy(ip_rx_busy),
						.ip_tx_busy(ip_tx_busy),
						.udp_rx_busy(udp_rx_busy),
						.udp_tx_busy(udp_tx_busy),
						.ip_rx_error_header_early_termination(ip_rx_error_header_early_termination),
						.ip_rx_error_payload_early_termination(ip_rx_error_payload_early_termination),
						.ip_rx_error_invalid_header(ip_rx_error_invalid_header),
						.ip_rx_error_invalid_checksum(ip_rx_error_invalid_checksum),
						.ip_tx_error_payload_early_termination(ip_tx_error_payload_early_termination),
						.ip_tx_error_arp_failed(ip_tx_error_arp_failed),
						.udp_rx_error_header_early_termination(udp_rx_error_header_early_termination),
						.udp_rx_error_payload_early_termination(udp_rx_error_payload_early_termination),
						.udp_tx_error_payload_early_termination(udp_tx_error_payload_early_termination),
						.local_mac(local_mac),
						.local_ip(local_ip),
						.gateway_ip(gateway_ip),
						.subnet_mask(subnet_mask),
						.clear_arp_cache(clear_arp_cache)
);
	always #4 clk = ~clk;
	always @(*) begin
		if (ip_rx_error_header_early_termination)
			ip_rx_error_header_early_termination_asserted = 1'b1;
		if (ip_rx_error_payload_early_termination)
			ip_rx_error_payload_early_termination_asserted = 1'b1;
		if (ip_rx_error_invalid_header)
			ip_rx_error_invalid_header_asserted = 1'b1;
		if (ip_rx_error_invalid_checksum)
			ip_rx_error_invalid_checksum_asserted = 1'b1;
		if (ip_tx_error_payload_early_termination)
			ip_tx_error_payload_early_termination_asserted = 1'b1;
		if (ip_tx_error_arp_failed)
			ip_tx_error_arp_failed_asserted = 1'b1;
		if (udp_rx_error_header_early_termination)
			udp_rx_error_header_early_termination_asserted = 1'b1;
		if (udp_rx_error_payload_early_termination)
			udp_rx_error_payload_early_termination_asserted = 1'b1;
		if (udp_tx_error_payload_early_termination)
			udp_tx_error_payload_early_termination_asserted = 1'b1;
	end

	initial begin
		clk = 1'b0;
		// for (int i = 0; i < 32; i++) begin
		// 	payload[i] = i;   // same as Python range(32)
		// end
	end
	initial begin
		#100;
		@(posedge clk);
		rst = 1'b1;
		@(posedge clk);
		rst = 1'b0;
		@(posedge clk);
		#100;
		@(posedge clk);
		local_mac = 48'h5A5152535455;
        local_ip = 32'hc0a80164;
        gateway_ip = 32'hc0a80101;
        subnet_mask = 32'hffffff00;
		eth_source = new();
		eth_sink = new();
		ip_source = new();
		ip_sink = new();
		@(posedge clk);
        $display("test 1: test IP RX packet");
		eth_source.dst_mac = 48'hDAD1D2D3D4D5;
		eth_source.src_mac = 48'h5A5152535455;
		eth_source.eth_type = 16'h0800;
		// IPv4 header fields from Python test_frame

		ip_source.version        = 4;              // test_frame.ip_version
		ip_source.ihl            = 5;              // test_frame.ip_ihl
		ip_source.dscp_ecn       = {6'd0, 2'd0};   // test_frame.ip_dscp = 0, ip_ecn = 0
		ip_source.total_length   = (5*4) + 8;     
		ip_source.identification = 16'd0;          // test_frame.ip_identification
		ip_source.flags          = 3'd2;           // test_frame.ip_flags
		ip_source.frag_offset    = 13'd0;          // test_frame.ip_fragment_offset
		ip_source.ttl            = 8'd64;          // test_frame.ip_ttl
		ip_source.protocol       = 8'h10;          // test_frame.ip_protocol
		ip_source.hdr_checksum   = 16'hb6b7;       // auto (None in Python)
		// Source IP: 192.168.1.100 (0xC0A80164)
		ip_source.src_ip = '{8'hC0, 8'hA8, 8'h01, 8'h64};  
		
		// Destination IP: 192.168.1.102 (0xC0A80166)
		ip_source.dst_ip = '{8'hC0, 8'hA8, 8'h01, 8'h66};  
		ip_source.pack(payload);
		ip_source.print();
		s_eth_hdr_valid = 1'b1;
		m_ip_hdr_ready = 1'b0;
		m_eth_hdr_ready = 1'b1;
		m_ip_payload_axis_tready  <= 1'b1;


		// $finish;
	end
	int j=0;
	always @(posedge clk)begin
		if(s_eth_hdr_valid)begin
			s_eth_dest_mac <= eth_source.dst_mac;
			s_eth_src_mac <= eth_source.src_mac;
			s_eth_type <= eth_source.eth_type;
			s_eth_hdr_valid <= 1'b1;
			s_eth_payload_axis_tvalid<=1'b1;
			s_eth_payload_axis_tkeep<=8'hFF;
			s_eth_payload_axis_tdata<=payload[j];
			s_eth_payload_axis_tuser <= 1'b0;
			s_eth_payload_axis_tlast<=1'b0;		
			// j++;
		end

		if (s_eth_payload_axis_tready && j < 2) begin
			s_eth_hdr_valid <= 1'b0;	
			s_eth_payload_axis_tvalid<=1'b1;
			s_eth_payload_axis_tkeep<=8'hFF;
			s_eth_payload_axis_tdata<=payload[++j];
			s_eth_payload_axis_tuser <= 1'b0;
			s_eth_payload_axis_tlast<=1'b0;
			// if(j == 1) 		
			// j++;
		end
		if(j == 3)begin
			s_eth_payload_axis_tlast<=1'b1;		
			// s_eth_payload_axis_tkeep<=8'h0F;
		end 
		if(j == 2)begin
			// s_eth_payload_axis_tlast<=1'b1;		
			s_eth_payload_axis_tkeep<=8'h0F;
			j<=j+1;
		end 
	end
	always @(*) begin
		if(s_eth_payload_axis_tready) 
			m_ip_payload_axis_tready  <= 1'b1;

	end

endmodule