/* -*- P4_16 -*- */

#include <core.p4>
#include <v1model.p4>

const bit<16> TYPE_IPV4 = 0x0800;
#define CPU_PORT 510
#define OSPF_NUM 89

/*************************************************************************
**************   H E A D E R S   A N D   S T R U C T S   ****************
*************************************************************************/

typedef bit<9>	egressSpec_t;
typedef bit<48>	macAddr_t;
typedef bit<32> ip4Addr_t;

header ethernet_t {
	macAddr_t dstAddr;
	macAddr_t srcAddr;
	bit<16>   etherType;
}

header ipv4_t {
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
	ip4Addr_t srcAddr;
	ip4Addr_t dstAddr;
}

// header ospf_t {
//     bit<8> version;
//     bit<8> type;
//     bit<16> pkt_len;
//     bit<32> router_id;
//     bit<32> area_id;
//     bit<16> checksum;
//     bit<16> au_type;
//     bit<64> authentication;
// }

@controller_header("packet_out")
header packet_out_header_t {
    bit<16> egress_port;
}

@controller_header("packet_in")
header packet_in_header_t {
    bit<16> ingress_port;
}

struct learn_t {
    bit<48> srcMAC;
    bit<9>  ingress_port;
    bit<32> srcIP;
}

struct headers {
	ethernet_t			ethernet;
	ipv4_t				ipv4;
	// ospf_t				ospf;
	packet_out_header_t packet_out_header;
	packet_in_header_t	packet_in_header;
}

struct routing_metadata_t {
	ip4Addr_t nhop_ipv4;
}

struct metadata {
	routing_metadata_t routing;
	learn_t learn;
}

/*************************************************************************
*********************** P A R S E R  ***********************************
*************************************************************************/

parser RouterParser(packet_in packet,
					out headers hdr,
					inout metadata meta,
					inout standard_metadata_t standard_metadata) {

    state start {
        transition select(standard_metadata.ingress_port) {
            CPU_PORT: parse_packet_out_header;
            default: parse_ethernet;
        }
    }

	state parse_packet_out_header {
		packet.extract(hdr.packet_out_header);
		transition parse_ethernet;
	}

	state parse_ethernet {
		packet.extract(hdr.ethernet);
		transition select(hdr.ethernet.etherType) {
			TYPE_IPV4: parse_ipv4;
			// arp
			default: accept;
		}
	}
	
	state parse_ipv4 {
		packet.extract(hdr.ipv4);
		transition accept;
	}
}

/*************************************************************************
************   C H E C K S U M    V E R I F I C A T I O N   *************
*************************************************************************/

control MyVerifyChecksum(inout headers hdr, inout metadata meta)
{   
	apply{
		verify_checksum(
			hdr.ipv4.isValid(),
			{ 	
				hdr.ipv4.version,
				hdr.ipv4.ihl,
				hdr.ipv4.diffserv,
				hdr.ipv4.totalLen,
				hdr.ipv4.identification,
				hdr.ipv4.flags,
				hdr.ipv4.fragOffset,
				hdr.ipv4.ttl,
				hdr.ipv4.protocol,
				hdr.ipv4.srcAddr,
				hdr.ipv4.dstAddr
			},
			hdr.ipv4.hdrChecksum, 
			HashAlgorithm.csum16);		
  }
}

/*************************************************************************
**************  I N G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control ingress(inout headers hdr,
				inout metadata meta,
				inout standard_metadata_t standard_metadata) {
	
	counter(64, CounterType.packets) counter_rec;
	counter(64, CounterType.packets) counter_dropped;
	counter(64, CounterType.packets) counter_send;
	
	action drop() {
		counter_dropped.count((bit<32>) 0); 
		mark_to_drop(standard_metadata);
	}
	
	action ipv4_forward(ip4Addr_t nextHop) {
		counter_rec.count((bit<32>) standard_metadata.ingress_port);  
		meta.routing.nhop_ipv4 = nextHop;
		hdr.ipv4.ttl = hdr.ipv4.ttl - 1;    
	}

	action set_dmac(macAddr_t dstAddr, egressSpec_t port) {
		counter_send.count((bit<32>) standard_metadata.egress_port);
		standard_metadata.egress_spec = port;
		hdr.ethernet.dstAddr = dstAddr;
	}

	action mac_learn(){
        meta.learn.srcMAC = hdr.ethernet.srcAddr;
        meta.learn.ingress_port = standard_metadata.ingress_port;
		meta.learn.srcIP = hdr.ipv4.srcAddr;
        digest<learn_t>(1, meta.learn);
    }

	action send_to_controller(){
		standard_metadata.egress_spec = CPU_PORT;
		hdr.packet_in_header.ingress_port = (bit<16>) standard_metadata.ingress_port;
		hdr.packet_in_header.setValid();
	}

/**************************************************/
	// table controller_port {
    //     key = {
    //         hdr.ipv4.protocol: exact;
    //     }

    //     actions = {
    //         send_to_controller;
    //         NoAction;
    //     }
    //     size = 256;
    //     default_action = NoAction;
    // }
