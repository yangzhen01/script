# coding: utf-8
# Author: Erick
# Date: 2018-12-19

import os
import commands
import json
import sys
import threading
from prettytable import PrettyTable


def get_flavors(project):
    flavors_list = []
    res = commands.getoutput('openstack server list -f json --project %s' % project)

    j_res = json.loads(res)

    for i in j_res:
        flavors_list.append(i['Flavor'].encode('utf8'))

    vm_count = len(flavors_list)
    return flavors_list, vm_count

def flavor_count(flavors_list):
    flavor_count_dic = {}

    for f in flavors_list:
        flavor_count_dic[f] = flavors_list.count(f)

    return flavor_count_dic

def get_resources(flavor_count_dic):
    t_list = []
    vcpus = {}
    ram = {}

    def get_flavor_info(vcpus, ram, flavor):
        res = commands.getoutput('openstack flavor show %s -f json' % flavor)
        j_res = json.loads(res)
        vcpus[flavor] = j_res['vcpus']
        ram[flavor] = j_res['ram']

    for flavor in flavor_count_dic.keys():
        thread1 = threading.Thread(target=get_flavor_info, args=(vcpus, ram, flavor))
        t_list.append(thread1)
        thread1.start()

    for t in t_list:
        t.join()

    return vcpus, ram

def get_flavor_info(vcpus, ram, flavor):
    res = commands.getoutput('openstack flavor show %s -f json' % flavor)
    j_res = json.loads(res)
    vcpus[flavor] = j_res['vcpus']
    ram[flavor] = j_res['ram']

def cal_sum(resource_dic, flavor_count_dic):
    total = 0

    for flavor in resource_dic.keys():
        resource_count = resource_dic[flavor] * flavor_count_dic[flavor]
        total += resource_count

    return total

def get_volumes(project):
    vol_size = []
    res = commands.getoutput('openstack volume list -f json --project %s' % project)
    j_res = json.loads(res)

    try:
        for i in j_res:
            vol_size.append(i['Size'])
    except KeyError:
        print("\033[1;31mThere is no volumes!\033[0m")
        sys.exit(1)

    total_size = sum(vol_size)
    vol_count = len(vol_size)
    return total_size, vol_count

def get_projects():
    projects = []
    res = commands.getoutput('openstack project list -f json')

    try:
        j_res = json.loads(res)
    except ValueError:
        print("\033[1;31mPlease source rc file first.\033[m")
        sys.exit(1)

    for i in j_res:
        #projects.append(i['ID'].encode('utf8'))
        projects.append(i['Name'].encode('utf8'))

    return projects

def main(proName=None):
    os.system('source /root/admin-openrc.sh')
    Vm_count = []
    Total_cpu_counts = []
    Total_ram_counts = []
    Vol_total_size = [] 
    Vol_count = []
    t2_list = []
    projects = get_projects()
    #if project in projects:
    #    flavors_list, vm_count = get_flavors(project)
    #else:
    #    print("\033[1;31mThere is no project: %s\033[0m" % project)
    #    sys.exit(1)
    if  proName:
        pro_tbl = PrettyTable(['项目名','虚机数量', 'vcpu总数量', '内存总用量(G)', '卷总容量(G)', '卷数量'])

    def fetchinfo(project):    
        flavors_list, vm_count = get_flavors(project)
        if flavors_list:
            flavor_count_dic = flavor_count(flavors_list)
            vcpus, ram = get_resources(flavor_count_dic)
            total_cpu_counts = cal_sum(vcpus, flavor_count_dic)
            total_ram_counts = cal_sum(ram, flavor_count_dic) / 1024
        else:
            vm_count = total_cpu_counts = total_ram_counts = 0
      
        vol_total_size, vol_count = get_volumes(project)
        if project in proName:
            pro_tbl.add_row([project, vm_count, total_cpu_counts, total_ram_counts, vol_total_size, vol_count])

        Vm_count.append(vm_count)
        Total_cpu_counts.append(total_cpu_counts)
        Total_ram_counts.append(total_ram_counts)
        Vol_total_size.append(vol_total_size)
        Vol_count.append(vol_count)

    for project in projects:
        thread2 = threading.Thread(target=fetchinfo,args=(project,))
        t2_list.append(thread2)
        thread2.start()

    for t2 in t2_list:
        t2.join()
        #flavors_list, vm_count = get_flavors(project)
        #if flavors_list:
        #    flavor_count_dic = flavor_count(flavors_list)
        #    vcpus, ram = get_resources(flavor_count_dic)
        #    total_cpu_counts = cal_sum(vcpus, flavor_count_dic)
        #    total_ram_counts = cal_sum(ram, flavor_count_dic) / 1024
        #else:
        #    vm_count = total_cpu_counts = total_ram_counts = 0

        #vol_total_size, vol_count = get_volumes(project)

        #pro_tbl.add_row([project, vm_count, total_cpu_counts, total_ram_counts, vol_total_size, vol_count])

        #Vm_count += vm_count
        #Total_cpu_counts += total_cpu_counts
        #Total_ram_counts += total_ram_counts
        #Vol_total_size += vol_total_size
        #Vol_count += vol_count

    print(pro_tbl)

    tbl = PrettyTable(['虚机总数量', 'vcpu总数量', '内存总用量(G)', '卷总容量(G)', '卷总数量'])
    #tbl.add_row([vm_count, total_cpu_counts, total_ram_counts, vol_total_size, vol_count])
    tbl.add_row([sum(Vm_count), sum(Total_cpu_counts), sum(Total_ram_counts), sum(Vol_total_size), sum(Vol_count)])

    print(tbl)

#def Usage():
#    prompt = """\033[1;34mUsage:
#    python %s <project_id>\033[0m""" % sys.argv[0]
#    print(prompt)

def Usage():
    prompt = """\033[1;34mUsage: python %s [PROJECT_ID]
                
       If you only print total resources of projects, please set PRJECT_ID empty.
       Besides printing total resources of projects, if you will to print specify projects, you should
       set PROJECT_ID, the argument can be multiple value separated by commas.\033[0m""" % sys.argv[0]
    print(prompt)

if __name__ == '__main__':
    #try:
    #    response = sys.argv[1]
    #except IndexError:
    #    Usage()
    #    sys.exit(1)
    #main(response)

    if sys.argv[1] == '-h' or sys.argv[1] == '--help':
       Usage()
       sys.exit(1)
    response = sys.argv[1:]
    print "Taking a while,please wait..."
    main(response)
