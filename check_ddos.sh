#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#set -x

ERROR_STATE=("SYN_RECV" "10" "ESTABLISHED" "30")
DDosIP=/tmp/DDosIP.txt
DDosLog=/var/log/DDos.log

rm -f $DDosIP

### get all the DDos IP ### 
for ((i=0;i<${#ERROR_STATE[*]};i=i+2))
  do
    netstat -ant | grep ${ERROR_STATE[$i]} | awk '{print $5}' | sort -d | awk -F: '{print $1}' | uniq -c | awk -v NUM="${ERROR_STATE[$i+1]}" '{if($1>NUM) print $2}' >> $DDosIP
  done

### drop all the request from the DDos IP ###
while read IP
  do
    /sbin/iptables -A INPUT -s $IP -j DROP
    echo "forbided $IP access to web at `date +%D/%T`" >> $DDosLog
  done < $DDosIP

### save all the iptables rules and restart iptables to take effects ###
sudo /etc/init.d/iptables save
sudo /etc/init.d/iptables restart
