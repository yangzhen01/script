#!/bin/bash
#-----------------------------------------
#copy configure file from ori node to new 
#node.
#-----------------------------------------
set -e
ori_node_manage_ip="10.134.170.183"

#---------------keystone file----------------------
echo "from $ori_node_manage_ip  copy keystone.conf to local"
keystone_file_path="/etc/keystone/keystone.conf"
scp $ori_node_manage_ip:$keystone_file_path $keystone_file_path
chown root.keystone $keystone_file_path
echo

echo "from $ori_node_manage_ip  copy httpd.conf to local"
apche_file_path="/etc/httpd/conf/httpd.conf"
scp $ori_node_manage_ip:$apche_file_path $apche_file_path
echo

echo "from $ori_node_manage_ip copy wsgi-keystone.conf to local"
wsgi_keystone_path="/etc/httpd/conf.d/wsgi-keystone.conf"
scp $ori_node_manage_ip:$wsgi_keystone_path $wsgi_keystone_path
echo
#--------------------------------------------------


#---------------glance file----------------------
echo "from $ori_node_manage_ip copy glance-api.conf to local"
glance_api_path="/etc/glance/glance-api.conf"
scp $ori_node_manage_ip:$glance_api_path $glance_api_path
chown root.glance $glance_api_path
echo

echo "from $ori_node_manage_ip copy glance-registry.conf to local"
glance_registry_path="/etc/glance/glance-registry.conf"
scp $ori_node_manage_ip:$glance_registry_path $glance_registry_path
chown root.glance $glance_registry_path
echo

ceph_dir="/etc/ceph"
ceph_glance="ceph.client.glance.keyring"
ceph_cinder="ceph.client.cinder.keyring"
ceph_backup="ceph.client.cinder-backup.keyring"
scp -r $ori_node_manage_ip:$ceph_dir /etc
cd $ceph_dir 
chown glance.glance $ceph_glance 
chown cinder.cinder $ceph_cinder
chown cinder.cinder $ceph_backup
#------------------------------------------------


echo "from $ori_node_manage_ip copy nova.conf to local"
nova_path="/etc/nova/nova.conf"
scp $ori_node_manage_ip:$nova_path $nova_path
chown root.nova $nova_path
echo


#---------------neutron file----------------------
echo "from $ori_node_manage_ip copy neutron.conf to local"
neutron_path="/etc/neutron/neutron.conf"
scp $ori_node_manage_ip:$neutron_path $neutron_path
chown root.neutron $neutron_path
echo

echo "from $ori_node_manage_ip copy neutron.conf to local"
neutron_lbaas_path="/etc/neutron/neutron_lbaas.conf"
scp $ori_node_manage_ip:$neutron_lbaas_path $neutron_lbaas_path
chown root.neutron $neutron_lbaas_path
echo

echo "from $ori_node_manage_ip copy ml2_conf.ini to local" 
ml2_conf_path="/etc/neutron/plugins/ml2/ml2_conf.ini"
scp $ori_node_manage_ip:$ml2_conf_path $ml2_conf_path
chown root.neutron $ml2_conf_path
ln -s $ml2_conf_path /etc/neutron/plugin.ini
#--------------------------------------------------


#---------------dashbaord file---------------------
echo "from $ori_node_manage_ip copy local_settings to local"
local_settings="/etc/openstack-dashboard/local_settings"
scp $ori_node_manage_ip:$local_settings $local_settings
chown root.apache $local_settings
echo
#--------------------------------------------------


#---------------cinder file----------------------
echo "from $ori_node_manage_ip copy cinder.conf to local"
cinder_path="/etc/cinder/cinder.conf"
scp $ori_node_manage_ip:$cinder_path $cinder_path
chown root.cinder $cinder_path
echo

mkdir -p /home/tmp
mkdir -p /home/conversion
chown cinder:cinder /home/tmp
chown cinder:cinder /home/conversion


cinder_run_dir="/var/run/cinder"
[ -d $cinder_run_dir ] || mkdir  $cinder_run_dir
chown cinder:root $cinder_run_dir
#--------------------------------------------------


#--------------ceilometer file-------------------------------
echo "from $ori_node_manage_ip copy ceilometer.conf to local"
ceilometer_path="/etc/ceilometer/ceilometer.conf"
scp $ori_node_manage_ip:$ceilometer_path $ceilometer_path
chown root.ceilometer $ceilometer_path
echo
#------------------------------------------------------------

