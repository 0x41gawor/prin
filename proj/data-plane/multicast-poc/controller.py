import p4runtime_sh.shell as sh
import signal
import sys

port_config = {
    1: {"nr": "1", "mac": "00:00:00:04:00:AA", "ip_addr": "10.0.0.3"},
    2: {"nr": "2", "mac": "00:00:00:04:00:BB", "ip_addr": "10.0.0.4"},
}

known_hosts = []

def init_p4runtime():
    sh.setup(
        device_id=0,
        grpc_addr='localhost:9559',
        election_id=(0, 1),
        config=sh.FwdPipeConfig('p4info.txt', 'out/struthio.json')
    )

# Adds proper arp table entries based on port config
def insert_arp_config():
    for port in port_config.values():
        te = sh.TableEntry('MyIngress.tbl_arp_lookup')(action="send_arp_reply")
        te.match['standard_metadata.ingress_port'] = port["nr"]
        te.match['hdr.arp.tpa'] = port["ip_addr"]
        te.action['target_mac'] = port["mac"]
        te.insert()

# Util func, initializes digest
def init_digest():
    d = sh.DigestEntry('learn_t')
    d.ack_timeout_ns = 1000000000 # 1000ms, 1s
    d.max_timeout_ns = 1000000000 # 1000ms, 1s
    d.max_list_size = 100
    d.insert()

# Inserts entry to tbl_mac_learn
def tbl_mac_learn(mac):
    te = sh.TableEntry('MyIngress.tbl_mac_learn')(action='NoAction')
    te.match['hdr.ethernet.srcAddr'] = mac
    te.insert()
    known_hosts.append(mac)
# Inserts entry to tbl_ip_routing
def tbl_ip_routing(dst, next_hop):
    te = sh.TableEntry('MyIngress.tbl_ip_routing')(action='route')
    te.match['hdr.ip.dstAddr'] = dst
    te.action['next_hop'] = next_hop
    te.insert()
# Inserts entry to tbl_ip_forwarding
def tbl_ip_forwarding(next_hop, egress_port):
    te = sh.TableEntry('MyIngress.tbl_ip_forwarding')(action='forward')
    te.match['meta.next_hop'] = next_hop
    te.action['egress_port'] = str(egress_port)
    te.insert()
# Inserts entry to tbl_mac_update
def tbl_mac_update(egress_port, src, dst):
    te = sh.TableEntry('MyEgress.tbl_mac_update')(action='update_mac_addresses')
    te.match['standard_metadata.egress_spec'] = str(egress_port)
    te.action['src'] = src
    te.action['dst'] = dst
    te.insert()

# Processes digest entries that come from data plane
# This func collects entries for 10s and the iterates over them
# For each entry it outputs its content and then make proper table entries if host is not known
def process_digest_entries():
    for e in sh.DigestList().sniff(timeout=10):
        port_bytes = e.digest.data[0].struct.members[0].bitstring
        mac_bytes = e.digest.data[0].struct.members[1].bitstring
        ip_addr_bytes = e.digest.data[0].struct.members[2].bitstring

        port = int.from_bytes(port_bytes, byteorder='big') & 0x1FF
        mac = ':'.join(format(byte, '02x').zfill(2) for byte in mac_bytes)
        ip_addr = '.'.join(str(byte) for byte in ip_addr_bytes)

        print("---------------- Digest entry ------------------")
        print("port:", str(port), "                       raw: ", port_bytes)
        print("mac:", mac, "        raw: ", mac_bytes)
        print("ip_addr:", ip_addr, "             raw: ", ip_addr_bytes)

        if mac not in known_hosts:
            # Insert tbl_mac_learn entry
            tbl_mac_learn(mac=mac)
            # Insert tbl_ip_routing entry
            tbl_ip_routing(dst=ip_addr,next_hop= ip_addr)
            # Insert tbl_ip_forwarding entry
            tbl_ip_forwarding(next_hop=ip_addr, egress_port=port)
            # Insert tbl_mac_update entry
            tbl_mac_update(egress_port=port, src=port_config[port]["mac"], dst=mac)

# Hndling the ctrl+c signal. Makes sure runtimeshell session is tear down
def signal_handler(sig, frame):
    print("Interrupt received, shutting down...")
    sh.teardown()
    sys.exit(0)

if __name__ == "__main__":
    signal.signal(signal.SIGINT, signal_handler)

    init_p4runtime()
    insert_arp_config()
    init_digest()

    print("Starting digest processing. Press Ctrl+C to stop.")
    try:
        while True:
            process_digest_entries()
    finally:
        sh.teardown()