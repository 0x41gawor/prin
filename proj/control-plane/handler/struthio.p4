/* -*- P4_16 -*- */

#include <core.p4>
#include <v1model.p4>

/*************************************************************************
**************   H E A D E R S   A N D   S T R U C T S   ****************
*************************************************************************/

#define CPU_PORT 510
#define OSPF_NUM 89


@controller_header("packet_out")
header packet_out_header_t {
    bit<16> egress_port;
}

@controller_header("packet_in")
header packet_in_header_t {
    bit<16> ingress_port;
}

struct learn_t {
    bit<9> port;
    bit<48> mac;
    bit<32> ip_addr;
}

header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> etherType;
}

header arp_t {
    bit<16> htype;
    bit<16> ptype;
    bit<8> hlen;
    bit<8> plen;
    bit<16> oper;
    bit<48> sha;  // Sender hardware address
    bit<32> spa;  // Sender protocol address
    bit<48> tha;  // Target hardware address
    bit<32> tpa;  // Target protocol address
}

header ip_t {
	bit<4>    version;
	bit<4>    ihl;
	bit<8>    diffserv;
	bit<16>   totalLen;
	bit<16>   identification;
	bit<3>    flags;
	bit<13>   fragOffset;
	bit<8>    ttl;
	bit<8>    protocol;
	bit<16>   hdrChecksum;
	bit<32>   srcAddr;
	bit<32>   dstAddr;
}

struct headers_t {
    ethernet_t ethernet;
    arp_t arp;
    ip_t ip;
    packet_in_header_t packet_in;
    packet_out_header_t packet_out;
}

struct metadata_t {
    bit<9> ingress_port;
    bit<32> next_hop;
    learn_t learn;
}

/*************************************************************************
*********************** P A R S E R  ***********************************
*************************************************************************/

parser MyParser(packet_in packet,
                out headers_t hdr,
                inout metadata_t meta,
                inout standard_metadata_t standard_metadata)
{
    state start {
        transition select(standard_metadata.ingress_port) {
            CPU_PORT: parse_packet_out;
            default: parse_ethernet;
        }
    }

    state parse_packet_out {
        packet.extract(hdr.packet_out);
        transition parse_ethernet;
    }

    state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            0x0800: parse_ip;
            0x0806: parse_arp;
            default: accept;
        }
    }

    state parse_arp {
        packet.extract(hdr.arp);
        transition accept;
    }

    state parse_ip {
        packet.extract(hdr.ip);
        transition accept;
    }
}

/*************************************************************************
************   C H E C K S U M    V E R I F I C A T I O N   *************
*************************************************************************/

control MyVerifyChecksum(inout headers_t hdr, inout metadata_t meta)
{   
    apply {
        
    }
}

