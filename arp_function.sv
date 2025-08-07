// Example of using SystemVerilog DPI-C with C++ code
class ARP;
	bit [15:0] htype;         // Hardware type
	bit [15:0] ptype;         // Protocol type
	bit [7:0]  hlen;          // Hardware address length
	bit [7:0]  plen;          // Protocol address length
	bit [15:0] oper;          // Opcode
	bit [7:0]	sha[6];        // Sender hardware (MAC) address
	bit [7:0]	spa[4];        // Sender protocol (IP) address
	bit [7:0]	tha[6];        // Target hardware (MAC) address
	bit [7:0]	tpa[4];        // Target protocol (IP) address
	function new();
		
	endfunction //new()
	function void print();
		$display("------ ARP Packet ------");
		$display("Hardware Type      : 0x%04h", htype);
		$display("Protocol Type      : 0x%04h", ptype);
		$display("HW Addr Length     : %0d", hlen);
		$display("Protocol Addr Len  : %0d", plen);
		$display("Opcode             : 0x%04h", oper);

		$write("Sender MAC Address : ");
		foreach (sha[i]) begin
			$write("%02x", sha[i]);
			if (i < 5) $write(":");
		end
		$write("\n");

		$write("Sender IP Address  : ");
		foreach (spa[i]) begin
			$write("%0d", spa[i]);
			if (i < 3) $write(".");
		end
		$write("\n");

		$write("Target MAC Address : ");
		foreach (tha[i]) begin
			$write("%02x", tha[i]);
			if (i < 5) $write(":");
		end
		$write("\n");

		$write("Target IP Address  : ");
		foreach (tpa[i]) begin
			$write("%0d", tpa[i]);
			if (i < 3) $write(".");
		end
		$write("\n");

		$display("------------------------");
	endfunction
	function void parse(byte my_data[28]);
		    // Parse fixed fields
		htype	= 	{my_data[0], my_data[1]};
		ptype	= 	{my_data[2], my_data[3]};
		hlen	= 	my_data[4];
		plen	= 	my_data[5];
		oper	= 	{my_data[6], my_data[7]};

		// MAC addresses
		for (int i = 0; i < 6; i++) sha[i] = my_data[8+i];
		for (int i = 0; i < 4; i++) spa[i] = my_data[14+i];
		for (int i = 0; i < 6; i++) tha[i] = my_data[18+i];
		for (int i = 0; i < 4; i++) tpa[i] = my_data[24+i];
		
	endfunction
endclass

class ETH;
	bit [47:0] dst_mac;
	bit [47:0] src_mac;
	bit [15:0] eth_type;

	function new();
	endfunction

	function void parse(byte data[14]);
		dst_mac = {data[0], data[1], data[2], data[3], data[4], data[5]};
		src_mac = {data[6], data[7], data[8], data[9], data[10], data[11]};
		eth_type = {data[12], data[13]};
	endfunction

	function void print();
		$display("------ Ethernet Frame ------");
		$display("Destination MAC : %02x:%02x:%02x:%02x:%02x:%02x",
			dst_mac[47:40], dst_mac[39:32], dst_mac[31:24],
			dst_mac[23:16], dst_mac[15:8], dst_mac[7:0]);
		$display("Source MAC      : %02x:%02x:%02x:%02x:%02x:%02x",
			src_mac[47:40], src_mac[39:32], src_mac[31:24],
			src_mac[23:16], src_mac[15:8], src_mac[7:0]);
		$display("Ethertype       : 0x%04h", eth_type);
		$display("----------------------------");
	endfunction
endclass

class IP;
	bit [3:0]  version;
	bit [3:0]  ihl;
	bit [7:0]  dscp_ecn;
	bit [15:0] total_length;
	bit [15:0] identification;
	bit [2:0]  flags;
	bit [12:0] frag_offset;
	bit [7:0]  ttl;
	bit [7:0]  protocol;
	bit [15:0] hdr_checksum;
	bit [7:0]  src_ip[4];
	bit [7:0]  dst_ip[4];

	function new();
	endfunction

	function void parse(byte data[20]);
		version     = data[0][7:4];
		ihl         = data[0][3:0];
		dscp_ecn    = data[1];
		total_length = {data[2], data[3]};
		identification = {data[4], data[5]};
		flags       = data[6][7:5];
		frag_offset = {data[6][4:0], data[7]};
		ttl         = data[8];
		protocol    = data[9];
		hdr_checksum = {data[10], data[11]};
		for (int i = 0; i < 4; i++) src_ip[i] = data[12+i];
		for (int i = 0; i < 4; i++) dst_ip[i] = data[16+i];
	endfunction

	function void print();
		$display("-------- IPv4 Packet --------");
		$display("Version         : %0d", version);
		$display("IHL             : %0d", ihl);
		$display("DSCP/ECN        : 0x%02h", dscp_ecn);
		$display("Total Length    : %0d", total_length);
		$display("Identification  : 0x%04h", identification);
		$display("Flags           : 0x%01h", flags);
		$display("Fragment Offset : %0d", frag_offset);
		$display("TTL             : %0d", ttl);
		$display("Protocol        : 0x%02h", protocol);
		$display("Header Checksum : 0x%04h", hdr_checksum);
		$write("Source IP       : ");
		foreach (src_ip[i]) begin
			$write("%0d", src_ip[i]);
			if (i < 3) $write(".");
		end
		$write("\nDestination IP  : ");
		foreach (dst_ip[i]) begin
			$write("%0d", dst_ip[i]);
			if (i < 3) $write(".");
		end
		$display("\n------------------------------");
	endfunction
