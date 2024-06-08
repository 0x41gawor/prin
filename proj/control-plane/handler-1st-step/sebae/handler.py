import threading
from scapy.all import Ether
from scapy.layers.inet import IP

from ospf import OSPF_Hdr, OSPF_Hello


class HandlerThread(threading.Thread):
    def __init__(self, packet):
        super().__init__()
        self.packet = packet.payload
        print(f"HandlerThread: Initialized with packet: {self.packet}")

    def run(self):
        print("HandlerThread: Starting to process packet")
        self.process_packet()

    def process_packet(self):
        print(f"HandlerThread: Processing packet: {self.packet}")
        # Convert the packet to a Scapy Ether object
        try:
            scapy_packet = Ether(self.packet)
            print("HandlerThread: Scapy Packet:")
            print(scapy_packet.show())

            if scapy_packet.haslayer(IP):
                ip_packet = scapy_packet[IP]
                print("HandlerThread: IP Packet Details:")
                ip_packet.show()
            else:
                print("HandlerThread: Not an IP packet")
            
            # Check if the packet has an OSPF_Hdr layer
            if scapy_packet.haslayer(OSPF_Hdr):
                ospf_packet = scapy_packet[OSPF_Hdr]
                print("HandlerThread: OSPF Packet Details:")
                print(ospf_packet.show())
            else:
                print("HandlerThread: Not an OSPF packet")
        except Exception as e:
            print(f"HandlerThread: Error parsing packet: {e}")
