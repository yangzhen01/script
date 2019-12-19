#!/bin/bash

openstack flavor list | grep -i True | awk '{print $2 " " $4}' | 
    while read uuid name; do
        if [[ "$name" =~ "openstack" ]]; then
            vcpus_mem_disk=($(echo "$name" | grep -Po "\d+"))
            mem_gb=$((${vcpus_mem_disk[1]} / 1024))
            name="${vcpus_mem_disk[0]}C${mem_gb}G"
        fi
        num=$(openstack server list --all --flavor $uuid | grep -Ei "active|shutoff|error" | wc -l)
        echo "$uuid $name: $num"
    done
