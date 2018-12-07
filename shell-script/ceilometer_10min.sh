#! /bin/bash

################################################
#	Version : 0.4
#	Author  : Andrew Allen
#	Date    : 2018/02/03
###############################################
set -e 
source /root/admin-openrc.sh


##################################you can modify start_time/end_time/space_time/custormer_id according to your request #########

start_time="2018-03-18T07:00:00"
end_time="2018-03-18T15:00:00"
space_time=1200
customer_id="/root/vst1-openrc.sh"













####################################Do not modify anything below##################################

PERIOD="| $space_time    |"
Path=`pwd`
instance_file=$Path/instanceinfo.txt
ceilometer_file=$Path/ceilometer.txt
cpu_file=$Path/cpu.txt
mem_file=$Path/mem.txt
time_file=$Path/time.txt
hdd_temp="$Path/hdd_temp.txt"
net_in=$Path/net_in.txt
net_out=$Path/net_out.txt
temp_file=$Path/temp.txt
item=""
err=""





#if [ -f $Path/ceilometer.cfg ];then
#    cfg_file=$Path/ceilometer.cfg
#else
#    echo "Can't find the cfg file in $Path"
#    exit 1
#fi

echo > $ceilometer_file

function usage()
{
    cat << HELP
    
Usage: $0 [OPTION]
    --all								display all monitored info of all the tenants 
	eg ceilometer.sh --all
    --tenant <tenant-id>						display all monitored info of the VMs in the tenant 
	eg ceilometer.sh --tenant-d xxxx
    --tenant <tenant-id> --item <cpu|memory|throughput|iops|network>	display the item monitored info for all the tenant
	eg ceilometer.sh --tenant-id xxxx --item cpu
    --vm-id <vm-id> 							display all monitored info of the VM
	eg ceilometer.sh --vm-id xxxx
    --vm-id <vm-id> --item <cpu|memory|throughput|iops|network>		display the item monitored info of the VM
	eg ceilometer.sh --vm-id xxxx --item cpu    

HELP
    exit -1
}


#if [ $# -eq 1 ] && [ "$1" == "--all" ];then
#    instance_id=`nova list --all --tenant |awk -F '|' '{print $2}' |awk 'gsub(/^ *| *$/,"")'`

