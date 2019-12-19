openstack  ip availability show ext-net -c subnet_ip_availability -f value|grep -v fip-agent |awk -F ',' '{print $5,$6}'|awk -F "'" '{sum1+=$2}{sum2+=$4}END{print "Total="sum1,"Used="sum2}'
