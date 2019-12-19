#coding: utf-8
#!/usr/bin/python

from __future__ import print_function
import os
from ipaddress import IPv4Address
from commands import getoutput

def getSubnetIp():
    ip_total = 0
    subnet_uuid = getoutput("openstack subnet list --network ext-net -c ID -c Name -f value | grep -v fip-agent-sub | awk '{print $1}' | xargs")
    for uuid in subnet_uuid.split(' '):
        ip_range = getoutput('openstack subnet show %s -c  allocation_pools -f value' % uuid)
        ip = ip_range.split('-')
        start = int(IPv4Address(ip[0].decode('utf-8')))
        end = int(IPv4Address(ip[1].decode('utf-8')))
        ip_total += (end - start + 1)
    return ip_total

def getTranportSubnetIp():
    transport_ip_used = []
    transport_ip_total = 0
    subnet_uuid = getoutput("openstack subnet list --network ext-net -c ID -c Name -f value | grep fip-agent-sub | awk '{print $1}' | xargs")
    for uuid in subnet_uuid.split(' '):
        ip_range = getoutput('openstack subnet show %s -c  allocation_pools -f value' % uuid)
        transport_ip_used.append(int(getoutput('openstack port list --fixed-ip subnet=%s | grep ip_address | wc -l' % uuid)))
        ip = ip_range.split('-')
        start = int(IPv4Address(ip[0].decode('utf-8')))
        end = int(IPv4Address(ip[1].decode('utf-8')))
        transport_ip_total += (end - start + 1)
    return transport_ip_total, sum(transport_ip_used), transport_ip_total-sum(transport_ip_used)


def main():
    os.environ['OS_USERNAME'] = 'admin'
    os.environ['OS_PASSWORD'] = 'ADMIN_PASS'
    os.environ['OS_PROJECT_NAME'] = 'admin'
    os.environ['OS_AUTH_URL'] = 'http://keystone-admin.cty.os:10006/v3'
    os.environ['OS_PROJECT_DOMAIN_NAME'] = 'default'
    os.environ['OS_USER_DOMAIN_NAME'] = 'default'
    os.environ['OS_IDENTITY_API_VERSION'] = '3'
    os.environ['OS_IMAGE_API_VERSION'] = '2'
    transport_ip_total, transport_ip_used, transport_ip_available = getTranportSubnetIp()
    print('公网IP总数: ', getSubnetIp())
    print('转发网IP总数: %d, 转发网IP已用/可用数目: %d/%d' %  (transport_ip_total, transport_ip_used, transport_ip_available))

if __name__ == '__main__':
    main()
