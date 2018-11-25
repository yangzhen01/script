# -*- coding: UTF-8 -*-
from __future__ import print_function
import os
import sys
import time
import subprocess

def execute_CMD(cmd):
    p = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    stdout, stderr = p.communicate()
    if p.returncode != 0:
        return p.returncode, stderr
    else:
        return p.returncode, stdout


if __name__ == '__main__':
    backup_dir = '/home/backup/'
    backup_time = time.strftime('%Y%m%d%H%M%S', time.localtime())
    backup_subdir = backup_dir + 'mariadb_backup_' + backup_time

    if not os.path.exists(backup_subdir):
        os.makedirs(backup_subdir)
    else:
        pass

    backup_cmd = 'xtrabackup --defaults-file=/etc/my.cnf.d/server.cnf --backup --target-dir=' + backup_subdir + ' --datadir=/var/lib/mysql --user root --password foxconn --host=127.0.0.1'
    output = execute_CMD(backup_cmd)

    prepare_cmd = 'xtrabackup --defaults-file=/etc/my.cnf.d/server.cnf --prepare --target-dir=' + backup_subdir + ' --datadir=/var/lib/mysql --user root --password foxconn --host=127.0.0.1'
    output = execute_CMD(prepare_cmd)

    compress_cmd = 'tar -czf ' + backup_subdir  + '.tar.gz ' +  backup_subdir
    output = execute_CMD(compress_cmd)
     
    dir_list = 'find ' + backup_dir + ' -maxdepth 1 -type d  -name "mariadb_backup*" -mtime +2'
    returncode, mariadb_dir = execute_CMD(dir_list)
    if returncode == 0 and mariadb_dir:
        #for dirname in (mariadb_dir.decode().split('\n')[:-1]):
        for dirname in mariadb_dir.split():
            delete_dir_cmd = 'rm -rf ' + dirname
            subreturn = execute_CMD(delete_dir_cmd)
    else:
        pass

    file_list = 'find ' + backup_dir + ' -maxdepth 1 -type f  -name "*tar.gz" -mtime +2'
    returncode, mariadb_file = execute_CMD(file_list)
    if returncode == 0 and mariadb_file:
    #    for backup_file in (mariadb_file.decode().split('\n')[:-1]):
        for backup_file in mariadb_file.split():
            delete_file_cmd = 'rm -f ' + backup_file
            subreturn = execute_CMD(delete_file_cmd)
    else:
        pass

