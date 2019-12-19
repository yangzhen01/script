#!/bin/env bash

source /root/admin-openrc.sh
#期望的参数个数
ARGS=1

#计算节点 nova-compute 服务可能正在运行
NOVA_COMPUTE_RUNNING=6

#计算节点上面没有虚机
NO_VM=3

#以下两个数组用来存贮每个虚机/计算节点的vcpu/mem
declare -A VM_INFO
declare -A PHY_INFO

#if [[ ! "$1" =~ "compute" || "$#" != "${ARGS}" ]]; then
#    echo -e "\033[32mUsage: $0 计算节点主机名\033[0m"
#    exit 1
#fi

work_dir=$(pwd)
work_path="$work_dir/evacuate"
if [[ ! -d $work_path ]]; then
    mkdir $work_path
fi

HOSTNAME="$1"
#Get compute node ip
: "${HOSTNAME##*-}"
COMPUTE_IP="${_//e/.}"

ZONE=$(openstack host list | grep "${HOSTNAME}" | awk '{print $6}')


#获取计算节点还有多少可用 vcpus 和内存，保存在数组中，数组的键是计算节点主机名
check_physical_resource(){
    FREE_RAM_GB_TOTAL=0
    FREE_VCPUS_TOTAL=0

    openstack host list | grep "${ZONE}" | grep -v "${HOSTNAME}" | awk '{print $2}' >$work_path/hypervisort_host
    while read name; do
        host_info=($(openstack hypervisor show ${name} -c free_ram_mb -c vcpus -c vcpus_used -f value | xargs))
        FREE_RAM_MB="${host_info[0]}"
        FREE_RAM_GB=$((${FREE_RAM_MB}/1024))
        FREE_RAM_GB_TOTAL=$((${FREE_RAM_GB_TOTAL}+${FREE_RAM_GB}))
        VCPUS="${host_info[1]}"
        VCPUS_USED="${host_info[2]}"
        FREE_VCPUS=$((${VCPUS}-${VCPUS_USED}))
        FREE_VCPUS_TOTAL=$((${FREE_VCPUS_TOTAL}+${FREE_VCPUS}))
        PHY_INFO[$name]="$FREE_VCPUS $FREE_RAM_GB"
        echo -e "\033[32m${name}: 可用vcpus数目 ${FREE_VCPUS} 可用内存 ${FREE_RAM_GB}GB\033[0m"
    done<$work_path/hypervisort_host
    echo -e "\033[32m总共可用vcpus数目 ${FREE_VCPUS_TOTAL}, 可用内存 ${FREE_RAM_GB_TOTAL}GB\033[0m"
}


#获取虚机信息, 使用多少 vcpus 和内存，保存在数组中，数组的键是虚机的 uuid
check_vm_resource_info(){
    echo -e "\033[32m检查虚机占用资源>>>\033[0m"
    nova list --all --host "$1" | grep -Ei "active|shutoff" | awk '{print $2 " " $4 " " $12}'>$work_path/vm_uuid_hostname
    if [[ ! -s $work_path/vm_uuid_hostname ]]; then
        echo -e "\033[31m计算节点上没有虚机, 无需疏散!\033[0m"
        exit $NO_VM 
    fi
    while read uuid name status; do
        info=($(nova show ${uuid} | grep -E 'flavor:ram | flavor:vcpus' | awk '{print $4}' | xargs))
        RAM_MB="${info[0]}"
        RAM_GB=$((${RAM_MB}/1024))
        VCPUS="${info[1]}"
        RAM_TOTAL_GB=$((${RAM_TOTAL_GB}+${RAM_GB}))
        VCPUS_TOTAL=$((${VCPUS_TOTAL}+${VCPUS}))
        VM_INFO[$uuid]="$VCPUS $RAM_GB"
        echo -e "\033[32m$uuid $name: ${VCPUS}C${RAM_GB}GB\033[0m" 
    done<$work_path/vm_uuid_hostname
    echo -e "\033[32m总共占用${VCPUS_TOTAL}核, ${RAM_TOTAL_GB}GB内存.\033[0m"
    check_physical_resource
}

#进一步检查疏散条件
check_whether_evacuate(){
    while true; do
        sleep 2
        status=$(nova service-list | grep ${HOSTNAME} | awk '{print $12}')
	[[ "${status}" == "down" ]] && break
    done
    echo -e "\033[32m疏散条件满足, 执行疏散!\033[0m"
    check_vm_resource_info $HOSTNAME
}

