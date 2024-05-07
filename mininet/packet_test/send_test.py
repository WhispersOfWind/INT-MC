#!/usr/bin/env python
import argparse
import sys
import socket
import random
import struct
import time
from time import sleep

from scapy.all import sendp, send, get_if_list, get_if_hwaddr, get_if_addr
from scapy.all import Packet
from scapy.all import Ether, IP, UDP, TCP

sleep_time=0

def get_if():
    ifs=get_if_list()
    iface=None # "h1-eth0"
    for i in get_if_list():
        if "ens7np1" in i:
            iface=i
            break;
    if not iface:
        print ("Cannot find ens7np1 interface")
        exit(1)
    return iface


def main():

    iface = get_if()
    source = get_if_hwaddr(iface)
    dst_ip = '192.168.123.169'
    addr = socket.gethostbyname(dst_ip) 

    print (source)
    print (addr)

    data= '\x07\x07'*500

    pkt =  Ether(src=get_if_hwaddr(iface), dst='ff:ff:ff:ff:ff:ff')

    pkt = pkt / IP(dst=addr) / UDP(dport=55555, sport=random.randint(49152,65535) ) / data
    
    pkt.show2()

    while True: 
        sendp(pkt, iface=iface)
        sleep(0.005) 

if __name__ == '__main__':
    main()
