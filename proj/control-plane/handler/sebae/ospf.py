from scapy.all import Ether, IP, Packet, ByteField, ShortField, IntField, XShortField, StrFixedLenField, FieldListField, IPField
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
        IPField("router_id", 0),
        IPField("area_id", 0),
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
        IPField("network_mask", 0),
        ShortField("helloInt", 30),
        ByteField("options", 0),                 # Not in use
        ByteField("rtr_pri", 0),                 # Not in use
        IntField("deadInt", 0),                  # Not in use
        IntField("designated_router", 0),        # Not in use
        IntField("backup_designated_router", 0), # Not in use
        IntField("neighbor", 0)                  # Not in use
    ]

# define OSFP LSA adertisment
class OSPF_LSA(Packet):
    name = "OSPF Link State Advertisement"
    fields_desc = [
        IPField("subnet", "0.0.0.0"),
        IPField("mask", "255.255.255.0"),
        IPField("routerid", "0.0.0.0")
    ]

# define OSFP LSU Packet
class OSPF_LSU(Packet):
    name = "OSPF Link State Update"
    fields_desc = [
        IntField("seq", 0),
        ByteField("ttl", 1),
        ByteField("num_adv", 1),
        FieldListField("lsa", [], OSPF_LSA, count_from=lambda pkt: pkt.num_adv)
        #FieldListField("lsa", [OSPF_LSA()], OSPF_LSA, count_from=lambda pkt: pkt.num_adv)
    ]