#疏散宕机节点管理的卷由正常机器管理,把控制权交出来
result=$(cinder --os-volume-api-version 3.33 list --filters host=${HOSTNAME} --all | grep -Ei "true|false")
if [[ $result != '' ]]; then
    new_host=$(cinder service-list | grep cinder-volume | grep -v ${HOSTNAME} | awk '{print $4}' | head -1)
    #迁移volume
    cinder-manage --config-file /etc/cinder/cinder.conf volume update_host \
                   --currenthost ${HOSTNAME}@${new_host#*@} --newhost ${new_host}
    #迁移backup
    cinder-manage --config-file /etc/cinder/cinder.conf backup update_backup_host \
                   --currenthost ${HOSTNAME} --newhost ${new_host%@*}
    sleep 1
    result=$(cinder --os-volume-api-version 3.33 list --filters host=${HOSTNAME} --all | grep -Ei "true|false")
    if [[ $result != '' ]]; then
        echo -e "\033[31m${HOSTNAME} 节点上有卷未迁移，请查明原因!\033[0m"
        exit 555
    else
        echo -e "\033[32m卷迁移成功!\033[0m"
    fi
else
    echo -e "\033[32m${HOSTNAME} 没有管理的卷.\033[0m"
fi

#Disable cinder-compute 服务
cinder service-disable ${HOSTNAME}@${new_host#*@} cinder-volume
cinder service-disable ${HOSTNAME} cinder-backup

ping -c 1 -W 1 "$COMPUTE_IP" &>/dev/null

if [[ $? == 0 ]]; then
    echo -e "\033[31m计算节点 ${COMPUTE_IP} 运行中, aborting...\033[0m"
    exit ${NOVA_COMPUTE_RUNNING}
else
    echo -e "\033[32m计算节点 ${COMPUTE_IP} 可能已经关机,进一步检查是否可以疏散...\033[0m"
    check_whether_evacuate
fi


#$work_path/vm_uuid_eva 文件作用是疏散成功后会自动删除相应的虚机uuid，如果为空，则说明全部疏散完毕。
[[ -e $work_path/vm_uuid_eva ]] && >$work_path/vm_uuid_eva

#执行疏散
for vm in ${!VM_INFO[@]}; do
    echo "$vm" >>$work_path/vm_uuid_eva
    VM="${VM_INFO[$vm]}"
    vm_cpu="${VM/ *}"
    vm_mem="${VM#* }"
    for phy in "${!PHY_INFO[@]}"; do
        PHY="${PHY_INFO[$phy]}"
        phy_cpu="${PHY/ *}"
        phy_mem="${PHY#* }"
        if [ $vm_cpu -le $phy_cpu -a $vm_mem -le $phy_mem ]; then
            nova evacuate --force $vm $phy
            if [[ $? == 0 ]]; then
                echo -e "\033[32m$vm 疏散至 $phy 成功!\033[0m" | tee -a $work_path/evacuate_sucess_rec
                sed -i "/$vm/d" $work_path/vm_uuid_eva
                host_info_update=($(openstack hypervisor show ${phy} -c free_ram_mb -c vcpus -c vcpus_used -f value | xargs))
                FREE_RAM_MB_UPDATE="${host_info_update[0]}"
                FREE_RAM_GB=$((${FREE_RAM_MB_UPDATE}/1024))
                VCPUS_UPDATE="${host_info_update[1]}"
                VCPUS_USED_UPDATE="${host_info_update[2]}"
                FREE_VCPUS_UPDATE=$((${VCPUS_UPDATE}-${VCPUS_USED_UPDATE}))
                PHY_INFO[$phy]="$FREE_VCPUS_UPDATE $FREE_RAM_GB"
            else
                echo -e "\033[31m$vm 疏散至 $phy 失败.\033[0m" 
            fi
            break
        else
            continue
        fi
    done
done

#如果文件 $work_path/vm_uuid_eva 不为空，则说明有虚机未能疏散 
if [[ -s $work_path/vm_uuid_eva ]]; then
    echo -e "\033[31m以下虚机未能疏散...\033[0m"
    cat $work_path/vm_uuid_eva
fi
