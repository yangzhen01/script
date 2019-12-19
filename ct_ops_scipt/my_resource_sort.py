# coding: utf-8
#!/usr/bin/python
from __future__ import print_function
import os
import sys
import time
import argparse
import warnings
from  commands import getoutput
from ConfigParser import RawConfigParser

from keystoneauth1 import identity
from keystoneauth1 import session
from neutronclient.v2_0 import client as network_client

from cinderclient import client

from prettytable import PrettyTable

import nova.conf
from nova import context
from nova import objects
from nova import config
from nova import availability_zones
from nova import compute
from nova import servicegroup
from ipaddress import IPv4Address

warnings.filterwarnings("ignore")
CONF = nova.conf.CONF

color_tbl = {
    "grey": '\033[1;30m',
    "green": '\033[32m',
    "blue": '\033[34m',
    "yellow": '\033[33m',
    "red": '\033[31m',
}
summary = {
    "vm_total": 0,
    "ram_used": 0,
    "cpu_total": 0,
    "cpu_used": 0,
    "ram_total": 0,
    "host_num": 0,
    "volume_count": 0,
    "volume_size": 0,
    "floatingip_total": 0,
    "floatingip_used": 0,
    "vm_remain": 0,
    "max_instances": 0,
    "max_vm_per_host": 0,
    "vrouter_total": 0,
    "vrouter_max_total": 0,
    "l3_total": 0
}

'''
As follows max_l3_agents_per_router  indicates the accounts of router on per l3 agent. Getting the value from 'field max_l3_agents_per_router'
in neutron node /etc/neutron/neutron.conf file '''
max_l3_agents_per_router = 2

max_router_per_agent = 80

config.parse_args([])
ctx = context.get_admin_context()
objects.register_all()
host_api = compute.HostAPI()
servicegroup_api = servicegroup.API()

parser = argparse.ArgumentParser(prog=os.path.basename(sys.argv[0]),
                                 description="This program can get "
                                             "resource usage.")

parser.add_argument('-z',
                    action="store",
                    help='Available zone')


def colorizer(num):
    if num <= 20:
        return "%s%.2f%%\033[0m" % (color_tbl['grey'], num)
    if num <= 40:
        return "%s%.2f%%\033[0m" % (color_tbl['green'], num)
    if num <= 60:
        return "%s%.2f%%\033[0m" % (color_tbl['blue'], num)
    if num <= 80:
        return "%s%.2f%%\033[0m" % (color_tbl['yellow'], num)
    return "%s%.2f%%\033[0m" % (color_tbl['red'], num)


def get_available_zones(zone_names=None, include_internal=False):

    def filter_availability_zones(zones):
        result = []
        for zone in zones:
            if zone[0] == CONF.internal_service_availability_zone:
                continue
            result.append(zone)
        return result

    available_zones, not_available_zones = \
        availability_zones.get_availability_zones(ctx, with_hosts=True)

    if include_internal:
        all_available_zones = available_zones + not_available_zones
    else:

        filtered_available_zones = \
            filter_availability_zones(available_zones)
        filtered_not_available_zones = \
            filter_availability_zones(not_available_zones)

        all_available_zones = filtered_available_zones + \
                              filtered_not_available_zones

    if zone_names:
        if not isinstance(zone_names, (list, tuple)):
            zone_names = [zone_names]

        all_available_zones = [az for az in all_available_zones
                               if az[0] in zone_names]

    return all_available_zones


