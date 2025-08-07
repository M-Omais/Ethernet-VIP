from scapy.layers.l2 import Ether, ARP
from scapy.layers.inet import IP, UDP

def create_arp_frame(hwsrc, psrc, hwdst, pdst,
                     hwtype=1, ptype=0x0800, hwlen=6, plen=4, op=2):
    # Create an ARP packet and return it as a byte list
    arp = ARP(hwtype=hwtype, ptype=ptype, hwlen=hwlen,
              plen=plen, op=op, hwsrc=hwsrc, psrc=psrc,
              hwdst=hwdst, pdst=pdst)
    return list(bytes(arp))

def create_eth_frame(src_mac, dst_mac, eth_type=0x0800):
    # Create an Ethernet frame with given source/destination MAC
    eth = Ether(src=src_mac, dst=dst_mac, type=eth_type)
    return list(bytes(eth))

def create_ip_header(src_ip, dst_ip, proto=17):
    # Create an IP header with given source/destination IPs
    ip = IP(src=src_ip, dst=dst_ip, proto=proto)
    return list(bytes(ip))

def create_udp_header(sport, dport, payload_len=0):
    # Create a UDP header with given ports and optional payload length
    udp = UDP(sport=sport, dport=dport, len=8 + payload_len)
    return list(bytes(udp))

# Sample test packet for extracting fields
eth = Ether(src='5a:51:52:53:54:55', dst='02:00:00:00:00:00')
ip = IP(src='192.168.1.100', dst='192.168.1.128')
udp = UDP(sport=5678, dport=1234)
test_pkt = eth / ip / udp

# Create ARP frame using the test packet's values
arp = create_arp_frame(
    hwsrc=test_pkt.src,
    psrc=test_pkt[IP].src,
    hwdst=test_pkt.dst,
    pdst=test_pkt[IP].dst
)
