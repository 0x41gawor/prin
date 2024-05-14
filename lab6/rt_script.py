import p4runtime_sh.shell as sh
import chardet


sh.setup(
    device_id=0,
    grpc_addr='localhost:9559',
    election_id=(0, 1), # (high, low)
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
######## digest ###########
########################################

d = sh.DigestEntry('learn_t')
d.ack_timeout_ns = 1000000000
d.max_timeout_ns = 1000000000
d.max_list_size = 100
d.insert()

while True:
    for e in sh.DigestList().sniff(timeout=20):

        print(f"TYPEk: {e.digest.data[0]}") 
        # print(f"TYPEk: {type(e.digest.data[0].struct.members[3].bitstring.decode('ascii'))}")
        # bytes_variable = e.digest.data[0].struct.members[3].bitstring

        print("\n0o0o0o0o0o0o0o0o00o0o0o0o0o0o")
        print(repr(e.digest.data[0].struct.members[0].bitstring))
        print(type(repr(e.digest.data[0].struct.members[0].bitstring)))
        print(repr(e.digest.data[0].struct.members[1].bitstring))
        print(repr(e.digest.data[0].struct.members[2].bitstring))
        print(repr(e.digest.data[0].struct.members[3].bitstring))
        print("0o0o0o0o0o0o0o0o00o0o0o0o0o0o\n")

        srcMac = e.digest.data[0].struct.members[0].bitstring
        prt = e.digest.data[0].struct.members[1].bitstring
        dstMac = e.digest.data[0].struct.members[2].bitstring
        dstIP = e.digest.data[0].struct.members[3].bitstring

        srcMac = ':'.join(format(byte, '02x') for byte in srcMac)
        dstMac = ':'.join(format(byte, '02x') for byte in dstMac)
        dstIP = '.'.join(str(byte) for byte in dstIP)
        prt = str(int.from_bytes(prt, byteorder='big'))

        print("------------------")
        print(srcMac) # string  ADRES MAC HOSTA wysylajacego
        print(dstMac) # string  ADRES SW od STRONY HOSTA wysylajacego      
        print(dstIP) # string   DOCELOWE IP
        print(prt) # string     INGRESS PORT
        print("------------------")

        ####################################
        ######### routing_table ############
        ####################################

        rt = sh.TableEntry('routing_table')(action='ipv4_forward')
        rt.match['dstAddr'] = dstIP + "/32"
        rt.action['nextHop'] = dstIP 
        if prt == "1":
            rt.action['port'] = "2"  # tu chodzi o egress port
        elif prt == "2":
            rt.action['port'] = "1"
        rt.insert()
        print("routing")


        # rt.match['dstAddr'] = '10.0.1.0/24'
        # rt.action['nextHop'] = '10.0.1.10' 
        # rt.action['port'] = '2'
        # rt.insert()

        #########################################
        ########## switching_table ##############
        #########################################

        st = sh.TableEntry('switching_table')(action='set_dmac') 
        st.match['nhop_ipv4'] = dstIP
        if prt == "1":         
            st.action['dstAddr'] = '88:04:00:00:00:01' # wysylam na 1, bo to drugi host
        elif prt == "2":
            st.action['dstAddr'] = '88:04:00:00:00:00' # wysylam na 0
        st.insert()
        print("mac")

        # st.match['nhop_ipv4'] = '10.0.1.10' 
        # st.action['dstAddr'] = '00:04:00:00:00:01'
        # st.insert()


sh.teardown() 

# dl = sh.DigestList()

# while True:
#     for e in dl.sniff(timeout=1):
#         print(e.data())
      

# for e in sh.DigestList.sniff(d):
# 	print(e)

# dl = sh.DigestList.digest_list_queue.get()
# print(dl)




# TODO:
# sprawdzic wpisy w tym skrypcie
# podejrzenie ze /24 to problem


# rutowac po porcie?
# maska /24 czy /32 o co z tym chodzi