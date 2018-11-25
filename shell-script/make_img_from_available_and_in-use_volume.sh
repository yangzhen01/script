#! /bin/bash
#-------------------------------------------------------
#
#Description:This script is used for creating image from
#            available and in-use volumes
#Author: Andrew, Allen
#Date:2017-12-11
#
#volume_info.txt file format as follows:
#         Volume ID                         Status    Volume Name   Size     Type         Bootable       Server ID
#| d77f03bd-a57a-48d5-97b6-5bb9b00a4221 |   in-use  |    cirros   |  1   |  iops-demo  |   true   |  6446afb0-baae-493d-9703-bf3e8d698cf9 |
#For available volume, the Server ID field can be neglected.
#
#-------------------------------------------------------


# This script is used for creating image from  available and in-use volumes 
###################################################################
#set -e
path=`pwd`
volume_info_file="$path/volume_info.txt"
volume_id=`cat $volume_info_file |awk '{print $2}'`







create_available()
{

############## Create img ##################
	echo "Creating img for  $volume_name ......"

	img_id=`cinder upload-to-image --force true --disk-format qcow2 --container-format bare $volume img_"$volume_name"_"$volume_type"_"$volume_size"G_"$volume_attach_flavor"_"$create_time"| grep image_id | awk '{print $4}'`
        [ $? -ne 0 ] && echo -e "\033[31m error,please retry!\033[0m" && exit 1
   
        echo -e "\033[32m fetch img_id: $img_id\033[0m"
	while ((1))
	do
		img_status=`glance image-show $img_id |grep status |awk '{print $4}'`
		echo $img_status
		if [ "$img_status" = "active" ];then
			echo -e "\033[32m Create img successfully !\033[0m"
			break
		elif [ "$img_status" = "saving" ];then
			sleep 2
			continue
		elif [ "$img_status" = "queued" ];then
			sleep 2
			continue
		else
			
			echo -e "\033[31m $img_id status can not be recognized '$img_status'!\033[0m"
			
		fi
	done	
#download img to local dir /mnt/img/

	for ((n=0;n<5;n++))
	do
	    glance image-download --file /mnt/img/img_"$volume_name"_"$volume_type"_"$volume_size"G_"$volume_attach_flavor"_"$create_time" $img_id

	    err=$?
	    if [ $err -eq 0 ];then
                qemu-img info /mnt/img/img_"$volume_name"_"$volume_type"_"$volume_size"G_"$volume_attach_flavor"_"$create_time" > /dev/null 2>&1
                if [ $? -eq 0 ];then
		   echo -e "\033[32m Download img successfully !\033[0m"
		   break
                else 
                   echo -e "\033[31m Image infomation incomplete!\033[0m"
                   echo "$img_id" img_"$volume_name"_"$volume_type"_"$volume_size"G_"$volume_attach_flavor"_"$create_time" >> /mnt/img/img_incomplete.log 
                fi 

	    else
		echo "Download..."
		sleep 2
		continue
	    fi
	done

	if [ $n -eq 5 ];then
	    echo img_"$volume_name"_"$volume_type"_"$volume_size"G_"$volume_attach_flavor"_"$create_time" $img_id >> /mnt/img/err_img_id.log
	    echo "\033[32m Download img failed !\033[0m" 
	    
	fi
      


}	


