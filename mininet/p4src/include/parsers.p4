/*************************************************************************
*********************** P A R S E R  *******************************
*************************************************************************/

parser MyParser(packet_in packet,
                out headers hdr,
                inout metadata meta,
                inout standard_metadata_t standard_metadata) {

    state start {

        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType){
            TYPE_IPV4: parse_ipv4;
            TYPE_SOURCE_ROUTING: parse_source_routing;
            default: accept;
        }
    }

    state parse_source_routing {
        packet.extract(hdr.source_routes.next);
        transition select(hdr.source_routes.last.last_header) {
            1: parse_ipv4;
            default: parse_source_routing;
        }
    }

    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol) {
            IP_PROTO_UDP: parse_udp;
            default: accept;
        }
    }


    state parse_udp {
        packet.extract(hdr.udp);
        transition select((hdr.udp.dport & INT_probe) == INT_probe) {
              true: parse_int_header;
              default: accept;
        }
}

    state parse_int_header {
        packet.extract(hdr.int_header);
        meta.parser_metadata.num_headers_remaining = hdr.int_header.int_count;
        transition select(meta.parser_metadata.num_headers_remaining){
            0: accept;
            default: parse_int_metadata;
        }
     }


    state parse_int_metadata {
        packet.extract(hdr.int_metadata.next);
        meta.parser_metadata.num_headers_remaining = meta.parser_metadata.num_headers_remaining -1 ;
        transition select(meta.parser_metadata.num_headers_remaining){
            0: accept;
            default: parse_int_metadata;
        }
    }
}

/*************************************************************************
***********************  D E P A R S E R  *******************************
*************************************************************************/

control MyDeparser(packet_out packet, in headers hdr) {
    apply {

        //parsed headers have to be added again into the packet.
        packet.emit(hdr.ethernet);
        packet.emit(hdr.source_routes);
        packet.emit(hdr.ipv4);
	packet.emit(hdr.udp);
	packet.emit(hdr.int_header);
	packet.emit(hdr.int_metadata);

    }
}
