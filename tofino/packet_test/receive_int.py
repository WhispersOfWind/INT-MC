#!/usr/bin/env python
import sys
import struct
import os

from scapy.all import sniff, sendp, hexdump, get_if_list, get_if_hwaddr, bind_layers
from scapy.all import Packet, IPOption
from scapy.all import PacketListField, ShortField, IntField, LongField, BitField, FieldListField, FieldLenField
from scapy.all import Ether, IP, UDP, Raw
from scapy.layers.inet import _IPOption_HDR

int_header_size = 12
data_hop_len = 28
dirpath = os.getcwd()

def get_if():
    ifs=get_if_list()
    iface=None
    for i in get_if_list():
        if "enp6s0np0" in i:
            iface=i
            break;
    if not iface:
        print ("Cannot find enp6s0np0 interface")
        exit(1)
    return iface

class SwitchTrace(Packet):
    fields_desc = [ ShortField("output_port", 0),
                    IntField("hop_latency", 0),
                    ShortField("queue_en_depth",0),
		            ShortField("queue_de_depth",0),
		            IntField("queue_latency",0),
 		    	    BitField("egress_timestamp",0,48),
                    BitField("pkts",0,32) ,
                    BitField("txbytes",0,32)   ]
								
    def extract_padding(self, p):
        return "", p

class Metadata(Packet):
    name = "Metadata"
    fields_desc = [ ShortField("output_port", 0),
                    IntField("hop_latency", 0),
                    ShortField("queue_en_depth",0),
		            ShortField("queue_de_depth",0),
		            IntField("queue_latency",0),
 		    	    BitField("egress_timestamp",0,48),
                    BitField("pkts",0,32) ,
                    BitField("txbytes",0,32)   ]
								


class INT_metadata(Packet):
    name = "INT"
    fields_desc = [ 
                    ShortField("max_count", 10),  
                    ShortField("udp_dstport", 0),  
                    BitField("ingress_global_tstamp",0,48),
		            BitField("length", 12,8),   
                    BitField("count", 0,8),    
                    PacketListField("int_data", [],SwitchTrace,count_from=lambda pkt:(pkt.count*1)) ]


class SourceRoute(Packet):
   fields_desc = [ BitField("last_header", 0, 1),
                   BitField("swid", 0, 7)]


bind_layers(Ether, SourceRoute, type=0x1111)	
bind_layers(SourceRoute, SourceRoute, last_header=0)
bind_layers(SourceRoute, IP, last_header=1)		
bind_layers(UDP, INT_metadata , dport=0x1010)


def handle_pkt(pkt):
    print ("got a packet")
    pkt.show2()
    p1 = pkt.payload.payload.payload
    p1.show2()
    count = p1.count
    p1_bytes = bytes(p1)

    p1_bytes = p1_bytes[int_header_size:]

    rfile = open(dirpath+"/results/INT_udp_results_10s_BG.txt","a")

    for i in range(count):
        p2 = Metadata(p1_bytes[0:data_hop_len])

        rfile.write(str(p2.hop_latency))
        rfile.write(" ")

        rfile.write(str(p2.queue_latency))
        rfile.write(" ")

        rfile.write(str(p2.queue_en_depth))
        rfile.write(" ")

        rfile.write(str(p2.pkts))
        rfile.write(" ")

        rfile.write(str(p2.txbytes))
        rfile.write(" ")

        rfile.write("\n")

        p1_bytes = p1_bytes[data_hop_len:]


    rfile.close()

#    print "next print another packet form"
#    pkt.show()
#    hexdump(pkt)
    sys.stdout.flush()


def main():
    #iface = 'h2-eth0'
    iface = get_if()
    print ("sniffing on %s" % iface)
    sys.stdout.flush()
    sniff(filter="udp and port 0x1010", iface = iface, prn = lambda x: handle_pkt(x))

if __name__ == '__main__':
    main()
