/* -*- P4_16 -*- */

#include <core.p4>
#include <v1model.p4>

/*************************************************************************
**************   H E A D E R S   A N D   S T R U C T S   ****************
*************************************************************************/
struct headers
{

}
struct metadata
{
}

/*************************************************************************
*********************** P A R S E R  ***********************************
*************************************************************************/

parser MyParser(packet_in packet,
                out headers hdr,
                inout metadata meta,
                inout standard_metadata_t standard_metadata)
{
	state start
	{
        transition accept;
	}
}

/*************************************************************************
************   C H E C K S U M    V E R I F I C A T I O N   *************
*************************************************************************/

control MyVerifyChecksum(inout headers hdr, inout metadata meta)
{   
	apply
	{
	}
}

/*************************************************************************
**************  I N G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyIngress(inout headers hdr,
                  inout metadata meta,
                  inout standard_metadata_t standard_metadata) 
{
	// zdefiniowanie akcji, ktora ustawia port wyjsciowy na taki jaki jest na wejsciu akcji
	action set_output_interface(bit<9> out_port) {
 		standard_metadata.egress_spec = out_port;
	}
	// ta tablea "mapuje interfejsy/porty" - stąd jej nazwa
	// kluczem do przeszukiwania wpisów jest port wejściowy, dopasowanie ma byc typu 'exact'(identyczne)
	// akcje to albo set_output_interface zdefiniowane wyzej, albo brak akcji w przypadku braku dopasowania
	// rozmiar to 256 wspisów, tyle ile 1 bajt pozwala
	table interface_mapper {
		key = {
			standard_metadata.ingress_port: exact;
		}
		actions = {
			set_output_interface;
			NoAction;
		}
		size = 256; // Correctly specify the size outside of the actions block
	}

	apply 
	{	
		interface_mapper.apply();
	}
}

/*************************************************************************
****************  E G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyEgress(inout headers hdr,
                 inout metadata meta,
                 inout standard_metadata_t standard_metadata)
{
	apply
	{
	}
}

/*************************************************************************
*************   C H E C K S U M    C O M P U T A T I O N   **************
*************************************************************************/

control MyComputeChecksum(inout headers hdr, inout metadata meta)
{
	apply
	{
	}
}


/*************************************************************************
***********************  D E P A R S E R  *******************************
*************************************************************************/

control MyDeparser(packet_out packet, in headers hdr)
{
	apply
	{
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