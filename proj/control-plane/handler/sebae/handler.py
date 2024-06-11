import threading
from scapy.all import Ether, IPField
from scapy.layers.inet import IP
from scapy.packet import bind_layers
from scapy.utils import PcapWriter

from ospf import OSPF_Hdr, OSPF_Hello, OSPF_LSU

import os
os.environ['DISPLAY'] = ''


neighbors = []

class Neighbor:
    def __init__(self, router_id: str, is_active: bool):
        self.router_id = IPField("router_id", router_id)
        self.is_active = is_active

    def __repr__(self):
        return f"Neighbor(router_id={self.router_id.default}, is_active={self.is_active})"
    

def validate_ospf_header(ospf_hdr):
    # Validate OSPF version
        if ospf_hdr.version != 2:
            print("HandlerThread: Invalid OSPF version.")
            return False
        
        # Validate Area ID
        if ospf_hdr.area_id != "0.0.0.0":
            print("HandlerThread: Invalid Area ID.")
            return False
        
        # Validate Authentication Type
        if ospf_hdr.autype != 0:
            print("HandlerThread: Invalid Authentication Type.")
            return False

        print("HandlerThread: OSPF packet is valid.")
        return True

def handle_hello_packet(hello_pkt):
    new_neighbor = Neighbor("192.168.1.4", True)
    if new_neighbor not in neighbors:
        neighbors.append(new_neighbor)
    return None

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
                validate_ospf_header(ospf_packet)
                # Determine OSPF packet type
                if ospf_packet.type == 1:
                    hello_pkt = ospf_packet[OSPF_Hello]
                    handle_hello_packet(hello_pkt)
                elif ospf_packet.type == 4:
                    lsu_pkt = ospf_packet[OSPF_LSU]
                else:
                    print("HandlerThread: Unsupported OSPF packet type.")
                    return False