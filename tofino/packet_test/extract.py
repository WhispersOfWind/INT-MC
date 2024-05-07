# attempt to parse switch id, ingress & egress ports, hop latency, qid & qdepth
import sys
import struct
import os
from datetime import datetime

from scapy.all import rdpcap , Packet
from scapy.all import IntField , ShortField , ByteField , BitField , FieldLenField , PacketListField , FieldListField

from scapy.all import sendp, send, hexdump, get_if_list, get_if_hwaddr , bind_layers

from scapy.all import Ether, IP, UDP ,Raw

int_header_size = 12
data_hop_len = 28
total_packets_recvd = 0
experiment_starts = datetime.now()

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

packets = rdpcap('s2-eth1_in.pcap')

def main():

    for packet in packets:
	
		global experiment_starts
		global total_packets_recvd

		if total_packets_recvd == 0:
			experiment_starts = datetime.now()

		dirpath = os.getcwd()

		foldername = os.path.basename(dirpath)

		rfile = open(dirpath+"/../results/s2-eth1_50.txt","a")

		total_packets_recvd = total_packets_recvd + 1;
		time_now = datetime.now()
		time_to_write = (time_now - experiment_starts).total_seconds()

		p1=packet.copy()

		if p1.haslayer(INT_metadata) :
			p1 = p1.payload.payload.payload

			count = p1.count
    		p1_bytes = bytes(p1)
			p1_bytes = p1_bytes[int_header_size:]



		
				int_header = INT_header( p1_bytes[0:int_header_size] )
			p1_bytes = p1_bytes[int_header_size:]
			#int_metadata = INT_metadata( p1_bytes[4:] )


			#Saving the metadata in the package to the file
			for i in range(count):
				p2 = Metadata( p1_bytes[0:data_hop_len] )   # Turning p2 into an instantiated object of the metadata class 
				p2.show()
				#print(p2.hop_latency)
				#print( str(p2.hop_latency) )

				rfile.write(str(time_to_write))
				rfile.write(" ")
		
				rfile.write(str(packet[IP].src))
				rfile.write(" ")

				rfile.write(str(packet[IP].dst))
				rfile.write(" ")

				rfile.write(str(p2.swid))
				rfile.write(" ")

				rfile.write(str(p2.portid))
				rfile.write(" ")

				rfile.write(str(p2.hop_latency))
				rfile.write(" ")

				rfile.write(str(p2.queue_latency))
				rfile.write(" ")

				rfile.write(str(p2.qdepth))
				rfile.write(" ")

				rfile.write("\n")
		
				p1_bytes = p1_bytes[data_hop_len : ]
		
		rfile.close()
	
if __name__ == '__main__':
    main()
