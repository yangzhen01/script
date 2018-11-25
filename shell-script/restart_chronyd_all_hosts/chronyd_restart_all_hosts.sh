#!/bin/bash

while read ip;  do
      ssh $ip systemctl restart chronyd
      sleep 1
done < host_ip.txt
