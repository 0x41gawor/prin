from hello_sender import HelloSenderThread
from sniffer import SnifferThread

import p4runtime_sh.shell as sh
from p4runtime_sh.shell import FwdPipeConfig

from scapy.all import *
from scapy.layers.inet import IP
from scapy.contrib.ospf import OSPF_Hdr, OSPF_Hello

# Initialize the P4Runtime shell
sh.setup(
    device_id=0,
    grpc_addr='localhost:9559',
    election_id=(0, 1),
    config=FwdPipeConfig('p4info.txt','out/struthio.json')
)

if __name__ == "__main__":

    sniffer_thread = SnifferThread()
    sniffer_thread.start()

    hello_sender_thread = HelloSenderThread()
    hello_sender_thread.start()

    sniffer_thread.join()
    hello_sender_thread.join()

    sh.teardown()