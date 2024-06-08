import os
os.environ['DISPLAY'] = ''

from scapy.all import Ether, IP, sendp, Packet, ByteField, ShortField, IntField, XShortField, StrFixedLenField
from scapy.packet import bind_layers
import struct

# Define checksum function
def checksum(data):
    if len(data) % 2 == 1:
        data += b'\0'
    s = sum(struct.unpack("!%dH" % (len(data) // 2), data))
    s = (s >> 16) + (s & 0xffff)
    s += s >> 16
    return ~s & 0xffff

# Define OSPF Header
class OSPF_Hdr(Packet):
    name = "OSPF Header"
    fields_desc = [
        ByteField("version", 2),
        ByteField("type", 1),
        XShortField("len", None),
        IntField("router_id", 0),
        IntField("area_id", 0),
        XShortField("checksum", None),
        XShortField("autype", 0),
        StrFixedLenField("authentication", b'\x00'*8, 8)
    ]
    def post_build(self, p, pay):
        p += pay
        if self.len is None:
            l = len(p)
            p = p[:2] + struct.pack("!H", l) + p[4:]
        if self.checksum is None:
            ck = checksum(p)
            p = p[:12] + struct.pack("!H", ck) + p[14:]
        return p

# Define OSPF Hello Packet
class OSPF_Hello(Packet):
    name = "OSPF Hello"
    fields_desc = [
        IntField("network_mask", 0),
        ShortField("helloInt", 30),
        ByteField("options", 0),                 # Not in use
        ByteField("rtr_pri", 0),                 # Not in use
        IntField("deadInt", 0),                  # Not in use
        IntField("designated_router", 0),        # Not in use
        IntField("backup_designated_router", 0), # Not in use
        IntField("neighbor", 0)                  # Not in use
    ]

# Bind OSPF Hello to OSPF Header
bind_layers(OSPF_Hdr, OSPF_Hello, type=1)
# Create Ethernet Layer
eth = Ether(src="00:00:00:00:00:00", dst="ff:ff:ff:ff:ff:ff") # switch will perform mac_update anyway
# Create IP Layer
ip = IP(src="10.0.0.0", dst="224.0.0.5", proto=89, ttl=1)
# Create OSPF Header Layer
ospf_hdr = OSPF_Hdr(router_id=0x0A00000E, area_id=0)
# Create OSPF Hello Layer
ospf_hello = OSPF_Hello(network_mask=0x00000000, helloInt=30)
# Construct the full packet
packet = eth / ip / ospf_hdr / ospf_hello

# Send the packet
sendp(packet, iface="eth0")