/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2019-present Barefoot Networks, Inc.
 *
 * All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks, Inc.
 * and its suppliers and may be covered by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law.  Dissemination of
 * this information or reproduction of this material is strictly forbidden unless
 * prior written permission is obtained from Barefoot Networks, Inc.
 *
 * No warranty, explicit or implicit is provided, unless granted under a written
 * agreement with Barefoot Networks, Inc.
 *
 ******************************************************************************/

#include <core.p4>
#if __TARGET_TOFINO__ == 2
#include <t2na.p4>
#else
#include <tna.p4>
#endif

#include "common/headers.p4"
#include "common/util.p4"

struct metadata_t {
    bit<32> pkt_len;
}

struct int_reg_item_t {
    bit<32> int_data;
}

//struct metadata_t {}

// ---------------------------------------------------------------------------
// Ingress parser
// ---------------------------------------------------------------------------
parser SwitchIngressParser(
        packet_in pkt,
        out header_t hdr,
        out metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {

    TofinoIngressParser() tofino_parser;
    
    state start {
        
        tofino_parser.apply(pkt, ig_intr_md);

        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select (hdr.ethernet.ether_type) {
            // ETHERTYPE_IPV4 : parse_ipv4;
            TYPE_SOURCE_ROUTING : parse_source_routing ;
            default : parse_ipv4;
        }
    }

    state parse_source_routing {
        pkt.extract(hdr.source_routes.next);
        transition select(hdr.source_routes.last.last_header) {
            1: parse_ipv4;
            default: parse_source_routing;
        }
    }
/*
    state parse_source_routing {
        pkt.extract(hdr.source_routes);
        transition parse_ipv4;
    }
*/
    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol) {
            IP_PROTOCOLS_UDP: parse_udp;
            default: accept;
        }
    }

    state parse_udp {
        pkt.extract(hdr.udp);
        transition select(hdr.udp.dst_port) {
              INT_probe: parse_int_shim;
              default: accept;
        }
    }

    state parse_int_shim {
        pkt.extract(hdr.int_shim);
        transition  parse_int_header;
    }

    state parse_int_header {
        pkt.extract(hdr.int_header); 
        transition accept;
        }
    }

