
Start=36
End=40
Server_ip=$(seq $Start $End)
for ip in $Server_ip; do
   ping -c 2  192.168.136.$ip > null.txt 2> null.txt
done
