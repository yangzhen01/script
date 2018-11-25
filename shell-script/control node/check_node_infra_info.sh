#!/bin/bash
echo "#------------------------------------------------"
echo -e "hostname is \033[31m$(hostname)\033[0m."

echo
echo -e "selinux status is \033[31m$(getenforce)\033[0m."

echo
firewalld=$(systemctl status firewalld | grep -i active)
echo -e "firewalld status is \033[31m${firewalld:11:8}\033[0m."

echo
network_manager=$(systemctl is-active NetworkManager)
echo -e "NetworkManager status is \033[31m$network_manager\033[0m."

echo
echo -e "Kernal version is \033[31m$(uname -r)\033[0m."

echo
rpm -qa | grep '^qemu'

echo
grep "nofile 65536" /etc/security/limits.conf
echo "#------------------------------------------------"