// ---------------------------------------------------------------------------
// Ingress 
// ---------------------------------------------------------------------------
control SwitchIngress_0(
        inout header_t hdr,
        inout metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {

    //Alpm(number_partitions = 1024, subtrees_per_partition = 2) algo_lpm;

//   bit<10> vrf;

    action miss() {
        ig_intr_dprsr_md.drop_ctl = 0x1; // Drop packet.
    }

    action set_normal_ethernet(){
        hdr.ethernet.ether_type = ETHERTYPE_IPV4;
    }

    action ipv4_forward(PortId_t dst_port) {
        //set the src mac address as the previous dst, this is not correct right?
        //hdr.ethernet.src_addr = srcMac;
       //set the destination mac address that we got from the match in the table
        //hdr.ethernet.dst_addr = dst_addr;
        //set the output port that we also get from the table
        ig_intr_tm_md.ucast_egress_port = dst_port;
        //decrease ttl by 1
       // hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
        ig_intr_dprsr_md.drop_ctl = 0x0;

    }

    table device_to_port {

        key = {
            hdr.source_routes[0].next_switch_id: exact;
        }

        actions = {
            ipv4_forward;
            NoAction;
        }
        size = 1024;
        default_action = NoAction();
        const entries = {
            7w4:ipv4_forward(56);
            7w10:ipv4_forward(40);
            7w12:ipv4_forward(48);

        }

    }

    table ipv4_lpm {
        key = {
//            vrf : exact;
            hdr.ipv4.dst_addr: lpm;
        }
        actions = {
            ipv4_forward;
            miss;
            //NoAction;
        }
        size = 1024;
        const default_action = miss;
        //alpm = algo_lpm;
    }

    apply {
//       
        if (hdr.source_routes[0].isValid()){

            device_to_port.apply();
            //ig_intr_tm_md.ucast_egress_port = 32;

            //ig_intr_dprsr_md.drop_ctl = 0x0;

            //ig_intr_tm_md.bypass_egress = 1w1;

            if (hdr.source_routes[0].last_header == 1 )
                set_normal_ethernet();
            hdr.source_routes.pop_front(1);

        }

        else if (hdr.ipv4.isValid()){
            ipv4_lpm.apply();
        }

        if(hdr.int_shim.isValid())
            hdr.int_shim.ingress_global_tstamp = ig_intr_prsr_md.global_tstamp;

    }
}

control SwitchIngress_1(
        inout header_t hdr,
        inout metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {

    //Alpm(number_partitions = 1024, subtrees_per_partition = 2) algo_lpm;

//   bit<10> vrf;

    action miss() {
        ig_intr_dprsr_md.drop_ctl = 0x1; // Drop packet.
    }

    action set_normal_ethernet(){
        hdr.ethernet.ether_type = ETHERTYPE_IPV4;
    }

    action ipv4_forward(PortId_t dst_port) {
        //set the src mac address as the previous dst, this is not correct right?
        //hdr.ethernet.src_addr = srcMac;
       //set the destination mac address that we got from the match in the table
        //hdr.ethernet.dst_addr = dst_addr;
        //set the output port that we also get from the table
        ig_intr_tm_md.ucast_egress_port = dst_port;
        //decrease ttl by 1
       // hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
        ig_intr_dprsr_md.drop_ctl = 0x0;

    }

    table device_to_port {

        key = {
            hdr.source_routes[0].next_switch_id: exact;
        }

        actions = {
            ipv4_forward;
            NoAction;
        }
        size = 1024;
        default_action = NoAction();
        const entries = {
            7w9:ipv4_forward(132);
            7w11:ipv4_forward(140);
            7w13:ipv4_forward(148);
        }

    }

    table ipv4_lpm {
        key = {
//            vrf : exact;
            hdr.ipv4.dst_addr: lpm;
        }
        actions = {
            ipv4_forward;
            miss;
            //NoAction;
        }
        size = 1024;
        const default_action = miss;
        //alpm = algo_lpm;
    }

    apply {
//       
        if (hdr.source_routes[0].isValid()){

            device_to_port.apply();
            //ig_intr_tm_md.ucast_egress_port = 32;

            //ig_intr_dprsr_md.drop_ctl = 0x0;

            //ig_intr_tm_md.bypass_egress = 1w1;

            if (hdr.source_routes[0].last_header == 1 )
                set_normal_ethernet();
            hdr.source_routes.pop_front(1);

        }

        else if (hdr.ipv4.isValid()){
            ipv4_lpm.apply();
        }

        if(hdr.int_shim.isValid())
            hdr.int_shim.ingress_global_tstamp = ig_intr_prsr_md.global_tstamp;

    }
}

// ---------------------------------------------------------------------------
// Ingress Deparser
// ---------------------------------------------------------------------------
control SwitchIngressDeparser(
        packet_out pkt,
        inout header_t hdr,
        in metadata_t ig_md,
        in ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md) {

    apply {
        pkt.emit(hdr);
        //pkt.emit(hdr.ethernet);

       // pkt.emit(hdr.source_routes);

        //pkt.emit(hdr.ipv4);
       // pkt.emit(hdr.udp);
        
        // INT headers
       // pkt.emit(hdr.int_shim);
       // pkt.emit(hdr.int_header);
    }
}

parser testEgressParser(    
    packet_in pkt,
    out header_t hdr,
    out metadata_t eg_md,
    out egress_intrinsic_metadata_t eg_intr_md){

    TofinoEgressParser() tofino_parser;

    state start {
        tofino_parser.apply(pkt, eg_intr_md);
        eg_md.pkt_len = 0;

        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select (hdr.ethernet.ether_type) {
            ETHERTYPE_IPV4 : parse_ipv4;
            TYPE_SOURCE_ROUTING : parse_source_routing ;
            default : reject;
        }
    }
/*
    state parse_source_routing {
        pkt.extract(hdr.source_routes.next);
        transition select(hdr.source_routes.last.last_header) {
            1: parse_ipv4;
            default: parse_source_routing;
        }
    }
*/

    state parse_source_routing {
        pkt.extract(hdr.source_routes.next);
        transition select(hdr.source_routes.last.last_header) {
            1: parse_ipv4;
            default: parse_source_routing;
        }
    }
    
    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol) {
            IP_PROTOCOLS_UDP: parse_udp;
            default: accept;
        }
    }

    state parse_udp {
        pkt.extract(hdr.udp);

        transition select(hdr.udp.dst_port) {
              INT_probe: parse_int_shim;
              default: accept;
        }
    }

    state parse_int_shim {
        pkt.extract(hdr.int_shim);
        transition  parse_int_header;
    }

    state parse_int_header {

        pkt.extract(hdr.int_header); 
        transition accept;
    }

}

