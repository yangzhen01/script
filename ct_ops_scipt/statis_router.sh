#!/bin/bash

DATE=$(date +%Y%m%d)

openstack network agent list  -c ID -c Host -c Binary -f value | grep network | grep l3 >l3_host_${DATE}.txt
 while read uuid host l3; do
     L3_UUID=$uuid
     NETWORK_HOST=$host
     ROUTER_NUM=$(openstack router list --agent $L3_UUID | grep True | wc -l)
     echo "$NETWORK_HOST vrouter number: $ROUTER_NUM"
done<l3_host_${DATE}.txt