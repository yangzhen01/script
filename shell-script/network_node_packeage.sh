#!/bin/bash

set -e

echo "install pacemaker corosync haproxy psc packages"
read -p "press any key to continue..."
yum install openstack-selinux haproxy corosync pacemaker pcs
echo

echo "install neutron packages"
read -p "press any key to continue..."
yum -y install openstack-neutron openstack-neutron-ml2 openstack-neutron-openvswitch ipset python-neutron-lbaas openstack-neutron-lbaas
echo
