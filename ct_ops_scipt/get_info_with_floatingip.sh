##################
#Date: 2019-5-16
##################

#!/bin/bash

#转发网CIDR及网关数组及初始索引
transport_ip=()
transport_ip_index=0

#公网CIDR及网关数组及初始索引
public_ip=()
public_ip_index=0

usage(){
    echo -e "\033[32msh $0 floatingip\033[0m"
}


if [[ $1 == "" ]]; then
    usage
    exit 1
fi

if [[ $1 != " " ]]; then
    IP="$1"
    #output array
    ip=(${IP//\./ })

    #get array length
    count=${#ip[@]}

    if [[ $count != '4' ]]; then
        echo -e "\033[32mPlease check ip address format!\033[0m"
        usage
        exit 1
    fi
fi

get_network_info(){
    
    subnet_uuid=$(openstack network show ext-net -c subnets -f value | sed 's/,//g')
    for subnet in $subnet_uuid; do
        gateway_type=($(openstack subnet show $subnet -c cidr -c gateway_ip -c service_types -f value | xargs))
        if [[ ${gateway_type[@]:2} =~ 'router_gateway' ]]; then
           transport_ip[transport_ip_index]=$(echo "${gateway_type[@]:0:2}" | tr ' ' ',')
           transport_ip_index=$(($transport_ip_index+1))
        else
           public_ip[public_ip_index]=$(echo "${gateway_type[@]:0:2}" | tr ' ' ',')
           public_ip_index=$((public_ip_index+1))
        fi
    done
    echo -e "\033[32m转发网CIDR及网关: ${transport_ip[@]}\n公网CIDR及网关: ${public_ip[@]}\033[0m"
}

get_info(){
     #get base infomation through floating ip
     base_info=$(openstack floating ip show $1 -c fixed_ip_address -c floating_ip_address  -c port_id -c project_id -c router_id -c status -f value | xargs)

     #array
     info=(${base_info})

     fixed_ip_address=${info[0]}
     floating_ip_address=${info[1]}
     port_id=${info[2]}
     project_id=${info[3]}
     router_id=${info[4]}
     status=${info[5]}
     
     #get vm information through port_id
     if [[ $port_id != "None" ]]; then
         vm_base_info=$(openstack port show $port_id -c binding_host_id -c device_id -c network_id -c security_group_ids -f value | xargs)
         vm_info=(${vm_base_info})

         #compute node that vm located in
         binding_host=${vm_info[0]}

         vm_uuid=${vm_info[1]}
         network_id=${vm_info[2]}

         #get vm power status and image ID
         vm_info=$(openstack server show $vm_uuid -c "OS-EXT-STS:power_state" -c created -c image -f value | xargs)
         vm_power_image=(${vm_info})
         vm_power_status=${vm_power_image[0]}
         vm_create_time=${vm_power_image[1]}
         vm_image_uuid=${vm_power_image[@]:2}

         router_status=$( openstack router show $router_id -c status -f value)
         router_ha=$(neutron l3-agent-list-hosting-router $router_id -c host -c ha_state -f value | grep network | xargs)

         security_group=${vm_info[@]:3}
         security_gp=(${security_group//,/ })

         project_description=$(openstack project show $project_id -c description -f value)
         console_url=$(openstack console url show $vm_uuid -c url -f value)

         echo -e "\033[32m浮动IP地址: $floating_ip_address\n浮动IP状态: $status\n固定IP地址: $fixed_ip_address\n网络ID: $network_id\n租户ID: $project_id\n租户描述信息: $project_description\n路由ID: $router_id\n路由状态: $router_status\n路由集群状态: $router_ha\n虚机所在节点: $binding_host\n虚机电源状态: $vm_power_status\n虚机UUID: $vm_uuid, 创建时间: $vm_create_time\n虚机控制台URL: $console_url\n虚机镜像ID: $vm_image_uuid\n安全组: ${security_gp[@]}\n查看安全组命令: 'openstack security group show 安全组ID -c rules -f value'\033[0m"
         echo "当有管理员权限时，字段'租户描述信息', '控制台URL', 可以显示出来!" 
         
     else
        echo "Floating ip is not bound to fixed ip"
     fi
}

get_info $1
get_network_info
