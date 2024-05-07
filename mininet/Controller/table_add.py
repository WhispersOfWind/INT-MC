from p4utils.utils.topology import Topology
from p4utils.utils.sswitch_API import SimpleSwitchAPI

class RoutingController(object):

    def __init__(self):

        self.topo = Topology(db="topology.db")
        self.controllers = {}
        self.init()

    def init(self):
        self.connect_to_switches()
        #self.reset_states()
        self.set_table_defaults()

    def reset_states(self):
        [controller.reset_state() for controller in self.controllers.values()]

    def connect_to_switches(self):
        for p4switch in self.topo.get_p4switches():
            thrift_port = self.topo.get_thrift_port(p4switch)
            self.controllers[p4switch] = SimpleSwitchAPI(thrift_port)

    def set_table_defaults(self):
        for controller in self.controllers.values():
            controller.table_set_default("ipv4_lpm", "drop", [])

    def route(self):
        switches = {sw_name:{} for sw_name in self.topo.get_p4switches().keys()}
	print "switches:", switches
        print "==============================================================================="
        print "self.controllers:", self.controllers
        print "==============================================================================="
           	
        for sw_name, controller in self.controllers.items():

	#addd rules for table ipv4_lpm
            for sw_dst in self.topo.get_p4switches():

                #if its ourselves we create direct connections
                if sw_name == sw_dst:
                    for host in self.topo.get_hosts_connected_to(sw_name):
                        sw_port = self.topo.node_to_node_port_num(sw_name, host)
                        host_ip = self.topo.get_host_ip(host) + "/32"
                        host_mac = self.topo.get_host_mac(host)
			print host, "(", host_ip, host_mac, ")", "-->", sw_name, "with port:", sw_port  

                        #add rule
                        print "table_add at {}:".format(sw_name)
                        self.controllers[sw_name].table_add("ipv4_lpm", "ipv4_forward", [str(host_ip)], [str(host_mac), str(sw_port)])

                #check if there are directly connected hosts
                else:
                    if self.topo.get_hosts_connected_to(sw_dst):
                        paths = self.topo.get_shortest_paths_between_nodes(sw_name, sw_dst)
 			print sw_name,"->",sw_dst,":",paths
                        for host in self.topo.get_hosts_connected_to(sw_dst):
			    next_hop = paths[0][1] #if there are more than one path, choose the first path
                            host_ip = self.topo.get_host_ip(host) + "/24"
                            sw_port = self.topo.node_to_node_port_num(sw_name, next_hop)
                            dst_sw_mac = self.topo.node_to_node_mac(next_hop, sw_name)

                            #add rule
                            print "table_add at {}:".format(sw_name)
                            self.controllers[sw_name].table_add("ipv4_lpm", "ipv4_forward", [str(host_ip)],
                                                                    [str(dst_sw_mac), str(sw_port)])

	#add table for device_to_port  ( from sw_port -> sw_port )
        #    for sw_dst in self.topo.get_switches_connected_to(sw_name):
	#	sw_port = self.topo.node_to_node_port_num(sw_name, sw_dst)
	#	dst_sw_mac = self.topo.node_to_node_mac(sw_dst, sw_name)
		
		#add rule
	#	print "table_add at {}:".format(sw_name)
	#	self.controllers[sw_name].table_add("device_to_port", "ipv4_forward", [str(sw_port)],
        #                                                            [str(dst_sw_mac), str(sw_port)])

	#add table for device_to_port  ( from sw_dst_id -> sw_port )
            for sw_dst in self.topo.get_switches_connected_to(sw_name):
		sw_port = self.topo.node_to_node_port_num(sw_name, sw_dst)
		dst_sw_mac = self.topo.node_to_node_mac(sw_dst, sw_name)
		
		sw = str(sw_dst)
		sw_dst_id = sw[1:]

		#add rule
		print "table_add at {}:".format(sw_name)
		self.controllers[sw_name].table_add("device_to_port", "ipv4_forward", [str(sw_dst_id)],
                                                                    [str(dst_sw_mac), str(sw_port)])


	#add table for int_table
        #    sw = str(sw_name)
	#    sw_id = sw[1:]
	#    print "table_number is {}:".format(sw_id)
	#    self.controllers[sw_name].table_set_default("int_table", "add_int_metadata", sw_id)	
		


    def main(self):
        self.route()

if __name__ == "__main__":
    controller = RoutingController().main()
