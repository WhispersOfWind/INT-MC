from p4utils.utils.topology import Topology
from p4utils.utils.sswitch_API import SimpleSwitchAPI

class SRController(object):

    def __init__(self):

        self.topo = Topology(db="topology.db")
        self.controllers = {}
        self.init()

    def init(self):
        self.connect_to_switches()
        #self.reset_states()
       # self.set_table_defaults()

    def reset_states(self):
        [controller.reset_state() for controller in self.controllers.values()]

    def connect_to_switches(self):
        for p4switch in self.topo.get_p4switches():
            thrift_port = self.topo.get_thrift_port(p4switch)
            self.controllers[p4switch] = SimpleSwitchAPI(thrift_port)

    #def set_table_defaults(self):
    #    for controller in self.controllers.values():
    #        controller.table_set_default("device_to_port", "drop", [])

    def route(self):
        switches = {sw_name:{} for sw_name in self.topo.get_p4switches().keys()}
	print "Set the device_tp_port table of the next switches:", switches
        print "==============================================================================="
        print "self.controllers:", self.controllers
        print "==============================================================================="
           	
        for sw_name, controller in self.controllers.items():
            for sw_dst in self.topo.get_switches_connected_to(sw_name):
		sw_port = self.topo.node_to_node_port_num(sw_name, sw_dst)
		dst_sw_mac = self.topo.node_to_node_mac(sw_dst, sw_name)
		
		#add rule
		print "table_add at {}:".format(sw_name)
		self.controllers[sw_name].table_add("device_to_port", "ipv4_forward", [str(sw_port)],
                                                                    [str(dst_sw_mac), str(sw_port)])
		


    def main(self):
        self.route()

if __name__ == "__main__":
    controller = SRController().main()