endclass

class UDP;
	bit [15:0] src_port;
	bit [15:0] dst_port;
	bit [15:0] length;
	bit [15:0] checksum;

	function new();
	endfunction

	function void parse(byte data[8]);
		src_port = {data[0], data[1]};
		dst_port = {data[2], data[3]};
		length   = {data[4], data[5]};
		checksum = {data[6], data[7]};
	endfunction

	function void print();
		$display("-------- UDP Segment --------");
		$display("Source Port      : %0d", src_port);
		$display("Destination Port : %0d", dst_port);
		$display("Length           : %0d", length);
		$display("Checksum         : 0x%04h", checksum);
		$display("-----------------------------");
	endfunction
endclass


module automatic test;

    // Import the C++ DPI function
	import "DPI-C" context function int arp_frame(
		output byte data[],
		inout int len,
		input string src_mac,
		input string src_ip,
		input string dst_mac,
		input string dst_ip
	);

	import "DPI-C" context function int eth_frame(
		output byte data[],
		inout int len,
		input string src_mac,
		input string dst_mac,
		input int eth_type
	);

	import "DPI-C" context function int ip_header(
		output byte data[],
		inout int len,
		input string src_ip,
		input string dst_ip,
		input int proto
	);

	import "DPI-C" context function int udp_header(
		output byte data[],
		inout int len,
		input int sport,
		input int dport,
		input int payload_len
	);

byte eth_data[];
    byte arp_data[];
    byte ip_data[];
    byte udp_data[];

    int eth_len = 0;
    int arp_len = 0;
    int ip_len  = 0;
    int udp_len = 0;
    int result;

    // Ethernet
    string eth_src_mac = "05:00:00:00:00:01";
    string eth_dst_mac = "ff:ff:ff:ff:ff:ff";
    int eth_type_arp   = 16'h0806;
    int eth_type_ip    = 16'h0800;

    // IP
    string src_ip  = "192.168.1.100";
    string dst_ip  = "192.168.1.1";
    int proto_udp  = 17;

    // UDP
    int sport       = 1234;
    int dport       = 5678;
    int payload_len = 16;

    // Object declarations
    ETH eth_obj;
    ARP arp_obj;
    IP  ip_obj;
    UDP udp_obj;

    initial begin
        // Ethernet + ARP
        eth_data = new[14];
        arp_data = new[28];
        eth_len  = 1;
        arp_len  = 1;

        result = eth_frame(eth_data, eth_len, eth_src_mac, eth_dst_mac, eth_type_arp);
        result = arp_frame(arp_data, arp_len, eth_src_mac, src_ip, eth_dst_mac, dst_ip);

        if (result != -1) begin
            eth_obj = new(); arp_obj = new();
            eth_obj.parse(eth_data); eth_obj.print();
            arp_obj.parse(arp_data); arp_obj.print();
        end

        // Ethernet + IP + UDP
        eth_data = new[14];
        ip_data  = new[20];
        udp_data = new[8];
        eth_len  = 1;
        ip_len   = 1;
        udp_len  = 1;

        result = eth_frame(eth_data, eth_len, eth_src_mac, eth_dst_mac, eth_type_ip);
        result = ip_header(ip_data, ip_len, src_ip, dst_ip, proto_udp);
        result = udp_header(udp_data, udp_len, sport, dport, payload_len);

        if (result != -1) begin
            eth_obj = new(); ip_obj = new(); udp_obj = new();
            eth_obj.parse(eth_data); eth_obj.print();
            ip_obj.parse(ip_data); ip_obj.print();
            udp_obj.parse(udp_data); udp_obj.print();
        end
    end
endmodule
