#!/bin/bash

log_file=/tmp/play-station-controller

if [ ! -e $log_file ];then
    date +"%Y/%m/%d %H:%M:%S.%N START" >> $log_file

    sixpair >> $log_file 2>&1
    su mc -c \
    "zenity --info --timeout=5 --display=:0.0 --text=\"<span font_desc='40'>Play Station 3 Controller Pairing finished</span>\"" \
            >> $log_file 2>&1

    date +"%Y/%m/%d %H:%M:%S.%N END" >> $log_file

    sleep 60
    /bin/rm -f $log_file
else
    date +"%Y/%m/%d %H:%M:%S.%N paring is all ready finished" >> $log_file
fi