/*************************************************************************
**************  I N G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyIngress(inout headers_t hdr,
                  inout metadata_t meta,
                  inout standard_metadata_t standard_metadata) 
{

    action learn_host() {
        meta.learn.port = standard_metadata.ingress_port;
        meta.learn.mac = hdr.ethernet.srcAddr;
        meta.learn.ip_addr = hdr.ip.srcAddr;
        digest<learn_t>(1, meta.learn);
    }

    action send_arp_reply(bit<48> target_mac) {
        // Swap Ethernet addresses
        bit<48> temp_mac = hdr.ethernet.dstAddr;
        hdr.ethernet.dstAddr = hdr.ethernet.srcAddr;
        hdr.ethernet.srcAddr = target_mac;

        // Set ARP reply fields
        hdr.arp.oper = 0x0002;  // ARP Reply
        hdr.arp.tha = hdr.arp.sha;  // Target hardware address = Sender hardware address
        hdr.arp.sha = target_mac;  // Sender hardware address = MAC address from table
        // Swap IP address
        bit<32> temp_ip = hdr.arp.spa;
        hdr.arp.spa = hdr.arp.tpa;  // Sender protocol address = Target protocol address
        hdr.arp.tpa = temp_ip;  // Target protocol address = Sender protocol address

        // Send ARP reply via the ingress port
        standard_metadata.egress_spec = standard_metadata.ingress_port;
    }

    action assign_mcast_group(bit<16> grp_num) {
        standard_metadata.mcast_grp=grp_num;
        exit;
    }

    action route(bit<32> next_hop) {
        meta.next_hop = next_hop;
    }

    action forward(bit<9> egress_port) {
        standard_metadata.egress_spec = egress_port;
    }

    action send_Packet_In_to_controller() {
        standard_metadata.egress_spec = CPU_PORT;
        hdr.packet_in.setValid();
        hdr.packet_in.ingress_port = (bit<16>)standard_metadata.ingress_port;
    }
    // ------------------------------------------------------- T A B L E S 
    table tbl_mac_learn {
        key = {
            hdr.ethernet.srcAddr: exact;
        }

        actions = {
            learn_host;
            NoAction;
        }
        default_action = learn_host;
    }

    table tbl_arp_lookup {
        key = {
            hdr.arp.tpa: exact;
            standard_metadata.ingress_port: exact;
        }
        actions = {
            send_arp_reply;
            NoAction;
        }
        default_action = NoAction;
    }

    table tbl_mcast_group {
        key = {
            hdr.ip.dstAddr: lpm;
        }
        actions = {
            assign_mcast_group;
            NoAction;
        }
        default_action = NoAction;
    }

    table tbl_ip_routing {
        key = {
            hdr.ip.dstAddr: lpm;
        }
        actions = {
            route;
            NoAction;
        }
        default_action = NoAction();
    }

    table tbl_ip_forwarding {
        key = {
            meta.next_hop: exact;
        }
        actions = {
            forward;
            NoAction;
        }
        default_action = NoAction();
    }

    apply {
        // Check if it is PacketOut P4Runtime message from controller
        if (hdr.packet_out.isValid()) {
            // we support only the case when egress port is specified by controller
            // we simply set the egress port to the one specified by controller and then processing of this packet goes to MyEgress
            standard_metadata.egress_spec = (bit<9>) hdr.packet_out.egress_port;
        } 
        // the other case is that it is simply the Ethertnet Packet
        else {
            // Do we know this host? If not, learn it (send info to control plane)
            tbl_mac_learn.apply();
            // Is this ARP packet? 
            if (hdr.ethernet.etherType == 0x0806 && hdr.arp.oper == 0x0001) {  
                // If is is, check if it concerns us, and eventually send ARP Reply
                tbl_arp_lookup.apply();
            }
            // Is this IP packet?
            if (hdr.ethernet.etherType == 0x0800) {
                // Check if ttl is less than 2
                if (hdr.ip.ttl < 2) {
                    NoAction();
                }
                else {
                    // Check if this packet belongs to some multicast group 
                    // (if it does, copy and forward it to specific ports and go directly to egress block)
                    tbl_mcast_group.apply();
                    // Check if this packet is an OSPF packet
                    if (hdr.ip.protocol == OSPF_NUM) {
                        // If it does, send it in Packet_In message to controller
                        send_Packet_In_to_controller();
                    }
                    // Check the next hop ip address for this packet (based on its ip.dst_addr)
                    tbl_ip_routing.apply();
                    // Set egress_port for this packet (based on next hop from previous step)
                    tbl_ip_forwarding.apply();
                }
            }
        }
    }
}

/*************************************************************************
****************  E G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyEgress(inout headers_t hdr,
                 inout metadata_t meta,
                 inout standard_metadata_t standard_metadata)
{

    action update_mac_addresses(bit<48> src, bit<48> dst) {
        hdr.ethernet.srcAddr = src;
        hdr.ethernet.dstAddr = dst;
    }

    table tbl_mac_update {
        key = {
            standard_metadata.egress_spec: exact;
        }
        actions = {
            update_mac_addresses;
            NoAction;
        }
        default_action = NoAction;
    }

    apply {
        // Is this IP packet?
        if (hdr.ethernet.etherType == 0x0800) {
            // If it is make proper changes in L2 addresses
            tbl_mac_update.apply();
        }
    }
}

/*************************************************************************
*************   C H E C K S U M    C O M P U T A T I O N   **************
*************************************************************************/

control MyComputeChecksum(inout headers_t hdr, inout metadata_t meta)
{
    apply {
        update_checksum(
            hdr.ip.isValid(),
            { hdr.ip.version, hdr.ip.ihl, hdr.ip.diffserv, hdr.ip.totalLen,
              hdr.ip.identification, hdr.ip.flags, hdr.ip.fragOffset, hdr.ip.ttl,
              hdr.ip.protocol, hdr.ip.srcAddr, hdr.ip.dstAddr },
            hdr.ip.hdrChecksum,
            HashAlgorithm.csum16
        );
    }
}

/*************************************************************************
***********************  D E P A R S E R  *******************************
*************************************************************************/

control MyDeparser(packet_out packet, in headers_t hdr)
{
    apply {
        packet.emit(hdr.packet_in);
        packet.emit(hdr.ethernet);
        packet.emit(hdr.arp);
        packet.emit(hdr.ip);
    }
}

/*************************************************************************
************************  S W I T C H  **********************************
*************************************************************************/

V1Switch(
    MyParser(),
    MyVerifyChecksum(),
    MyIngress(),
    MyEgress(),
    MyComputeChecksum(),
    MyDeparser()
) main;