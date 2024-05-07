#################################################################################################
# BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
#
# Copyright (c) 2019-present Barefoot Networks, Inc.
#
# All Rights Reserved.
#
# NOTICE: All information contained herein is, and remains the property of
# Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
# technical concepts contained herein are proprietary to Barefoot Networks, Inc.
# and its suppliers and may be covered by U.S. and Foreign Patents, patents in
# process, and are protected by trade secret or copyright law.  Dissemination of
# this information or reproduction of this material is strictly forbidden unless
# prior written permission is obtained from Barefoot Networks, Inc.
#
# No warranty, explicit or implicit is provided, unless granted under a written
# agreement with Barefoot Networks, Inc.
#
################################################################################
import os
import logging
import random

from ptf import config
from collections import namedtuple
import ptf.testutils as testutils
from bfruntime_client_base_tests import BfRuntimeTest
import bfrt_grpc.client as gc
import grpc

this_dir = os.path.dirname(os.path.abspath(__file__))

logger = logging.getLogger('Test')
if not len(logger.handlers):
    logger.addHandler(logging.StreamHandler())

swports = []
for device, port, ifname in config["interfaces"]:
    swports.append(port)
    swports.sort()

if swports == []:
    swports = list(range(9))

class LpmMatch_ipv4_0(BfRuntimeTest):
    """@brief Basic test for TCAM-based lpm matches.
    """

    def setUp(self):
        client_id = 0
        p4_name = "int_pipe_2"
        BfRuntimeTest.setUp(self, client_id, p4_name)

    def runTest(self):

        # Get bfrt_info and set it as part of the test
        bfrt_info = self.interface.bfrt_info_get("int_pipe_2")

        #ipv4_lpm table entry

        #pipe0_ipv4_0
        f_0 = open(this_dir+'/ipv4_0.txt')
        lines_0 = f_0.readlines()

        forward_table_0 = bfrt_info.table_get("SwitchIngress_0.ipv4_lpm")
        forward_table_0.info.key_field_annotation_add("hdr.ipv4.dst_addr", "ipv4")

        key_random_tuple_0 = namedtuple('key_random', 'dst_ip prefix_len')
        tuple_list_0 = []
        i = 0
        lpm_dict_0 = {}

        num_entries_0 = len(lines_0)
        while (i < num_entries_0):

            line = lines_0[i].split(" ")
            dst_ip = line[0]
            p_len = int(line[1])
            egress_port = int(line[2])

            tuple_list_0.append(key_random_tuple_0(dst_ip, p_len))
            logger.info("Adding %s %d %s", dst_ip, p_len, egress_port)
        
            target = gc.Target(device_id=0, pipe_id=0xffff) 
            key = forward_table_0.make_key([gc.KeyTuple('hdr.ipv4.dst_addr', dst_ip, prefix_len=p_len)]) 
            data = forward_table_0.make_data([gc.DataTuple('dst_port', egress_port)],'SwitchIngress_0.ipv4_forward')
            forward_table_0.entry_add(target, [key], [data])

            i += 1

        #pipe1_ipv4_1
        f_1 = open(this_dir+'/ipv4_1.txt')
        lines_1 = f_1.readlines()

        forward_table_1 = bfrt_info.table_get("SwitchIngress_1.ipv4_lpm")
        forward_table_1.info.key_field_annotation_add("hdr.ipv4.dst_addr", "ipv4")

        key_random_tuple_1 = namedtuple('key_random', 'dst_ip prefix_len')
        tuple_list_1 = []
        i = 0
        lpm_dict_1 = {}

        num_entries_1 = len(lines_1)
        while (i < num_entries_1):

            line = lines_1[i].split(" ")
            dst_ip = line[0]
            p_len = int(line[1])
            egress_port = int(line[2])

            tuple_list_1.append(key_random_tuple_1(dst_ip, p_len))
            logger.info("Adding %s %d %s", dst_ip, p_len, egress_port)
        
            target = gc.Target(device_id=0, pipe_id=0xffff) 
            key = forward_table_1.make_key([gc.KeyTuple('hdr.ipv4.dst_addr', dst_ip, prefix_len=p_len)]) 
            data = forward_table_1.make_data([gc.DataTuple('dst_port', egress_port)],'SwitchIngress_1.ipv4_forward')
            forward_table_1.entry_add(target, [key], [data])

            i += 1
        

