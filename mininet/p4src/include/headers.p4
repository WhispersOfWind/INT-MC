/*************************************************************************
*********************** H E A D E R S  ***********************************
*************************************************************************/

#define MAX_INT_COUNT 100
#define MAX_HOPS 127

const bit<16> TYPE_IPV4  = 0x800;
const bit<16> TYPE_SOURCE_ROUTING = 0x1111;

const bit<8> IP_PROTO_TCP= 0x06;
const bit<8> IP_PROTO_UDP= 0x11;
const bit<16> INT_probe  = 0x10E1;


typedef bit<9>  egressSpec_t;
typedef bit<48> macAddr_t;
typedef bit<32> ip4Addr_t;

typedef bit<13> switch_id_t;
typedef bit<13> queue_depth_t;
typedef bit<6>  output_port_t;

header ethernet_t {
    macAddr_t dstAddr;
    macAddr_t srcAddr;
    bit<16>   etherType;
}

header source_routing_t {
    bit<1> last_header;
    bit<7> switch_id;
}


header ipv4_t {
    bit<4>    version;
    bit<4>    ihl;
    bit<6>    dscp;
    bit<2>    ecn;
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


header udp_t{
    bit<16> sport;
    bit<16> dport;
    bit<16> len;
    bit<16> chksum;
}


header int_header_t{
    bit<16> int_length;
    bit<16> int_count;
}

header int_metadata_t{
    bit<13> switch_id;
    bit<13> queue_depth;
    bit<6>  output_port;

    bit<32> enqueue_timestamp;
    bit<32> queue_latency;

    //bit<32> ingress_timestamp;
  //  bit<32> egress_timestamp;
    bit<32> hop_latency;
}


struct parser_metadata_t {
    bit<16> num_headers_remaining;
}

struct metadata {
    parser_metadata_t  parser_metadata;
}

struct headers {
    ethernet_t     ethernet;
    source_routing_t[MAX_HOPS] source_routes;
    ipv4_t         ipv4;
    udp_t	   udp;
    int_header_t   int_header;  	   
    int_metadata_t[MAX_INT_COUNT] int_metadata;
}

error { IPHeaderWithoutOptions }
