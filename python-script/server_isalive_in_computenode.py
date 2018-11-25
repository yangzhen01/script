
from __future__ import print_function
import os
import sys
import re
import argparse
import subprocess 
from collections import OrderedDict

def arg_Check():
    parse = argparse.ArgumentParser(description='list all server in specified host.')
    parse.add_argument('--host', metavar='hostname', action='store',dest='hostname', required=True, help='physical compute node hostname')
    parse.add_argument('-V', '--version', action='version', version='%(prog)s 0.1')
    return parse.parse_args()

def process_Cmd(Cmd, outfile):
    print(subprocess.check_output(Cmd, shell=True), file=outfile, end='')
    
def execute_Cmd(Cmd):
    p = subprocess.Popen(Cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    p.wait()
    return p.returncode

def statistic_Cmd(Cmd):
    p = subprocess.Popen(Cmd, shell=True, stdout=subprocess.PIPE)    
    p.wait()
    stdout, stderr = p.communicate()
    return stdout

def main():
    parse = arg_Check()
    cmd = "nova list" + " --host " + parse.hostname + " --all-tenants"
    
    #list all servers into output.txt
    with open('output.txt', 'w') as f:
        process_Cmd(cmd, f)    
    with open('output.txt', 'r') as f:
        for line in f:
            print(line, end='')

    cmd_host_mem_info = "nova host-describe " + parse.hostname
    with open('host_info.txt', 'w') as f:
         process_Cmd(cmd_host_mem_info, f)

    #statistic used_mem in the compute
    pattern = re.compile(r'.*(used_now).*')
    with open('host_info.txt', 'r') as f:
        for line in f:
            suit = pattern.search(line)
            if suit:
               value = int(suit.group().split('|')[-3].strip())//1024
            else:
               pass

    cmd_total_statistic = 'grep -E "ACTIVE|SHUTOFF" output.txt | wc -l'
    print('The number of all servers in the {} is {}used_mem {}GB.'.format(parse.hostname, statistic_Cmd(cmd_total_statistic), value))

    #filter active servers and then put then into file server_active.txt
    filename = "output.txt"
    cmd_active = "grep -i active " + filename
    with open('server_active.txt', 'w') as f:
        process_Cmd(cmd_active, f)

    #output active servers into screen
    print()
    d = OrderedDict()
    with open('server_active.txt', 'r') as f:
       print("=======ACTIVE SERVER=======")
       for line in f:
           name = line.split('|')[2].strip()
           print(name,': ', end='')
           ip = line.split('|')[-2]
           ip_list = re.split(';|=| ', ip.strip())
           ip_list.sort()
           if len(ip_list) == 2:
              print(ip_list[0])
              d[name] = ip_list[:1]
           elif len(ip_list) == 5:
              print(*ip_list[1:3])
              d[name] = ip_list[1:3]
           elif len(ip_list) == 8:
              print(*ip_list[2:4])
              d[name] = ip_list[2:4]
           else:
              print("None ip address")
    cmd_active_statistic = 'cat server_active.txt | wc -l'
    count_active = statistic_Cmd(cmd_active_statistic)
    print('The number of active servers is ', count_active)

    #ping test
    print()
    IP = []
    code = []
    for item in d.keys():
        for ip in d[item]:
            cmd = "ping -c 2 " + ip
            code.append(execute_Cmd(cmd))
            IP.append(ip)
        if 0 in code:
            print(item, end=':')
            print(*IP, end=' ')
            print('is up.')
            IP = []
            code = []
        else:
            print(item, end=':')
            print(*IP, end=' ')
            print('is down!')
            IP = []
            code = []
    
if __name__ == '__main__':
    main()
