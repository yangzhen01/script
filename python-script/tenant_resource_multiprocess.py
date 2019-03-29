# coding: utf-8
#----------------------------
#Date: 2019-03-29
#Author: 杨震
#----------------------------
import os
import commands
from multiprocessing import Pool
import time 
from prettytable import PrettyTable

def get_volumes():
    vol_size_total = 0
    vol_counts = 0

    res = commands.getoutput("openstack volume list --all | grep -E 'in-use|available' | awk -F'|' '{print $5}' |xargs")

    vol_size_list = res.split(' ')
    vol_counts = len(vol_size_list)
    for i in vol_size_list:
        vol_size_total += int(i)

    return vol_size_total, vol_counts

def get_hypervisor_id():
    hy_id = commands.getoutput("nova hypervisor-list | grep -i compute | awk '{print $2}' | xargs")
    hypervisor_id = hy_id.split(' ')
    return hypervisor_id

def get_vms_vcpus_mem(host_id):
    mem_MB, vms, vcpus = commands.getoutput("nova hypervisor-show  %s | grep -iE 'memory_mb_used|running_vms|vcpus_used' \
                                             | sort -k2 | awk -F'|' '{print $3}' | xargs" % host_id).split(' ')
    mem = (int(mem_MB) - 57344) / 1024
    return int(vms), int(vcpus), mem
    
def vms_vcpus_mem_count(hypervisor_id):
    res = []
    vms_count = []
    vcpus_counts = []
    mem_total = []
    pool = Pool(40)
    for host_id in hypervisor_id:
        res.append(pool.apply_async(get_vms_vcpus_mem, args=(host_id,)))
    
    pool.close()
    pool.join()
    for i in res:
        vms_count.append(i.get()[0])
        vcpus_counts.append(i.get()[1])
        mem_total.append(i.get()[2])
    return sum(vms_count), sum(vcpus_counts), sum(mem_total)

def vms_count():
    return commands.getoutput("openstack server list --all | grep -iE 'active|shutoff' | wc -l")

os.environ['OS_PROJECT_DOMAIN_NAME']='default'
os.environ['OS_USER_DOMAIN_NAME']='default'
os.environ['OS_PROJECT_NAME']='admin'
os.environ['OS_USERNAME']='admin'
os.environ['OS_PASSWORD']='ADMIN_PASS'
os.environ['OS_AUTH_URL']='http://keystone-admin.cty.os:10006/v3'
os.environ['OS_IDENTITY_API_VERSION']='3'
os.environ['OS_IMAGE_API_VERSION']='2'

if __name__ == '__main__':
    start = time.time()

    tbl = PrettyTable(['虚机总数量', 'vcpu总数量', '内存总用量(G)', '卷总容量(G)', '卷总数量'])

    vol_size_total, vol_counts = get_volumes()
    vms, vcpus_count, mem_total = vms_vcpus_mem_count(get_hypervisor_id())
    tbl.add_row([vms, vcpus_count, mem_total, vol_size_total, vol_counts])
    
    print(tbl)
    print('耗时 %s' % round((time.time()-start), 2))
