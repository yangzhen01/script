#!/bin/bash
#####################
#统计每天凌晨以来虚机状态变化的vm数目
#输出格式为：2019-12-05 00:00:00: 1
#
#####################
source /root/admin-openrc.sh

declare -a array
declare -A ARRAY

BEFORE_DAYS="$1"
CURRENT_SEC=$(date -d"$(date +%F)" +%s)
LOOP=1

for ((i=${BEFORE_DAYS:-5}; i>=1; i--)); do
     SEC=$(($CURRENT_SEC-i*24*3600))   
     DATE=$(date -d"@${SEC}" +%F\ %H:%M:%S)
     array[$LOOP]="${DATE}"
     LOOP=$(($LOOP+1))
     OP_SEC=$(($SEC-8*3600))
     OP_DATE=$(date -d"@${OP_SEC}" +%FT%H:%M:%SZ)
     vm_num=$(nova list --all --changes-since=${OP_DATE} | grep -iE 'ACTIVE|SHUTOFF' | wc -l)
     ARRAY[$DATE]=$vm_num
done

for ((i=1; i<${BEFORE_DAYS:-5}; i++)); do
    vms=$((${ARRAY[${array[$i]}]}-${ARRAY[${array[$(($i+1))]}]}))
    ARRAY[${array[$i]}]=${vms}
done

for i in ${!array[@]}; do
    echo "${array[$i]}: ${ARRAY[${array[$i]}]}" 
done
