import p4runtime_sh.shell as sh

sh.setup(
    device_id=0,
    grpc_addr='localhost:9559',
    election_id=(0, 1), # (high, low)
    config=sh.FwdPipeConfig('p4info.txt', 'out/template.json')
)

te = sh.TableEntry('MyIngress.arp_lookup')(action='send_arp_reply')
#te.match['meta.ingress_port'] = '1'
te.match['hdr.arp.tpa'] = '10.0.0.3'
te.action['target_mac'] = '00:00:00:04:00:AA'
te.insert()

te = sh.TableEntry('MyIngress.arp_lookup')(action='send_arp_reply')
#te.match['meta.ingress_port'] = '2'
te.match['hdr.arp.tpa'] = '10.0.0.4'
te.action['target_mac'] = '00:00:00:04:00:BB'
te.insert()

sh.teardown()