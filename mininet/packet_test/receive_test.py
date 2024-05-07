#!/usr/bin/env python
import sys
import struct

from scapy.all import sniff, sendp, hexdump, get_if_list, get_if_hwaddr, bind_layers
from scapy.all import Packet, IPOption
from scapy.all import PacketListField, ShortField, IntField, LongField, BitField, FieldListField, FieldLenField
from scapy.all import Ether, IP, UDP, Raw
from scapy.layers.inet import _IPOption_HDR

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


def handle_pkt(pkt):
    print ("got a packet")
    pkt.show2()
#    print "next print another packet form"
#    pkt.show()
#    hexdump(pkt)
    sys.stdout.flush()


def main():
   # iface = 'h2-eth0'
    iface = get_if()

    print ("sniffing on %s" % iface)
    sys.stdout.flush()
    sniff(filter="udp and port 55555", iface = iface, prn = lambda x: handle_pkt(x))

if __name__ == '__main__':
    main()
