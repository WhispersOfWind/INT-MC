/* -*- P4_16 -*- */
#include <core.p4>
#include <v1model.p4>

//My includes
#include "include/headers.p4"
#include "include/parsers.p4"


const bit<4> MAX_PORT = 15;

/*************************************************************************
************   C H E C K S U M    V E R I F I C A T I O N   *************
*************************************************************************/

control MyVerifyChecksum(inout headers hdr, inout metadata meta) {
    apply {  }
}


/*************************************************************************
**************  I N G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyIngress(inout headers hdr,
                  inout metadata meta,
                  inout standard_metadata_t standard_metadata) {

    action drop() {
        mark_to_drop(standard_metadata);
    }

    action set_normal_ethernet(){
        hdr.ethernet.etherType = TYPE_IPV4;
    }

    action ipv4_forward(macAddr_t dstAddr, egressSpec_t port) {

        //set the src mac address as the previous dst, this is not correct right?
        hdr.ethernet.srcAddr = hdr.ethernet.dstAddr;

       //set the destination mac address that we got from the match in the table
        hdr.ethernet.dstAddr = dstAddr;

        //set the output port that we also get from the table
        standard_metadata.egress_spec = port;

        //decrease ttl by 1
        hdr.ipv4.ttl = hdr.ipv4.ttl -1;

    }

//table: ipv4 routing rule matching
    table ipv4_lpm {
        key = {
            hdr.ipv4.dstAddr: lpm;
        }
        actions = {
            ipv4_forward;
            drop;
            NoAction;
        }
        size = 1024;
        default_action = NoAction();
    }

//table: source routing rule matching
    table device_to_port {

        key = {
            hdr.source_routes[0].switch_id: exact;
        }

        actions = {
            ipv4_forward;
            NoAction;
        }
        size = 128;
        default_action = NoAction();

    }

    apply {

        //only if IPV4 the rule is applied. Therefore other packets will not be forwarded.
        if (hdr.source_routes[0].isValid() && device_to_port.apply().hit){
            //if it is the last header then.
            if (hdr.source_routes[0].last_header == 1 ){
               set_normal_ethernet();
            }
            hdr.source_routes.pop_front(1);
        }

        else if (hdr.ipv4.isValid()){
            ipv4_lpm.apply();
            //it means that it did not hit but that there is something to remove..
            if (hdr.source_routes[0].isValid()){
                //if it is the last header then.
                if (hdr.source_routes[0].last_header == 1 ){   //source routing ending, setting ethernet.etherType to TYPE_IPV4
                   set_normal_ethernet();
                }
                hdr.source_routes.pop_front(1);

            }
        }
    }
}

/*************************************************************************
****************  E G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyEgress(inout headers hdr,
                 inout metadata meta,
                 inout standard_metadata_t standard_metadata) {


    action add_int_metadata(switch_id_t swid){

        //increase int stack counter by one
        hdr.int_header.int_count = hdr.int_header.int_count + 1;

        hdr.int_metadata.push_front(1);
        // This was not needed in older specs. Now by default pushed invalid elements are
        hdr.int_metadata[0].setValid();
        hdr.int_metadata[0].switch_id   = (bit<13>)swid;
        hdr.int_metadata[0].queue_depth = (bit<13>)standard_metadata.deq_qdepth;
        hdr.int_metadata[0].output_port = (bit<6>)standard_metadata.egress_port;

        hdr.int_metadata[0].enqueue_timestamp = standard_metadata.enq_timestamp;
        hdr.int_metadata[0].queue_latency     = standard_metadata.deq_timedelta;

        //hdr.int_metadata[0].ingress_timestamp = (bit<32>)standard_metadata.ingress_global_timestamp;
        //hdr.int_metadata[0].egress_timestamp  = (bit<32>)standard_metadata.egress_global_timestamp;	
        hdr.int_metadata[0].hop_latency       = (bit<32>)standard_metadata.egress_global_timestamp - (bit<32>)standard_metadata.ingress_global_timestamp;

	// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	hdr.ipv4.totalLen = hdr.ipv4.totalLen + 16;
        hdr.udp.len =  hdr.udp.len + 16;
	//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

        //update int_header length
        hdr.int_header.int_length = hdr.int_header.int_length + 16;
    }

    table int_table {
        actions = {
            add_int_metadata;
            NoAction;
        }
        default_action = NoAction();
    }

    counter((bit<32>)MAX_PORT, CounterType.packets) egressPortCounter; 

    apply {
        egressPortCounter.count((bit<32>)standard_metadata.egress_port);
        if (hdr.int_header.isValid()){
            int_table.apply();
        }
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
              hdr.ipv4.dscp,
              hdr.ipv4.ecn,
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
    }
}





/*************************************************************************
***********************  S W I T C H  *******************************
*************************************************************************/

//switch architecture
V1Switch(
MyParser(),
MyVerifyChecksum(),
MyIngress(),
MyEgress(),
MyComputeChecksum(),
MyDeparser()
) main;
