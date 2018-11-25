#!/bin/bash
#--------------------------------------------
#Note:before operation we had better trush other host passing ssh command
#--------------------------------------------
set -e 

ori_network_node_ip=""

neutron_file_path="/etc/neutron/neutron.conf"
scp $ori_network_node_ip:$neutron_file_path $neutron_file_path
chown root.neutron $neutron_file_path

ml2_conf_path="/etc/neutron/plugins/ml2/ml2_conf.ini"
scp $ori_network_node_ip:$ml2_conf_path $ml2_conf_path
chown root.neutron $ml2_conf_path

openvswitch_agent_file="/etc/neutron/plugins/ml2/openvswitch_agent.ini"
scp $ori_network_node_ip:$openvswitch_agent_file $openvswitch_agent_file
chown root.neutron $openvswitch_agent_file

l3_agent_file="/etc/neutron/l3_agent.ini"
scp $ori_network_node_ip:$l3_agent_file $l3_agent_file
chown root.neutron $l3_agent_file

dhcp_agent_path="/etc/neutron/dhcp_agent.ini" 
scp $ori_network_node_ip:$dhcp_agent_path $dhcp_agent_path
chown root.neutron $dhcp_agent_path

dnsmasq_file_path="/etc/neutron/dnsmasq-neutron.conf"
scp $ori_network_node_ip:$dnsmasq_file_path $dnsmasq_file_path
chown root.neutron $dnsmasq_file_path

metadata_agent_file_path="/etc/neutron/metadata_agent.ini"
scp $ori_network_node_ip:$metadata_agent_file_path $metadata_agent_file_path
chown root.neutron $metadata_agent_file_path

lbaas_agent_file_path="/etc/neutron/lbaas_agent.ini"
scp $ori_network_node_ip:$lbaas_agent_file_path $lbaas_agent_file_path
chown root.neutron $lbaas_agent_file_path

neutron_lbaas_path="/etc/neutron/neutron_lbaas.conf"
scp $ori_network_node_ip:$neutron_lbaas_path $neutron_lbaas_path
chown root.neutron $neutron_lbaas_path
