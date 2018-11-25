from __future__ import print_function
import os, sys
import re
import shutil
import subprocess
import argparse

def process_Cmd(cmd, filename):
    print(subprocess.check_output(cmd, shell=True), file=filename, end='')

def main():
    directory = '/var/lib/nova/instances/'
    filename = 'disk.config'
    cmd = 'find ' + directory + ' -type f' + ' -name ' + filename
    pattern = re.compile('<nova:name>(.*)</nova:name>')
    #patt = re.compile('<name>(*)</name>')
    with open('disk.file', 'w') as diskfile:
        process_Cmd(cmd, diskfile)

    if os.path.getsize('disk.file') != 0:
       with open('disk.file') as f:
           for line in f:
               uuid = line.split('/')[5]
               new_dir = '/home/' + uuid[:8]
               os.mkdir(new_dir)
               shutil.copy(line.strip(), new_dir)
               libvirt_path = directory + uuid + '/' + 'libvirt.xml'
               with open(libvirt_path) as f:
                    for line in f:
                        pat = pattern.search(line)
                        if pat:
                            break
                        else:
                            pass             
 
               with open(libvirt_path) as ff:
                    for l in ff:
                        pat_name = re.search(r'<name>(.*)</name>', l)
                        if pat_name:
                            break
                        else:
                            pass
               print(pat.group(1), patt_name.group(1), uuid, os.path.join(new_dir, *os.listdir(new_dir)))
if __name__ == '__main__':
    main()
