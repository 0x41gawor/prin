import threading
from scapy.all import Ether
from scapy.layers.inet import IP
from scapy.packet import bind_layers
from scapy.utils import PcapWriter

from ospf import OSPF_Hdr

import os
os.environ['DISPLAY'] = ''

class HandlerThread(threading.Thread):
    def __init__(self, packet_data):
        super().__init__()
        self.packet_data = packet_data

    def run(self):
        self.handle_packet(self.packet_data)

    def handle_packet(self, packet_data):
        #print("HandlerThread: Processing packet: ", packet_data)

        #writer = PcapWriter('captured_packet.pcap')
        #writer.write(packet_data)
        # Bind OSPF Hello to OSPF Header
        bind_layers(IP, OSPF_Hdr, proto=89)

        # Convert the raw bytes to a Scapy packet
        pkt = Ether(packet_data)
        
        # Check if the packet contains an IP layer
        if IP in pkt:
            ip_layer = pkt[IP]
            # Check if the IP layer contains an OSPF layer
            if ip_layer.proto == 89:  # 89 is the protocol number for OSPF
                ospf_packet = pkt[OSPF_Hdr]
                # Now you can access OSPF packet fields
                print(f"{ospf_packet.show()}")