/*************************************************/	
	table smac {
        key = {
            hdr.ethernet.srcAddr: exact;
        }

        actions = {
            mac_learn;
            NoAction;
        }
        size = 256;
        default_action = mac_learn;
    }
/**************************************************/
	table routing_table {
		key = {
			hdr.ipv4.dstAddr: lpm;
		}
		actions = {
			ipv4_forward;
			drop;
			NoAction;
		}
		default_action = NoAction();
	}
/**************************************************/
	table switching_table {
		key = {
			meta.routing.nhop_ipv4 : exact;
		}
		actions = {
			set_dmac;
			drop;
			NoAction;
		}
		default_action = NoAction();
	}
/**************************************************/
// 	apply {
// 		if (standard_metadata.ingress_port == CPU_PORT){ // jesli przyjdzie pakiet od sterownika
// 			if (standard_metadata.egress_port != CPU_PORT) { // jesli sterownik ustawi port wyjsciowy
// 				standard_metadata.egress_spec = standard_metadata.egress_port
// 			}
// 			else { // jesli sterownik nie ustawil portu wyjsciowego, to pakiet podlega domyslnemu routingowi
// 				if (hdr.ipv4.ttl <= 2) {
// 					drop();
// 				}
// 				if (hdr.ipv4.protocol == OSPF_NUM) {
// 					send_to_controller();
// 				}			
// 				smac.apply();	
// 				routing_table.apply();
// 				switching_table.apply();
// 			}
// 		}
// 		else {
// 			if (hdr.ipv4.ttl <= 2) {
// 				drop();
// 			}
// 			if (hdr.ipv4.protocol == OSPF_NUM) {
// 				send_to_controller();
// 			}			
// 			smac.apply();	
// 			routing_table.apply();
// 			switching_table.apply();
// 		}		   	
// 	}
//  standard_metadata.ingress_port == CPU_PORT && standard_metadata.egress_port != CPU_PORT {
				//standard_metadata.egress_spec = standard_metadata.egress_port;}

		apply {
			if (hdr.packet_out_header.isValid()){ 
				// gdy switch ustawia egress_port
				standard_metadata.egress_spec = (bit<9>) hdr.packet_out_header.egress_port;
				// standard_metadata.egress_port = 0;
			} 
			else {
				if (hdr.ipv4.ttl <= 2) {
					drop();
				} else if (hdr.ipv4.protocol == OSPF_NUM) {
					send_to_controller();
				} else {
					smac.apply();    
					routing_table.apply();
					switching_table.apply();
				}
			}
		}
}
/*************************************************************************
****************  E G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control egress(inout headers hdr,
			   inout metadata meta,
			   inout standard_metadata_t standard_metadata) {
		
	action set_smac(macAddr_t mac) {
		hdr.ethernet.srcAddr = mac;
	}

	action drop() {
		mark_to_drop(standard_metadata);
	}

	table mac_rewriting_table {

		key = {
			standard_metadata.egress_port: exact;
		}

		actions = {
			set_smac;
			drop;
			NoAction;
		}

		default_action = NoAction();
	}

	apply {
		mac_rewriting_table.apply();
	}

}

/*************************************************************************
*************   C H E C K S U M    C O M P U T A T I O N   **************
*************************************************************************/

control MyComputeChecksum(inout headers hdr, inout metadata meta) {
	 apply {
		update_checksum(
			hdr.ipv4.isValid(),
				{ 	
					hdr.ipv4.version,
					hdr.ipv4.ihl,
					hdr.ipv4.diffserv,
					hdr.ipv4.totalLen,
					hdr.ipv4.identification,
					hdr.ipv4.flags,
					hdr.ipv4.fragOffset,
					hdr.ipv4.ttl,
					hdr.ipv4.protocol,
					hdr.ipv4.srcAddr,
					hdr.ipv4.dstAddr 
				},
				hdr.ipv4.hdrChecksum,
				HashAlgorithm.csum16);
	}
}

/*************************************************************************
***********************  D E P A R S E R  *******************************
*************************************************************************/

control deparser(packet_out packet,
				 in headers hdr) {
	apply {
		packet.emit(hdr.packet_in_header);
		packet.emit(hdr.ethernet);
		packet.emit(hdr.ipv4);
	}
}

/*************************************************************************
************************  S W I T C H  **********************************
*************************************************************************/

V1Switch(
RouterParser(),
MyVerifyChecksum(),
ingress(),
egress(),
MyComputeChecksum(),
deparser()
) main;