def add_host_to_table(host, tb_list, zone):
    volume = getoutput("cinder --os-volume-api-version 3.33 list --filters host=%s --all | grep -E 'in-use|available' | awk -F'|' '{print $6}' | xargs" % host.host)
    if volume == "":
        vol_nums = 0
        vol_size = 0
    else:
        vol = [int(i) for i in volume.strip().split(' ')]
        vol_nums = len(vol)
        vol_size = sum(vol)
    vm = host.running_vms
    cpu = str(host.vcpus_used) + "/" + \
          str(int(host.vcpus * host.cpu_allocation_ratio))
    cpu_ratio = host.vcpus_used * 100.0 / (host.vcpus * host.cpu_allocation_ratio)

    ram = str(host.memory_mb_used) + "/" + str(host.memory_mb)
    
    ram_used = host.memory_mb_used
    
    ram_ratio = colorizer(host.memory_mb_used * 100.0 / (host.memory_mb * host.ram_allocation_ratio))

    service = host_api.service_get_by_compute_host(ctx, host.host)

    status = 'disabled' if service.disabled else 'enabled'
    status = "%s%s\033[0m" % (
    color_tbl['red'], status) if status != "enabled" else status

    alive = servicegroup_api.service_is_up(service)

    state = 'up' if alive else 'down'
    state = "%s%s\033[0m" % (
    color_tbl['red'], state) if state != "up" else state
        
    tb_list.append([host.host, host.host_ip, status, state, cpu,
                    cpu_ratio, ram, ram_ratio, zone, vm, vol_nums, vol_size])

    summary['vm_total'] += vm
    summary['ram_used'] += ram_used
    summary["cpu_total"] += host.vcpus * host.cpu_allocation_ratio
    summary["cpu_used"] += host.vcpus_used
    summary["ram_total"] += (host.memory_mb * host.ram_allocation_ratio)
    summary["host_num"] += 1

def print_summary(table):
    def getSubnetIp():
        ip_total = 0
        subnet_uuid = getoutput("openstack subnet list --network ext-net -c ID -c Name -f value | grep -v fip-agent-sub | awk '{print $1}' | xargs")
        for uuid in subnet_uuid.split(' '):
            ip_range = getoutput('openstack subnet show %s -c  allocation_pools -f value' % uuid)
            if ',' not in ip_range:
                ip = ip_range.split('-')
                start = int(IPv4Address(ip[0].decode('utf-8')))
                end = int(IPv4Address(ip[1].decode('utf-8')))
                ip_total += (end - start + 1)
            else:
                IP_range = ip_range.split(',')
                for ip_list in IP_range:
                    ip = ip_list.split('-')
                    start = int(IPv4Address(ip[0].decode('utf-8')))
                    end = int(IPv4Address(ip[1].decode('utf-8')))
                    ip_total += (end - start + 1)
        return ip_total
    public_ip = getSubnetIp()
    table.add_row([int(summary['cpu_total']), str(summary['cpu_used']) + '/' + str(int(summary['cpu_total']-summary['cpu_used'])), int(summary['ram_total'] / 1024), \
                 str(summary['ram_used'] / 1024) + '/' + str(int((summary['ram_total'] - summary['ram_used']) / 1024)), str(summary['volume_count']) + '/' + \
                 str(summary['volume_size']),  public_ip, str(summary['floatingip_used']) + '/' + str(public_ip - summary['floatingip_used']), \
                 summary['max_instances'], str(summary['vm_total']) + '/' + str(summary['vm_remain']), summary['l3_total'] * max_router_per_agent, \
                 str(summary['vrouter_total']) + '/' + str(summary['l3_total'] * max_router_per_agent -  summary['vrouter_total']), summary['host_num']])

def get_router():
    summary['router_total'] = int(getoutput('openstack router list -c ID -f value | wc -l'))

def get_l3_agent():
    summary['l3_total'] = int(getoutput('openstack network agent list -c Host -c Binary -f value | grep network | grep l3 | wc -l'))

def get_volume():
    volume = client.Client(2, os.getenv('OS_USERNAME'), os.getenv('OS_PASSWORD'), os.getenv('OS_PROJECT_NAME'), os.getenv('OS_AUTH_URL'))
    for vol in volume.volumes.list(search_opts = {'all_tenants': 1}):
        yield vol


