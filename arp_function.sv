// Example of using SystemVerilog DPI-C with C++ code

module automatic test;

    // Import the C++ DPI function
	import "DPI-C" context function int helloFromCppArray(
		output byte data[],
		inout int len,
		input string src_mac,
		input string src_ip,
		input string dst_mac,
		input string dst_ip
	);
	byte my_data[];  // Partial init; rest will be 0 by default
	int result;
    int len = 0;

    string src_mac = "05:00:00:00:00:01";
    string src_ip  = "192.168.1.100";
    string dst_mac = "ff:ff:ff:ff:ff:ff";
    string dst_ip  = "192.168.1.1";
	initial begin
		my_data = new[1500];
		len =1;
        result = helloFromCppArray(my_data, len, src_mac, src_ip, dst_mac, dst_ip);
		for (int i = 0;i<len ;i++ ) begin
			$write("%h\t",my_data[i]);
		end
	end

endmodule
