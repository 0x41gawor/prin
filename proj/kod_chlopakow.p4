/* -*- P4_16 -*- */

// Lab 5 to jest

#include <core.p4>
#include <v1model.p4>

const bit<16> TYPE_IPV4 = 0x0800;

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

header tcp_t {
	bit<16> srcPort;
	bit<16> dstPort;
	bit<32> seqNo;
	bit<32> ackNo;
	bit<4>  dataOffset;
	bit<3>  res;
	bit<3>  ecn;
	bit<6>  ctrl;
	bit<16> window;
	bit<16> checksum;
	bit<16> urgentPtr;
}

header udp_t {
	bit<16> srcPort;
	bit<16> dstPort;
	bit<16> length_;
	bit<16> checksum;
}

struct learn_t {
    bit<48> srcMAC;
    bit<9>  ingress_port;
    bit<32> srcIP;
}

struct headers {
	ethernet_t	ethernet;
	ipv4_t		ipv4;
	tcp_t		tcp;
	udp_t		udp;
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
		transition parse_ethernet;
	}

	state parse_ethernet {
		packet.extract(hdr.ethernet);
		transition select(hdr.ethernet.etherType) {
			TYPE_IPV4: parse_ipv4;
			default: accept;
		}
	}
	
	state parse_ipv4 {
		packet.extract(hdr.ipv4);
		transition select (hdr.ipv4.protocol) {
			6: parse_tcp;
			17: parse_udp;
			default: accept;
		}
	}
	
	state parse_tcp {
		packet.extract(hdr.tcp);
		transition accept;
	}
	
	state parse_udp {
		packet.extract(hdr.udp);
		transition accept;
	}
}

/*************************************************************************
************   C H E C K S U M    V E R I F I C A T I O N   *************
*************************************************************************/

control MyVerifyChecksum(inout headers hdr, inout metadata meta)
{   
	apply{
		verify_checksum(true,
			{ hdr.ipv4.version,
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
			hdr.ipv4.hdrChecksum, HashAlgorithm.csum16);
			
		  verify_checksum_with_payload(hdr.tcp.isValid(),
			{ hdr.ipv4.srcAddr,
				hdr.ipv4.dstAddr,
				8w0,
				hdr.ipv4.protocol,
				hdr.tcp.srcPort,
				hdr.tcp.dstPort,
				hdr.tcp.seqNo,
				hdr.tcp.ackNo,
				hdr.tcp.dataOffset,
				hdr.tcp.res,
				hdr.tcp.ecn,
				hdr.tcp.ctrl,
				hdr.tcp.window,
				hdr.tcp.urgentPtr
			},
			hdr.tcp.checksum, HashAlgorithm.csum16);
			
		verify_checksum_with_payload(hdr.udp.isValid(),
			{ hdr.ipv4.srcAddr,
				hdr.ipv4.dstAddr,
				8w0,
				hdr.ipv4.protocol,
				hdr.udp.srcPort,
				hdr.udp.dstPort,
				hdr.udp.length_
			},
			hdr.udp.checksum, HashAlgorithm.csum16); 
			
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
	
	action dropa() {
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

/**************************************************/
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
	table ip_table {
		key = {
			hdr.ipv4.dstAddr: ternary;
		}
		actions = {
			dropa;
			NoAction;
		}
		default_action = NoAction();
	}
/**************************************************/    
	table tcp_table {
		key = {
			hdr.tcp.dstPort: ternary;
		}
		actions = {
			dropa;
			NoAction;
		}
		default_action = NoAction();
	}
/**************************************************/   
	table udp_table {
		key = {
		   hdr.udp.dstPort: ternary;
		}
		actions = {
			dropa;
			NoAction;
		}
		default_action = NoAction();
	}
/**************************************************/    
	table prot_table {
		key = {
			hdr.ipv4.protocol: ternary;
		}
		actions = {
			dropa;
			NoAction;
		}
		default_action = NoAction();
	}
/**************************************************/
	apply {
		smac.apply();	
		routing_table.apply();
		switching_table.apply();
		ip_table.apply();
		tcp_table.apply();
		udp_table.apply();
		prot_table.apply();
		if (hdr.ipv4.ttl == 255) {
			drop();
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

		default_action = drop();
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
			{ hdr.ipv4.version,
		  hdr.ipv4.ihl,
			  hdr.ipv4.diffserv,
			  hdr.ipv4.totalLen,
			  hdr.ipv4.identification,
			  hdr.ipv4.flags,
			  hdr.ipv4.fragOffset,
			  hdr.ipv4.ttl,
			  hdr.ipv4.protocol,
			  hdr.ipv4.srcAddr,
			  hdr.ipv4.dstAddr },
			hdr.ipv4.hdrChecksum,
			HashAlgorithm.csum16);
			
	 update_checksum_with_payload(hdr.tcp.isValid(),
			{ hdr.ipv4.srcAddr,
				hdr.ipv4.dstAddr,
				8w0,
				hdr.ipv4.protocol,
				hdr.tcp.srcPort,
				hdr.tcp.dstPort,
				hdr.tcp.seqNo,
				hdr.tcp.ackNo,
				hdr.tcp.dataOffset,
				hdr.tcp.res,
				hdr.tcp.ecn,
				hdr.tcp.ctrl,
				hdr.tcp.window,
				hdr.tcp.urgentPtr
			},
			hdr.tcp.checksum, HashAlgorithm.csum16);
			
		update_checksum_with_payload(hdr.udp.isValid(),
			{ hdr.ipv4.srcAddr,
				hdr.ipv4.dstAddr,
				8w0,
				hdr.ipv4.protocol,
				hdr.udp.srcPort,
				hdr.udp.dstPort,
				hdr.udp.length_
			},
			hdr.udp.checksum, HashAlgorithm.csum16);
	}
}

/*************************************************************************
***********************  D E P A R S E R  *******************************
*************************************************************************/

control deparser(packet_out packet,
				 in headers hdr) {
	apply {
		packet.emit(hdr.ethernet);
		packet.emit(hdr.ipv4);
		packet.emit(hdr.tcp);
		packet.emit(hdr.udp);
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