create_inuse()
{	

################## Create snapshot ########################
	echo "Creating snapshot......"

	cinder snapshot-create --display-name snapshot_"$volume_name"_"$volume_type"_"$volume_size"G_"$volume_attach_flavor"_"$create_time" $volume --force True

	while ((1))
	do
		snapshot_status=`cinder snapshot-list |grep snapshot_"$volume_name"_"$volume_type"_"$volume_size"G_"$volume_attach_flavor"_"$create_time" |awk '{print $6}'`

		echo $snapshot_status
		if [ "$snapshot_status" = "available" ];then
			echo -e "\033[32m Create snapshot successfully !\033[0m"
			break

		elif [ "$snapshot_status" = "creating" ];then
			sleep 2
			continue

		elif [ "$snapshot_status" = "error" ];then
			echo -e "\033[31m Create snapshot faild !\033[0m"
			exit 1

		else
			echo -e "\033[31m $volume status can not be recognized '$snapshot_status'!\033[0m"
			
		fi
	done	

	snapshot_id=`cinder snapshot-list |grep snapshot_"$volume_name"_"$volume_type"_"$volume_size"G_"$volume_attach_flavor"_"$create_time" |awk '{print $2}'`
	#volume_type=`cat $volume_info_file |grep $volume |awk '{print $10}'|awk 'gsub(/^ *| *$/,"")'`

	if [ "$volume_type" == "sata_iops_150" ];then
	    volume_type_id="23ac2574-6df7-4ea2-a798-89b42a3764cc"

        elif [ "$volume_type" == "iops-demo" ];then
             volume_type_id="6493fa22-3f4b-4de2-bc88-c19e51a93675"

        elif [ "$volume_type" == "iops_150" ];then
	     volume_type_id="d0a22392-e0c4-42ab-9750-b0b70fff0446"
        
        elif [ "$volume_type" == "sata_iops_300" ];then
             volume_type_id="4a5e32b5-6535-4845-9ce4-29e3b7eb8b64"
       
        elif [ "$volume_type" == "iops_300" ];then
             volume_type_id="37d0dd81-7d3c-480a-87b3-e696db19d53b"

        elif [ "$volume_type" == "ssd_iops_600" ];then
             volume_type_id="5ace1f86-3624-43fb-9093-0b1f8698b37d"

        elif [ "$volume_type" == "iops_100" ];then
             volume_type_id="79ab02fa-af48-454f-9d00-12cebe21ed2f"
        else
             #echo -e "\033[31m Volume type can not  be recognized \033[0m"
             echo -e "\033[31m Volume type may  be None \033[0m"
        fi
#	volume_type_id=`cinder type-list |grep $volume_type |awk '{print $2}'`
#	for vol_type_id in $volume_type_id
#	do 
#		type=`cinder type-list |grep $vol_type_id |awk '{print $4}'`
#		if [ "$volume_type" == "$type" ];then
#			volume_type_id=$vol_type_id
#			break
#		else
#			continue
#		fi
#	done
		
#	size=`cat $volume_info_file |grep $volume |awk '{print $8}'`

########### create volume from snapshot ################

	echo "Creating volume from snapshot ......"

	if [ "$volume_type" == "None" ];then
	    cinder create --snapshot-id $snapshot_id --display-name temporary_"$volume_name"_"$volume_type"_"$volume_size"G_"$volume_attach_flavor"_"$create_time" $volume_size

	else
            cinder create --snapshot-id $snapshot_id --display-name temporary_"$volume_name"_"$volume_type"_"$volume_size"G_"$volume_attach_flavor"_"$create_time" --display-description "Create temporary volume for $volume_name" --volume-type $volume_type_id $volume_size
	fi

	while ((1))
	do

	    VOLUME_STATUS=`cinder list |grep temporary_"$volume_name"_"$volume_type"_"$volume_size"G_"$volume_attach_flavor"_"$create_time" |awk '{print $4}'` 
	    tmp_volume_id=`cinder list |grep temporary_"$volume_name"_"$volume_type"_"$volume_size"G_"$volume_attach_flavor"_"$create_time" |awk '{print $2}'`

	    echo $VOLUME_STATUS
	    if [ "$VOLUME_STATUS" = "available" ];then
	        echo -e "\033[32m Create temporary volume successfully !\033[0m"
    	        break

	    elif [ "$VOLUME_STATUS" = "creating" ];then
	        sleep 2
	        continue

	    elif [ "$VOLUME_STATUS" = "error" ];then
	        echo -e "\033[31m Create temporary volume fail !\033[0m"
	        exit 1

	    else
	        echo -e "\033[31m $tmp_volume_id status can not be recognized '$VOLUME_STATUS'!\033[0m"
	    fi
       done
############### backup the volume from snapshot ################
	volume=$tmp_volume_id
#	volume_name="$volume_name"_"$volume_type"_"$volume_size"G_"$volume_attach_flavor"_"$create_time"
	create_available

############## delete temporary volume and snapshot ############

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
}




main_function()
{
	for volume in $volume_id
	do	
		volume_stat=`cat $volume_info_file |grep $volume |awk '{print $4}'`
		[ $? -ne 0 ] && echo -e "\033[31m Volume ID can not be recognized '$volume'\033[0m" && exit 1
	        volume_name=`cat $volume_info_file |grep $volume |awk '{print $6}'`
                volume_type=`cat $volume_info_file |grep $volume |awk '{print $10}'`	
                #echo $volume_type && exit 1
                if [ "$volume_type" = "-" ]; then
                   volume_type="None"
                fi
                volume_size=`cat $volume_info_file |grep $volume |awk '{print $8}'`	

		if [ "$volume_stat" = "available" ];then
    		   create_time=`date +%Y%m%d%H%M%S`
		   create_available
		
                elif [ "$volume_stat" = "in-use" ];then
                   volume_attach_server=`cat $volume_info_file |grep $volume |awk '{print $14}'`
                   volume_attach_flavor=`nova show $volume_attach_server | grep flavor | awk '{print $4}'`                
    		   create_time=`date +%Y%m%d%H%M%S`
                   create_inuse
	        
                else
	           echo -e "\033[31m $volume status can not be recognized '$volume_stat'\033[0m"
	           exit 1
	        fi			
	done
}

main_function
