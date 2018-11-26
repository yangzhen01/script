#!/bin/bash

while read ip; do
     scp /etc/hosts $ip:/etc/hosts
     #echo $ip
done < host_ip.txt
