import p4runtime_sh.shell as sh

sh.setup(
    device_id=0,
    grpc_addr='localhost:9559',
    election_id=(0, 1),
    config=sh.FwdPipeConfig('p4info.txt', 'out/runtime.json')
)

########################################
######## mac_rewriting_table ###########
########################################

mt = sh.TableEntry('mac_rewriting_table')(action='set_smac')
mt.match['egress_port'] = '1'
mt.action['mac'] = '12:aa:bb:00:00:00'
mt.insert()

mt.match['egress_port'] = '2'
mt.action['mac'] = '12:aa:bb:00:00:01'
mt.insert()     

########################################
############ digest init ###############
########################################

d = sh.DigestEntry('learn_t')
d.ack_timeout_ns = 1000000000
d.max_timeout_ns = 1000000000
d.max_list_size = 100
d.insert()

while True:
    for e in sh.DigestList().sniff(timeout=30):
        try:
            srcMac = e.digest.data[0].struct.members[0].bitstring
            in_port = e.digest.data[0].struct.members[1].bitstring
            srcIP = e.digest.data[0].struct.members[2].bitstring

            srcMac = ':'.join(format(byte, '02x') for byte in srcMac)
            in_port = str(int.from_bytes(in_port, byteorder='big'))
            srcIP = '.'.join(str(byte) for byte in srcIP)

            print("------------------")
            print(srcMac)
            print(in_port)     
            print(srcIP)  
            print("------------------")

            ####################################
            ######### routing_table ############
            ####################################

            rt = sh.TableEntry('routing_table')(action='ipv4_forward')
            rt.match['dstAddr'] = srcIP + "/32"
            rt.action['nextHop'] = srcIP
            rt.insert()

            #####################################
            ########## switching_table ##########
            #####################################

            st = sh.TableEntry('switching_table')(action='set_dmac') 
            st.match['nhop_ipv4'] = srcIP     
            st.action['dstAddr'] = srcMac
            st.action['port'] = in_port

            st.insert()

        except Exception as inner_e:
            print("Exception: ", inner_e)

sh.teardown()