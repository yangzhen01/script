#!/bin/bash

declare -A a

Network_Hostname="$1"
FILENAME="router_status.txt"
SORT_FILE="router_status_sort_by_status.txt"

if [[ "${Network_Hostname}" == "" ]]; then
    echo "Usage: $0 network_node__hostname"
    exit 1
fi

if [[ -e ./$FILENAME ]]; then
    >./$FILENAME
fi


L3_UUID=$(openstack network agent list | grep $Network_Hostname | grep l3 | awk '{print $2}' | xargs)

router_list=($(neutron router-list-on-l3-agent $L3_UUID | grep snat | awk '{print $2}'))

for router in "${router_list[@]}"; do
    tenant_uuid=$(openstack router show $router | grep project_id | awk '{print $4}')
    neutron l3-agent-list-hosting-router $router | grep -E 'standby|active' | awk '{print $4 "\t" $10}' | \
    while read line status; do 
        a[$line]=$status
        if [[ "$line" == "$Network_Hostname" ]]; then
            echo "$tenant_uuid $router ${a[$line]}" | tee -a ./$FILENAME
            break
        fi
    done
done

cat ./$FILENAME | sort -t" " -k3 > ./$SORT_FILE