control testEgress(    
    inout header_t hdr,
    inout metadata_t eg_md,
    in egress_intrinsic_metadata_t eg_intr_md,
    in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
    inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
    inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md    ){


    Register<int_reg_item_t, bit<32>>(size=1, initial_value={32w0}) int_pkts_reg;
    RegisterAction<int_reg_item_t, bit<32>, bit<32>>(int_pkts_reg) int_pkts_get = {
        void apply(inout int_reg_item_t item, out bit<32> ret) {
            ret = item.int_data;
        }
    };
    RegisterAction<int_reg_item_t, bit<32>, void>(int_pkts_reg) int_pkts_update = {
        void apply(inout int_reg_item_t item) {
            item.int_data = item.int_data + 1;
        }
    };
    Register<int_reg_item_t, bit<32>>(size=1, initial_value={32w0}) int_bytes_reg;
    RegisterAction<int_reg_item_t, bit<32>, bit<32>>(int_bytes_reg) int_bytes_get = {
        void apply(inout int_reg_item_t item, out bit<32> ret) {
            ret = item.int_data;
        }
    };
    RegisterAction<int_reg_item_t, bit<32>, void>(int_bytes_reg) int_bytes_update = {
        void apply(inout int_reg_item_t item) {
            item.int_data = item.int_data + eg_md.pkt_len;
        }
    };

    action add_int_metadata(){
        //hdr.local_int_data.switch_id =  (bit<10>)swid ;
        //hdr.local_int_data.output_port = (bit<6>)eg_intr_md.egress_port;
        hdr.local_int_data.output_port = (bit<16>)eg_intr_md.egress_port;
        hdr.local_int_data.hop_latency = (bit<32>) (eg_intr_md_from_prsr.global_tstamp - hdr.int_shim.ingress_global_tstamp) ; 
        hdr.local_int_data.queue_en_depth = (bit<16>)eg_intr_md.enq_qdepth;    
        hdr.local_int_data.queue_de_depth = (bit<16>)eg_intr_md.deq_qdepth;    
        hdr.local_int_data.queue_latency = (bit<32>)eg_intr_md.deq_timedelta; 
        hdr.local_int_data.egress_timestamp = (bit<48>)eg_intr_md_from_prsr.global_tstamp;

        // hdr.local_int_data.pkts = int_pkts_get.execute(0);
        // hdr.local_int_data.bytes = int_bytes_get.execute(0);
    }

    // table int_table {
    //     actions = {
    //         add_int_metadata;
    //     }
    //     size = 1024;
    // }

	apply {

        if(hdr.ipv4.isValid()){
            eg_md.pkt_len = (bit<32>)hdr.ipv4.total_len;

	        if (!hdr.int_header.isValid()){
                int_pkts_update.execute(0);
                int_bytes_update.execute(0);
            }
            else {
                hdr.local_int_data.setValid();

                add_int_metadata();

                hdr.local_int_data.pkts = int_pkts_get.execute(0);
                hdr.local_int_data.bytes = int_bytes_get.execute(0);

                //int_table.apply();

                hdr.ipv4.total_len = hdr.ipv4.total_len + 28;
                hdr.udp.hdr_length =  hdr.udp.hdr_length + 28;
                //hdr.int_header.int_len = hdr.int_header.int_len + 28;
                hdr.int_header.int_count = hdr.int_header.int_count + 1;
            }
            
        }
    }
}

control testEgressDeparser(    
    packet_out pkt,
    inout header_t hdr,
    in metadata_t eg_md,
    in egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md){
    apply{
        pkt.emit(hdr);
        // pkt.emit(hdr.ethernet);

        // pkt.emit(hdr.source_routes);
        
        // pkt.emit(hdr.ipv4);
        // pkt.emit(hdr.udp);

        // pkt.emit(hdr.int_shim);
        // pkt.emit(hdr.int_header);
        // pkt.emit(hdr.local_int_data);
        // pkt.emit(hdr.int_data);
    }
}


Pipeline(SwitchIngressParser(),
         SwitchIngress_0(),
         SwitchIngressDeparser(),
         //EmptyEgressParser(),
         //EmptyEgress(),
        // EmptyEgressDeparser()) pipe;
         testEgressParser(),
         testEgress(),
         testEgressDeparser()) pipe_1;

Pipeline(SwitchIngressParser(),
         SwitchIngress_1(),
         SwitchIngressDeparser(),
         //EmptyEgressParser(),
         //EmptyEgress(),
        // EmptyEgressDeparser()) pipe;
         testEgressParser(),
         testEgress(),
         testEgressDeparser()) pipe_2;

Switch(pipe_1,pipe_2) main;
