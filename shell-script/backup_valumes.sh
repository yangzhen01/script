#! /bin/bash

# This script is used for backuping available and in-use vlaumes 
###################################################################
#set -e
path=`pwd`
volume_info_file="$path/volume_info.txt"
volume_id=`cat $volume_info_file |awk '{print $2}'`







backup_available()
{

############## Backup volume ##################
	echo "Backuping $volume_name ......"
	cinder backup-create --container backups --display-name backup_$volume_name"_"$create_time --display-description "backup $volume_name" $volume
	
	while ((1))
	do
		backup_status=`cinder backup-list |grep "backup_$volume_name"_"$create_time" |awk '{print $6}'`
		echo $backup_status
		if [ "$backup_status" = "available" ];then
			echo -e "\033[32m Backup successfully !\033[0m"
			break
		elif [ "$backup_status" = "error" ];then
			echo -e "\033[31m Backup fail !\033[0m"
			exit 1
		elif [ "$backup_status" = "creating" ];then
			sleep 2
			continue
		else
			
			echo -e "\033[31m $volume_id status can not be recognized '$backup_status'!\033[0m"
			
		fi
	done	
		
}	


backup_inuse()
{	

################## Create snapshot ########################
	echo "Creating snapshot......"
	cinder snapshot-create --display-name snapshot_$volume_name"_"$create_time $volume --force True

	while ((1))
	do
		snapshot_status=`cinder snapshot-list |grep "snapshot_$volume_name"_"$create_time" |awk '{print $6}'`
		echo $snapshot_status
		if [ "$snapshot_status" = "available" ];then
			echo -e "\033[32m Create snapshot successfully !\033[0m"
			break
		elif [ "$snapshot_status" = "error" ];then
			echo -e "\033[31m Create snapshot faild !\033[0m"
			exit 1
		elif [ "$snapshot_status" = "creating" ];then
			sleep 2
			continue
		else
			echo -e "\033[31m $volume_id status can not be recognized '$snapshot_status'!\033[0m"
			
		fi
	done	
	
	snapshot_id=`cinder snapshot-list |grep "snapshot_$volume_name"_"$create_time" |awk '{print $2}'`
	volume_type=`cat $volume_info_file |grep $volume |awk '{print $10}'`
	volume_type_id=`cinder type-list |grep $volume_type |awk '{print $2}'`
	size=`cat $volume_info_file |grep $volume |awk '{print $8}'`

########### create volume from snapshot ################
	echo "Creating volume from snapshot ......"
	cinder create --snapshot-id $snapshot_id --display-name temporary_$volume_name"_"$create_time --display-description "Create temporary volume for $volume_name" --volume-type $volume_type_id $size

	while ((1))
	do

		VOLUME_STATUS=`cinder list |grep "temporary_$volume_name"_"$create_time" |awk '{print $4}'`
		tmp_volume_id=`cinder list |grep "temporary_$volume_name"_"$create_time" |awk '{print $2}'`
	    echo $VOLUME_STATUS

	    if [ "$VOLUME_STATUS" = "available" ];then
	        echo -e "\033[32m Create temporary volume successfully !\033[0m"
    	    break
	    elif [ "$VOLUME_STATUS" = "error" ];then
	        echo -e "\033[31m Create temporary volume fail !\033[0m"
	        exit 1
		elif [ "$VOLUME_STATUS" = "creating" ];then
	        sleep 2
	        continue
	    else
	        echo -e "\033[31m $tmp_volume_id status can not be recognized '$VOLUME_STATUS'!\033[0m"
	    fi
    done
############### backup the volume from snapshot ################
	volume=$tmp_volume_id
	backup_available
############## delete temporary volume and snapshot ############

	cinder snapshot-delete $snapshot_id
	while ((1))
	do
		cinder snapshot-list |grep $snapshot_id >  /dev/null 2>&1
		err=$?
	    if [ $err -ne 0 ];then
	        echo -e "\033[32m Delete snapshot successfully !\033[0m"
    	    break
	    else
			sleep 2
			continue
	    fi
	done

	cinder delete $tmp_volume_id
	while ((1))
	do

		cinder list |grep $tmp_volume_id >  /dev/null 2>&1
		err=$?
	    if [ $err -ne 0 ];then
	        echo -e "\033[32m Delete temporary volume successfully !\033[0m"
    	    break
	    else
			sleep 2
			continue
	    fi
	done

}




main_function()
{
	for volume in $volume_id
	do	
		volume_stat=`cat $volume_info_file |grep $volume |awk '{print $4}'`
		[ $? -ne 0 ] && echo -e "\033[31m Volume ID can not be recognized '$volume'\033[0m" && exit 1
	    volume_name=`cat $volume_info_file |grep $volume |awk '{print $6}'`
	
		if [ "$volume_stat" = "available" ];then
    		create_time=`date +%Y%m%d%H%M%S`
			backup_available
		elif [ "$volume_stat" = "in-use" ];then
    		create_time=`date +%Y%m%d%H%M%S`
			backup_inuse
	    else
	        echo -e "\033[31m $volume status can not be recognized '$volume_stat'\033[0m"
	        exit 1
	    fi			


	done
}

main_function
