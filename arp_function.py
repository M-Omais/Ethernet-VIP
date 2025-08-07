from scapy.layers.l2 import Ether, ARP
from scapy.layers.inet import IP, UDP
def create_arp_frame(hwsrc, psrc, hwdst, pdst,
                     hwtype=1, ptype=0x0800, hwlen=6, plen=4, op=2):
    arp = ARP(hwtype=hwtype,	ptype=ptype,	hwlen=hwlen,	plen=plen,	op=op,	hwsrc=hwsrc,	psrc=psrc,	hwdst=hwdst,	pdst=pdst)
    byte_data = bytes(arp)
    # print(byte_data.hex())
    return list(byte_data)
eth = Ether(src='5a:51:52:53:54:55', dst='02:00:00:00:00:00')
ip = IP(src='192.168.1.100', dst='192.168.1.128')
udp = UDP(sport=5678, dport=1234)
test_pkt = eth / ip / udp 
arp = ARP(hwtype=1, ptype=0x0800, hwlen=6, plen=4, op=2,
	hwsrc=test_pkt.src, psrc=test_pkt[IP].src,
	hwdst=test_pkt.dst, pdst=test_pkt[IP].dst)
# print(arp)
create_arp_frame(hwtype=1, ptype=0x0800, hwlen=6, plen=4, op=2,
	hwsrc=test_pkt.src, psrc=test_pkt[IP].src,
	hwdst=test_pkt.dst, pdst=test_pkt[IP].dst)