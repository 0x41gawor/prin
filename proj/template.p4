/* -*- P4_16 -*- */

#include <core.p4>
#include <v1model.p4>

/*************************************************************************
**************   H E A D E R S   A N D   S T R U C T S   ****************
*************************************************************************/

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

struct headers_t
{
	ethernet_t ethernet;
    arp_t arp;
}

struct metadata_t {
    bit<9> ingress_port;
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
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            0x0806: parse_arp;
            default: accept;
        }
    }

    state parse_arp {
        packet.extract(hdr.arp);
        transition accept;
    }
}


/*************************************************************************
************   C H E C K S U M    V E R I F I C A T I O N   *************
*************************************************************************/

control MyVerifyChecksum(inout headers_t hdr, inout metadata_t meta)
{   
	apply
	{
	}
}


/*************************************************************************
**************  I N G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyIngress(inout headers_t hdr,
                  inout metadata_t meta,
                  inout standard_metadata_t standard_metadata) 
{
    action send_arp_reply(bit<48> target_mac) {
        // Swap Ethernet addresses
        bit<48> temp_mac = hdr.ethernet.dstAddr;
        hdr.ethernet.dstAddr = hdr.ethernet.srcAddr;
        hdr.ethernet.srcAddr = target_mac;

        // Set ARP reply fields
        hdr.arp.oper = 0x0002;  // ARP Reply
        hdr.arp.tha = hdr.arp.sha;  // Target hardware address = Sender hardware address
        hdr.arp.sha = target_mac;  // Sender hardware address = MAC address from table
        hdr.arp.tpa = hdr.arp.spa;  // Target protocol address = Sender protocol address
        hdr.arp.spa = hdr.arp.tpa;  // Sender protocol address = Target protocol address

        // Send ARP reply via the ingress port
        standard_metadata.egress_spec = standard_metadata.ingress_port;
    }

   action drop() {
		// Drop the packet
		mark_to_drop(standard_metadata);
	}

    table arp_lookup {
        key = {
            hdr.arp.tpa: exact;
        }
        actions = {
            send_arp_reply;
            drop;
        }
        size = 1024;
    }

    apply {
        if (hdr.ethernet.etherType == 0x0806 && hdr.arp.oper == 0x0001) {  // ARP Request
            arp_lookup.apply();
        } else {
            drop();
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
	apply
	{
	}
}

/*************************************************************************
*************   C H E C K S U M    C O M P U T A T I O N   **************
*************************************************************************/

control MyComputeChecksum(inout headers_t hdr, inout metadata_t meta)
{
	apply
	{
	}
}


/*************************************************************************
***********************  D E P A R S E R  *******************************
*************************************************************************/

control MyDeparser(packet_out packet, in headers_t hdr)
{
	apply {
        packet.emit(hdr.ethernet);
        packet.emit(hdr.arp);
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