#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

### set URLs that need to be checked and set log file ###

ERROR_LOG=/www/wdlinux/nginx-1.2.9/logs/error.log
LOG_FILE=/var/log/nginx/error-info.log
URL=("http://www.wangcaigu.com/" "https://www.wangcaigu.com/")

if [ ! -d "`dirname $LOG_FILE`" ] ; then
  mkdir -p `dirname $LOG_FILE`
fi

for url in ${URL[@]}
  do

### check web status ###
    HTTP_CODE=`curl -I -m 10 -o /dev/null -s -w %{http_code} $url`
      if [ "$HTTP_CODE" != "200" ] && [ "$HTTP_CODE" != "301" ]; then

### backup old log file if it exits ###
        if [  -f "$LOG_FILE" ] ; then
          mv `bashname $LOG_FILE` `bashname $LOG_FILE`.`date +%D/%T`
        else
### touch file if does not exits ###
          touch `bashname $LOG_FILE`
          echo "logfile `basename $LOG_FILE` inited ...."
        fi
      
        if [ ! -w "$LOG_FILE" ] ; then
          chmod a+w `bashname $LOG_FILE`
        fi
### get log info ###
        echo "#### `date +%D/%A/%T` ####" >> $LOG_FILE
        tail -f $ERROR_LOG >> $LOG_FILE

### restart service ###
        sudo kill -SIGUSR2 `cat /var/run/php5-fpm.pid`
        sudo service nginx restart

### check restart result ###	  
        HTTP_RESTART_CODE=`curl -I -m 10 -o /dev/null -s -w %{http_code} $url`
	  
### send mail to notice admin ### 
        if [ "$HTTP_RESTART_CODE" != "200" ] && [ "$HTTP_RESTART_CODE" != "301" ]; then
### send mail that restart does not work ###
          echo "!!!! Service still can not recover after restart service !!!!" >> $LOG_FILE
          cat $LOG_FILE |  mail -s "### wangcaigu web server CRITICAL ###" guowei@wangcaigu.com
        else 
### send mail that restart works ###
          echo "!!!! Service recover after restart service !!!!" >> $LOG_FILE
          cat $LOG_FILE |  mail -s "### wangcaigu web server CRITICAL ###" guowei@wangcaigu.com
        fi
      fi
  done

### remove old log file ###
find `dirname $LOG_FILE` -ctime +30 | xargs rm -f 