def get_neutronclient():
    username = os.environ['OS_USERNAME']
    password = os.getenv('OS_PASSWORD')
    project_name = os.environ['OS_PROJECT_NAME']
    project_domain_id = os.environ['OS_PROJECT_DOMAIN_NAME']
    user_domain_id = os.environ['OS_USER_DOMAIN_NAME']
    auth_url = os.getenv('OS_AUTH_URL')
    auth = identity.Password(auth_url=auth_url,username=username,password=password,project_name=project_name,project_domain_id=project_domain_id,user_domain_id=user_domain_id)
    sess = session.Session(auth=auth)
    return network_client.Client(session=sess, username=username, password=password, project_name=project_name, auth_url=auth_url)

def get_floatingip():
    neutron = get_neutronclient()
    summary['floatingip_used'] += len(neutron.list_floatingips()['floatingips'])


def get_vm_remain():
    config = RawConfigParser()
    config.read('/etc/nova/nova.conf')
    summary['max_vm_per_host'] = int(config.get('filter_scheduler', 'max_instances_per_host'))
    summary['max_instances'] = summary['host_num'] * summary['max_vm_per_host']
    summary['vm_remain'] = summary['max_instances'] - summary['vm_total'] 

def get_vrouter():
    summary['vrouter_total'] = int(getoutput('openstack router list  -c ID -f value | wc -l'))

def main():
    if os.path.exists('/root/admin-openrc.sh'):
        secret = getoutput("cat /root/admin-openrc.sh | grep OS_PASSWORD | awk -F'=' '{print $2}'")
    else:
        print("rc file not exit!")
        sys.exit(1)

    os.environ['OS_USERNAME'] = 'admin'
    os.environ['OS_PASSWORD'] = secret
    os.environ['OS_PROJECT_NAME'] = 'admin'
    os.environ['OS_AUTH_URL'] = 'http://keystone-admin.cty.os:10006/v3'
    os.environ['OS_PROJECT_DOMAIN_NAME'] = 'default'
    os.environ['OS_USER_DOMAIN_NAME'] = 'default'
    os.environ['OS_IDENTITY_API_VERSION'] = '3'
    os.environ['OS_IMAGE_API_VERSION'] = '2'
 
    for volume in get_volume():
        summary['volume_count'] += 1
        summary['volume_size'] += volume.size

    args = parser.parse_args()

    tbl = PrettyTable(
        ["hostname", "ip", "status", "state", "cpu", "cpu_ratio", "ram",
         "ram_ratio", "zone", "vm", "volumes", "vol_size"])
    tbl.align['hostname'] = 'l'
    tbl.align['ip'] = 'l'

    available_zones = get_available_zones(args.z)
    if not available_zones:
        print("There no available zones")
        sys.exit(0)

    for zone in available_zones:
        hosts_in_zone = zone[1]
        tb_list = []
        for host in hosts_in_zone:
            computes = objects.ComputeNodeList.get_all_by_host(ctx, host, False)
            for compute in computes:
                add_host_to_table(compute, tb_list, zone[0])
        std_tb_list = sorted(tb_list, key=lambda x: x[5], reverse = True)
        for key in range(len(std_tb_list)):
            std_tb_list[key][5] = colorizer(std_tb_list[key][5])
        for info in std_tb_list:
            tbl.add_row(info)

    print(tbl)

    get_vm_remain()
    get_floatingip()
    get_vrouter()
    get_l3_agent()
   
    table = PrettyTable(["CPU总量", "CPU已用/剩余", "内存总量(G)", "内存已用/剩余(G)", "卷数量/卷总容量(G)", \
                        "公网IP总量", "公网IP已用/剩余", "可建虚机总量", "已建虚机数量/剩余","可建路由总量", "已建Vrouter数量/剩余", "节点总数"])
    print_summary(table)
    print(table)
   
    if summary['vrouter_total'] * max_l3_agents_per_router >= summary['l3_total'] * max_router_per_agent:
       print("Please expand the network node!")
    else:
       pass


if __name__ == '__main__':
    start = time.time()
    main()
    print("耗时 %ss" % round((time.time()-start), 2))
