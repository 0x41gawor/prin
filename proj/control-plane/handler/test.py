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
        IntField("routerid", 0),
        IntField("areaid", 0),
        XShortField("chksum", None),
        XShortField("authtype", 0),
        StrFixedLenField("auth", b'\x00'*8, 8)
    ]
    def post_build(self, p, pay):
        p += pay
        if self.len is None:
            l = len(p)
            p = p[:2] + struct.pack("!H", l) + p[4:]
        if self.chksum is None:
            ck = checksum(p)
            p = p[:12] + struct.pack("!H", ck) + p[14:]
        return p

# Define OSPF Hello Packet
class OSPF_Hello(Packet):
    name = "OSPF Hello"
    fields_desc = [
        IntField("netmask", 0),
        ShortField("hellointerval", 10),
        ByteField("options", 2),
        ByteField("priority", 1),
        IntField("deadinterval", 40),
        IntField("designatedrouter", 0),
        IntField("backupdesignatedrouter", 0),
        IntField("neighbor", 0)
    ]

# Bind OSPF Hello to OSPF Header
bind_layers(OSPF_Hdr, OSPF_Hello, type=1)

# Create Ethernet Layer
eth = Ether(src="88:04:00:00:00:00", dst="12:aa:bb:00:00:01")

# Create IP Layer
ip = IP(src="10.0.0.10", dst="10.0.0.1", proto=89)

# Create OSPF Header Layer
ospf_hdr = OSPF_Hdr(routerid=0x0A00000A, areaid=0)

# Create OSPF Hello Layer
ospf_hello = OSPF_Hello(netmask=0xFFFFFF00)

# Construct the full packet
packet = eth / ip / ospf_hdr / ospf_hello

# Send the packet
sendp(packet, iface="eth0")