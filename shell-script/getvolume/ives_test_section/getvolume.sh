
project_name=$1
base_item=4


output=("Project Instance_name IP ")

proj=$(mysql keystone -u root -pfoxconn<<<"select id from project where name='$project_name';")
project_id=$(cut -d ' ' -f2 <<< $proj)
nova=()
### example,   var0,1....
myIns=$(mysql nova -u root -pfoxconn<<<"select display_name, uuid, vcpus, memory_mb from instances where project_id='$project_id' and deleted='0';")
#myIns=$(mysql nova -u root -pfoxconn<<<"select display_name, uuid, vcpus, memory_mb from instances where project_id='$project_id' and deleted='0' and power_state='1';")
#myIns=$(mysql nova -u root -pfoxconn<<<"select display_name, uuid, vcpus, memory_mb from instances where project_id='cb15eef1a6094475b11ea6fbe5fc70e1' and deleted='0'")
count=0

for i in ${myIns}
do
nova[$count]=$i
count=$((count+1))
done

### instance numbers
vm_no=$((count/base_item - 1))

### seq start from 2nd row
for i in $(seq 1 1 $vm_no)
do
instance=()
index=$((1+$base_item*$i))
instance_id=${nova[$index]}
#echo "instance id: $instance_id"
#echo "instance name: ${nova[$((4*$i))]}"
netw=$(mysql nova -u root -pfoxconn<<<"select network_info from instance_info_caches where instance_uuid='$instance_id';")
pp=$(grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" <<< $netw)
network=$(cut -d ' ' -f1 <<< $pp)
if [[ -z $network ]]
then
        network="NULL"
fi
if [[ ${network} == "NULL" ]];then
	echo "NULL IP"
elif [[ ${network} != *"10.134"* ]] ;then
	tmpn=$(cut -d ' ' -f6 <<< $pp)
	if [[ ${tmpn} == "NULL" ]];then
		network=${tmpn}
	fi
fi
extra=$(mysql nova -u root -pfoxconn<<<"select node, created_at, power_state from instances where uuid='$instance_id';")
node=$(cut -d ' ' -f4 <<< $extra)
create=$(cut -d ' ' -f5 <<< $extra)
power=$(cut -d ' ' -f7 <<< $extra)
if [[ -z $node ]]
then
        node="NULL"
fi
if [[ -z $create ]]
then
        create="NULL"
fi

#echo $node
#echo $create
instance+=($project_name)
instance_name=(${nova[$(($base_item*$i))]})
if [[ -z $instance_name ]]
then
        instance_name="NULL"
fi
instance+=(${instance_name})
instance+=($node)
instance+=($create)
instance+=($power)
instance+=($network)
instance+=(${nova[$((2+base_item*$i))]})
ram=${nova[$((3+base_item*$i))]}
ram_g=$((ram/1024))
#instance+=(${nova[$((3+4*$i))]})
instance+=($ram_g)



myvolattach=$(mysql cinder -u root -pfoxconn<<<"select volume_id, mountpoint from volume_attachment where instance_uuid='$instance_id' and deleted='0' order by mountpoint;")
# for loop each vol
count_vol=0
myvol=()
for i in $myvolattach
do
myvol[$count_vol]=$i
count_vol=$((count_vol+1))
done

count_vol=$((count_vol/2-1))
for i in $(seq 1 1 $count_vol)
do
#volume_type_id=$(mysql cinder -u root -pfoxconn<<<"select volume_type_id from volumes where id='${myvol[$i]}' and deleted='0';")
volume_type_id=$(mysql cinder -u root -pfoxconn<<<"select volume_type_id, size from volumes where id='${myvol[$((i*2))]}' and deleted='0';")
vol_type_id=$(cut -d ' ' -f3 <<< $volume_type_id)
vol_size=$(cut -d ' ' -f4 <<< $volume_type_id)

volume_image="NULL"
if [[ ${myvol[$((i*2+1))]} == "/dev/vda" ]];then
#echo "vda"
volume_image_id=$(mysql cinder -u root -pfoxconn<<<"select value from volume_glance_metadata where volume_id='${myvol[$((i*2))]}' and volume_glance_metadata.key='image_name';")
volume_image=$(cut -d ' ' -f2 <<< $volume_image_id)
#echo ${volume_image}
if [[ -z $volume_image ]]
then
        volume_image="NULL"
fi
instance+=(${volume_image})
fi

#echo $vol_type_id
volume_type_name=$(mysql cinder -u root -pfoxconn<<<"select name from volume_types where id='$vol_type_id';")
vol_type_name=$(cut -d ' ' -f2 <<< $volume_type_name)
if [[ -z $vol_type_name ]]
then
	vol_type_name="NULL"
fi
#echo $vol_type_name
#echo $vol_size
#echo ${myvol[$((i*2+1))]}
#if [[ -z ${myvol[$((i*2+1))]} ]]
#then
#        vol_mount=${myvol[$((i*2+1))]}
#else
#	vol_mount="NULL"
#fi
instance+=(${myvol[$((i*2+1))]})
#instance+=($vol_mount)
instance+=($vol_size)
instance+=($vol_type_name)
done
echo ${instance[@]} >> vm_overall.txt
echo ${instance[@]} 
done
