from ospf import OSPF_Hdr, OSPF_Hello

import threading
import time
import p4runtime_sh.shell as sh
from scapy.all import Ether, IP, Packet, ByteField, ShortField, IntField, XShortField, StrFixedLenField
from scapy.packet import bind_layers

import os
os.environ['DISPLAY'] = ''

HELLO_INT = 10

# Thread of this class sends OSPF Hello message every HELLO_INT seconds
class HelloSenderThread(threading.Thread):
    def run(self):
        print("HelloSenderThread: started...")
        while True:
            self.send_hello()
            time.sleep(HELLO_INT)

    # Creates hello packet    
    def create_packet(self):
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
        return packet

    def send_hello(self):
        p = sh.PacketOut(payload=bytes(self.create_packet()), egress_port='2')
        p.send()
        print("HelloSenderThread: Message sent")