#!/bin/bash


other_compute_node_ip="10.134.208.15"
compute_node_local_ip="192.168.1.103"
compute_node_vxlan_ip="192.168.3.103"
ovs_br="br-v20"
bond_vlan_interface="bond0.20"

nova_conf_path="/etc/nova/nova.conf"
neutron_conf_path="/etc/neutron/neutron.conf"
neutron_ml2_directory_path="/etc/neutron/plugins/ml2"
ml2_conf_path="$neutron_ml2_directory_path/ml2_conf.ini"
openvswitch_agent_path="$neutron_ml2_directory_path/openvswitch_agent.ini"
libvirtd_conf_path="/etc/libvirt/libvirtd.conf"
libvirtd_path="/etc/sysconfig/libvirtd"
ceph_path="/etc/ceph"
secret_xml="/root/secret.xml"
ceph_cinder_keyring="/etc/ceph/ceph.client.cinder.keyring"
ssh_user_nova="/var/lib/nova"
ceilometer_path="/etc/ceilometer/ceilometer.conf"

#----------------install and configure nova service------------------------
yum -y install openstack-nova-compute sysfsutils

scp $other_compute_node_ip:$nova_conf_path $nova_conf_path
chown root.nova $nova_conf_path
sed -i "s/vncserver_proxyclient_address.*/vncserver_proxyclient_address=$compute_node_local_ip/g" $nova_conf_path
#--------------------------------------------------------------------------

#-------start nova service-------
systemctl enable libvirtd.service openstack-nova-compute.service
systemctl start libvirtd.service openstack-nova-compute.service
#-------------------------------


#----------------install and configure neutron service---------------------
yum install openstack-neutron openstack-neutron-ml2 openstack-neutron-openvswitch

scp $other_compute_node_ip:$neutron_conf_path $neutron_conf_path
chown root.neutron $neutron_conf_path
scp $other_compute_node_ip:$ml2_conf_path $ml2_conf_path
chown root.neutron $ml2_conf_path
scp $other_compute_node_ip:$openvswitch_agent_path $openvswitch_agent_path
sed -i "s/local_ip.*/local_ip\ =$compute_node_vxlan_ip/g" $openvswitch_agent_path
chown root.neutron $openvswitch_agent_path
ln -s $neutron_ml2_directory_path/ml2_conf.ini /etc/neutron/plugin.ini

systemctl restart openvswitch.service
ovs-vsctl add-br $ovs_br
ovs-vsctl add-port $ovs_br $bond_vlan_interface
ifup $ovs_br
ifup $bond_vlan_interface
#--------------------------------------------------------------------------


#----------------start neutron service------------------------
#systemctl restart network
systemctl restart openstack-nova-compute.service
systemctl restart openvswitch.service
systemctl enable neutron-openvswitch-agent.service
systemctl start  neutron-openvswitch-agent.service
#-------------------------------------------------------------

#---------------configure libvirtd----------------------------
scp $other_compute_node_ip:$libvirtd_conf_path $libvirtd_conf_path
uid=`uuidgen`
sed -i "s/host_uuid.*/host_uuid\ =\ \"$uid\"/" $libvirtd_conf_path
scp $other_compute_node_ip:$libvirtd_path $libvirtd_path

#---------------start libvirtd service------------------------
systemctl restart libvirtd.service
#-------------------------------------------------------------

#---------------configure kvm--------------------------------
scp -r $other_compute_node_ip:$ceph_path /etc
scp $other_compute_node_ip:$secret_xml $secret_xml
virsh secret-define --file $secret_xml
UUID=`cat $secret_xml | grep uuid | cut -c 7-42`
key=`cat $ceph_cinder_keyring | grep key | awk '{print $3}'`
virsh secret-set-value --secret $UUID --base64 $key 
#------------------------------------------------------------

#---------------restart service----------------------
systemctl restart libvirtd.service
systemctl restart openstack-nova-compute.service
#----------------------------------------------------

#---------------VM Live Migration-------------------
usermod -s /bin/bash nova
mkdir -p $ssh_user_nova/.ssh
scp -r $other_compute_node_ip:$ssh_user_nova/.ssh $ssh_user_nova
chown -R nova:nova $ssh_user_nova/.ssh
#---------------------------------------------------

#--------------install and configure ceilometer---------
yum install  openstack-ceilometer-compute  python-ceilometerclient  python-pecan

scp $other_compute_node_ip:$ceilometer_path $ceilometer_path
chown root.ceilometer $ceilometer_path
#---------------------------------------------------------

#--------------start ceilometer service-------------------
systemctl enable openstack-ceilometer-compute.service
systemctl start openstack-ceilometer-compute.service
systemctl restart openstack-nova-compute.service
#---------------------------------------------------------
