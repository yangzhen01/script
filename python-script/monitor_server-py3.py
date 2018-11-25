from __future__ import print_function
import time
import psutil
import datetime
from collections import Counter

def cpu_Info():
    logical_cpu_cnt = psutil.cpu_count()
    physical_cpu_cnt = psutil.cpu_count(logical=False)
    total_cpus_usage_avg = psutil.cpu_percent(interval=3)
    user_time_cpu_perccent = psutil.cpu_times_percent().user
    return dict(log_cpu_counts=logical_cpu_cnt, phy_cpu_count=physical_cpu_cnt, cpu_usages_percent=total_cpus_usage_avg, user_cpu_percent=user_time_cpu_perccent)


def bytes2readable(n):
    sysmbols = ['K', 'M', 'G', 'T', 'P']
    prefix = {}
    for i, unit in enumerate(sysmbols):
        prefix[unit] = 1 << (i + 1) * 10
    for key in reversed(sysmbols):
        if n >= prefix[key]:
            value = n / prefix[key]
            return str('{:.2f}'.format(value)) + key
        elif (n < 1024 or n == 0):
            return str(n) + 'B'

def memory_Swap_Info():
    memory_info = psutil.virtual_memory()
    mem_total = bytes2readable(memory_info.total)
    mem_used = bytes2readable(memory_info.used)
    mem_free = bytes2readable(memory_info.free)
    used_percent_memory = memory_info.percent
   
    swap_info = psutil.swap_memory()
    swap_total = bytes2readable(swap_info.total)
    swap_used = bytes2readable(swap_info.used)
    swap_free = bytes2readable(swap_info.free)
    used_swap_percent = swap_info.percent
    return dict(memory_total=mem_total, memory_used=mem_used, memory_free=mem_free, used_percent_mem=used_percent_memory, swap_space_total=swap_total, swap_space_used=swap_used, swap_space_free=swap_free, used_swap_space_percent=used_swap_percent)

def disk_Partitions():
    partition_list = psutil.disk_partitions()
    for partition in partition_list:
        yield dict(partition_dev=partition.device, partition_mount=partition.mountpoint, partition_fstype=partition.fstype)

def disk_Usage():
    '''
    specify root partitions
    '''
    disk_info = psutil.disk_usage('/')
    disk_root_total = bytes2readable(disk_info.total)
    disk_root_used = bytes2readable(disk_info.used)
    disk_root_free = bytes2readable(disk_info.free)
    disk_root_usage_percent = disk_info.percent
    return dict(root_total=disk_root_total, root_used=disk_root_used, root_free=disk_root_free, root_usage_percent=disk_root_usage_percent)

def disk_IO_Counters():
    io_counters = psutil.disk_io_counters(perdisk=True)   
    disk = io_counters.keys()
    for item in disk:
        yield dict(devname=item, read_cnts=io_counters[item].read_count, write_cnts=io_counters[item].write_count, read_bys=bytes2readable(io_counters[item].read_bytes), write_bys=bytes2readable(io_counters[item].write_bytes))
        
def net_IO_Counters():
    net_info = psutil.net_io_counters(pernic=True)
    netcard = net_info.keys()
    for ntcard in netcard:
        if ntcard != 'lo':
            yield dict(card=ntcard, bys_send=bytes2readable(net_info[ntcard].bytes_sent), bys_recv=bytes2readable(net_info[ntcard].bytes_recv), pkts_sent_counts=net_info[ntcard].packets_sent, pkts_recv_counts=net_info[ntcard].packets_recv, drop_pakts=net_info[ntcard].dropin)

        else:
            pass

def net_Connections():
    cnt = Counter()
    conn = psutil.net_connections()
    for cn in conn:
        if cn.raddr and cn.status == 'ESTABLISHED':
            cnt[cn.raddr[0]] += 1
        else:
            pass
    return dict(cnt.most_common())

def log_User_Info():
    users = psutil.users()
    for user in users:
        yield dict(log_user=user.name, log_host=user.host, log_beging_time=time.asctime(time.localtime(user.started)))


def main():
    print()
    print('------------login information------------')
    for user in log_User_Info():
        print('log user:', user['log_user'], '|', 'log host:', user['log_host'], '|', 'log time begin:', user['log_beging_time'])
    print('\n')

    cpu_info = cpu_Info()
    print('-------------cpu information---------------')
    print('physical cpu counts: ', cpu_info['phy_cpu_count'])
    print('logical cpu counts: ', cpu_info['log_cpu_counts'])
    print('usage percent of cpu: ', cpu_info['cpu_usages_percent'])
    print('usage time percent of user program: ', cpu_info['user_cpu_percent'])
    print('\n')

    mem_swap = memory_Swap_Info() 
    print('------------member infomation--------------')
    print('memory total: ', mem_swap['memory_total'])
    print('memory used:', mem_swap['memory_used'])
    print('memory free: ', mem_swap['memory_free'])
    print('usage percert of memory: ', mem_swap['used_percent_mem'])
    print('swap total: ', mem_swap['swap_space_total']) 
    print('swap used: ', mem_swap['swap_space_used'])
    print('swap free: ', mem_swap['swap_space_free'])
    print('usage percent of swap: ', mem_swap['used_swap_space_percent'])
    print('\n')

    print('------------mountpoint information-------------')
    for disk in disk_Partitions():
        print('partiton_dev:', disk['partition_dev'].split('/')[-1], '|', 'partition_mount:',format(disk['partition_mount']), '|', 'partition_fstype:',disk['partition_fstype'])
    print('\n')

    print('------------root partitions information-------------------')
    disk_usage = disk_Usage()
    print('root_total:', disk_usage['root_total'], 'root_used:', disk_usage['root_used'], 'root_usage_percent:', disk_usage['root_usage_percent'])
    print('\n')

    print('------------disk I/O information-------------- ')
    for disk_io in disk_IO_Counters():
       print('devicename:', disk_io['devname'], '|', 'read_counts:', disk_io['read_cnts'], '|',  'write_counts:', disk_io['write_cnts'], '|',  'read_bytes:', disk_io['read_bys'], '|', 'write_bytes:', disk_io['write_bys']) 
    print('\n')
 
    print('------------network sent/rcv information-------------')
    for net_io in net_IO_Counters():
       print('netcard:', net_io['card'], '|', 'send bytes:', net_io['bys_send'], '|', 'receive bytes:', net_io['bys_recv'], '|', 'package sent counts:', net_io['pkts_sent_counts'], '|', 'package receive counts:', net_io['pkts_recv_counts']) 
    print('\n')
       
    print('-----------link information------------')
    net_link = net_Connections()
    print('connection counts ranked 3... ')
    for ip, cnt in net_link.items():
        print('ip:', ip, '|', 'counts:', cnt)

if __name__ == '__main__':
    main()