if [ $# -eq 2 ] && [ "$1" == "--tenant-id" ];then
    instance_id=`nova list --tenant $2 |awk -F '|' '{print $2}' |awk 'gsub(/^ *| *$/,"")'`

elif [ $# -eq 4 ] && [ "$1" == "--tenant-id" ] && [ "$3" == "--item" ];then
    instance_id=`nova list --tenant $2 |awk -F '|' '{print $2}' |awk 'gsub(/^ *| *$/,"")'`
    item=$4

elif [ $# -eq 2 ] && [ "$1" == "--vm-id" ];then
    instance_id="$2"

elif [ $# -eq 4 ] && [ "$1" == "--vm-id" ] && [ "$3" == "--item" ];then
    instance_id="$2"
    item=$4
else
       
    echo "Wrong arguments !"
    echo ""
    usage
fi





for VM_ID in $instance_id
do
    VM_ID=`echo $VM_ID`
    [ "$VM_ID" == "ID" ] && continue
    
    source /root/admin-openrc.sh
    nova show $VM_ID > $instance_file
    vm_name=`cat $instance_file |grep "| name" |awk -F '|' '{print $3}' |awk 'gsub(/^ *| *$/,"")'`
    result_file="$Path/$vm_name"_"ceilometer.csv"
    ceilometer_org=$Path/$vm_name"_org.txt"
    echo  > $ceilometer_org	
    ceilometer statistics -m cpu_util -p $space_time -q "resource=$VM_ID;timestamp>=$start_time;timestamp<$end_time" |grep "$PERIOD" |awk -F '|' '{print $11}'| awk -F 'T' '{print $2","}' |sed s/[[:space:]]//g > $time_file
    sed -i '1i time,' $time_file
    mv  $time_file $result_file

    if [ "$item" == "" ] || [ "$item" == "cpu" ];then
        echo "VM : $vm_name  the utilization of CPU per $space_time seconds " |tee -a $ceilometer_org
        ceilometer statistics -m cpu_util -p $space_time -q "resource=$VM_ID;timestamp>=$start_time;timestamp<$end_time" |tee  $ceilometer_file
	err=$?
	
	cat $ceilometer_file >> $ceilometer_org
	echo >> $ceilometer_org

	grep "$PERIOD" $ceilometer_file|awk -F '|' '{print $5","$6","$7","$8","}' |sed s/[[:space:]]//g > $cpu_file
	sed -i '1i cpu-max,min,avg,sum,' $cpu_file
	paste -d, $result_file $cpu_file > $temp_file
	mv $temp_file $result_file 
    fi   
 
    if [ "$item" == "" ] || [ "$item" == "memory" ];then
        echo "VM : $vm_name  the utilization of Memory per $space_time seconds  " |tee -a $ceilometer_org
        ceilometer statistics -m memory.usage -p $space_time -q "resource=$VM_ID;timestamp>=$start_time;timestamp<$end_time" |tee  $ceilometer_file
        err=$?

        cat $ceilometer_file >> $ceilometer_org
        echo >> $ceilometer_org

	grep "$PERIOD" $ceilometer_file |awk -F '|' '{print $5","$6","$7","$8","}' |sed s/[[:space:]]//g > $mem_file
	sed -i '1i memory-max,Min,Avg,sum,' $mem_file
	paste -d, $result_file $mem_file > $temp_file
	mv $temp_file $result_file

    fi
#    if [ "$item" == "" ] || [ "$item" == "throughput" ];then
#        echo "VM : $vm_name  the THROUGHPUT:READ per $space_time seconds " |tee -a $ceilometer_file
#        ceilometer statistics -m disk.read.bytes.rate -p $space_time -q "resource=$VM_ID;timestamp>=$start_time;timestamp<$end_time" |tee -a $ceilometer_file
#        err=$?
#        echo "" |tee -a $ceilometer_file
#        echo "" |tee -a $ceilometer_file
#
#        echo "VM : $vm_name  the THROUGHPUT:WRITE per $space_time seconds " |tee -a $ceilometer_file
#        ceilometer statistics -m disk.write.bytes.rate -p $space_time -q "resource=$VM_ID;timestamp>=$start_time;timestamp<$end_time" |tee -a $ceilometer_file
#        err=$? 
#        echo "" |tee -a $ceilometer_file
#        echo "" |tee -a $ceilometer_file
#    fi
    if [ "$item" == "" ] || [ "$item" == "iops" ];then
        echo "VM : $vm_name  the IOPS_VM of READ per $space_time seconds " |tee -a $ceilometer_org
        ceilometer statistics -m disk.read.requests.rate -p $space_time -q "resource=$VM_ID;timestamp>=$start_time;timestamp<$end_time" |tee  $ceilometer_file
        err=$?
        cat $ceilometer_file >> $ceilometer_org
        echo >> $ceilometer_org

        echo "VM : $vm_name  the IOPS_VM of WRITE per $space_time seconds " |tee -a $ceilometer_org
        ceilometer statistics -m disk.write.requests.rate -p $space_time -q "resource=$VM_ID;timestamp>=$start_time;timestamp<$end_time" |tee $ceilometer_file
        err=$?
        cat $ceilometer_file >> $ceilometer_org
        echo >> $ceilometer_org
        volume_id=`cat $instance_file |grep "volumes_attached" |awk -F '|' '{print $3}' |awk '{print $2$4}' |awk -F '"' '{print $2,$4}' |awk 'gsub(/^ *| *$/,"")'`
 
        for volume in $volume_id
        do
		
#	    read_file="$Path/$vm_name"_"$volume"_"read.txt"
#	    write_file="$Path/$vm_name"_"$volume"_"write.txt"
#	    hdd_temp="$Path/hdd_temp.txt"
            dev=`cinder show $volume | grep "attachments" |awk -F '/dev/' '{print $2}' |awk -F "'" '{print $1}'`
            disk_resource_id="$VM_ID-$dev"

            echo "VM : volume-id $volume  the IOPS of READ per $space_time seconds " |tee -a $ceilometer_org
            ceilometer statistics -m disk.device.read.requests.rate -p $space_time -q "resource=$disk_resource_id;timestamp>=$start_time;timestamp<$end_time" |tee $ceilometer_file
            err=$?

            cat $ceilometer_file >> $ceilometer_org
            echo >> $ceilometer_org

	    grep "$PERIOD" $ceilometer_file|awk -F '|' '{print $5","$6","$7","$8","}' |sed s/[[:space:]]//g > $hdd_temp
	    sed -i "1i $volume"_read"-max,min,avg,sum," $hdd_temp
	    paste -d, $result_file  $hdd_temp > $temp_file
	    mv $temp_file $result_file

            echo "VM : volume-id $volume  the IOPS of WRITE per $space_time seconds " |tee  -a $ceilometer_org
            ceilometer statistics -m disk.device.write.requests.rate -p $space_time -q "resource=$disk_resource_id;timestamp>=$start_time;timestamp<$end_time" |tee $ceilometer_file
            err=$?

            cat $ceilometer_file >> $ceilometer_org
            echo >> $ceilometer_org
	
	    grep "$PERIOD" $ceilometer_file |awk -F '|' '{print $5","$6","$7","$8","}' |sed s/[[:space:]]//g > $hdd_temp
	    sed -i "1i $volume"_write"-max,min,avg,sum," $hdd_temp
	    paste -d, $result_file $hdd_temp > $temp_file
	    mv $temp_file $result_file
		
        done
    fi
    
    if [ "$item" == "" ] || [ "$item" == "network" ];then
        instance_ip=`cat $instance_file |grep "network" |awk -F '|' '{print $3}' |awk 'gsub(/^ *| *$/,"")'`
    	instance_name=`cat $instance_file |grep instance_name |awk -F '|' '{print $3}' |awk 'gsub(/^ *| *$/,"")'`
	source $customer_id

        for vm_ip in $instance_ip
        do
            instance_net_port=`neutron port-list |grep $vm_ip |awk -F '|' '{print $2}' |cut -c 1-12 |awk 'gsub(/^ *| *$/,"")'`

            net_resource_id="$instance_name-$VM_ID-tap$instance_net_port"
            echo "VM : $vm_name  IP $vm_ip INCOMING per $space_time seconds " |tee -a $ceilometer_org
            ceilometer statistics -m network.incoming.bytes.rate -p $space_time -q "resource=$net_resource_id;timestamp>=$start_time;timestamp<$end_time" |tee  $ceilometer_file
            err=$?

            cat $ceilometer_file >> $ceilometer_org
            echo >> $ceilometer_org

	    grep "$PERIOD" $ceilometer_file|awk -F '|' '{print $5","$6","$7","$8","}' |sed s/[[:space:]]//g > $net_in
	    sed -i "1i $vm_ip"_incoming"-max,min,avg,sum," $net_in
	    paste -d, $result_file $net_in > $temp_file
	    mv $temp_file $result_file
 
            echo "VM : $vm_name  IP $vm_ip OUTGOING per $space_time seconds " |tee -a $ceilometer_org
            ceilometer statistics -m network.outgoing.bytes.rate -p $space_time -q "resource=$net_resource_id;timestamp>=$start_time;timestamp<$end_time" |tee $ceilometer_file
            err=$?

            cat $ceilometer_file >> $ceilometer_org
            echo >> $ceilometer_org

	    grep "$PERIOD" $ceilometer_file |awk -F '|' '{print $5","$6","$7","$8","}' |sed s/[[:space:]]//g > $net_out
            sed -i "1i $vm_ip"_outgoing"-max,Min,Avg,sum," $net_out
            paste -d, $result_file $net_out > $temp_file
            mv $temp_file $result_file 


        done
    fi 
   
done
	


mv $ceilometer_org /$Path/$vm_name".txt"


rm -f $cpu_file $mem_file $hdd_temp $temp_file $net_in $net_out





if [ "$err" == "" ];then
  echo ""
  echo Wrong argument/tenant-id/vm-id/item ! 
  usage
fi

echo "The result is saved in $ceilometer_file or $result_file"
