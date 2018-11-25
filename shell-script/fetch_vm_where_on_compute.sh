ServerID=$(nova list --all-tenants | grep ACTIVE | awk  '{print $2}')
ServerName=($(nova list --all-tenants | grep ACTIVE | awk  '{print $4}'))
echo -e "--------------------ID--------------------------Name-------------------Compute--------------"
declare -i n=0
for serverid in $ServerID;do
    compute=$(nova show $serverid |grep "hypervisor_hostname" | awk '{print $4}')
echo -e "    $serverid       ${ServerName[$n]}       $compute "
n=$(($n+1))
echo
done
