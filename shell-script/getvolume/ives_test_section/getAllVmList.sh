#/root/ives_test_section/getvolume.sh tj-it@foxconn.com
awk '{print $1}' project.txt | xargs -n1 /root/ives_test_section/getvolume.sh 
