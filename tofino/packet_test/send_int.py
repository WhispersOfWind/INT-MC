#!/usr/bin/env python

import argparse
import sys
import socket
import random
import struct

from scapy.all import sendp, send, hexdump, get_if_list, get_if_hwaddr , bind_layers
from scapy.all import Packet, IPOption
from scapy.all import Ether, IP, UDP ,Raw
from scapy.all import IntField, FieldListField, FieldLenField, ShortField, PacketListField, BitField
from scapy.layers.inet import _IPOption_HDR

from time import sleep

def get_if():
    ifs=get_if_list()
    iface=None 
    for i in get_if_list():
        if "ens7np1" in i:
            iface=i  
            break;
    if not iface:
        print ("Cannot find ens7np1 interface")
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

def main():

    if len(sys.argv)<3:
        print ('pass 2 arguments: <destination> "<message>"')
        exit(1)

    addr = socket.gethostbyname(sys.argv[1])
    iface = get_if()
    print ("sending on interface %s to %s" % (iface, str(addr)))

    s = str(input('Type space separated switch_ids nums (example: "2 3 2 2 1") or "q" to quit: '))
    if s == "q":
        print("no source_routing information , ipve transmit")

    i = 0
    pkt =  Ether(src=get_if_hwaddr(iface), dst='ff:ff:ff:ff:ff:ff',type=0x1111)

    for p in s.split(" "):
        try:
            pkt = pkt / SourceRoute(last_header=0, swid=int(p))
            i = i+1
        except ValueError:
            pass
    if pkt.haslayer(SourceRoute):
        pkt.getlayer(SourceRoute, i).last_header = 1

    pkt = pkt / IP(dst=addr) / UDP(dport=0x1010, sport=1234) 
    pkt = pkt / INT_metadata(count=0,int_data=[])  

    pkt.show2()
    hexdump(pkt)
    try:
        for i in range(int(sys.argv[2])):
            sendp(pkt, iface=iface)
            sleep(2)
    except KeyboardInterrupt:
        raise


if __name__ == '__main__':
    main()
