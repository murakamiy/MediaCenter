#!/bin/bash

type=$1
log_file=/tmp/play-station-controller

event_handle=not_yet
if [ -e $log_file ];then
    event_handle=finished
fi

date +"%Y/%m/%d %H:%M:%S.%N $type START" >> $log_file

if [ "$event_handle" = "not_yet" ];then

    if [ "$type" = "pairing" ];then

        sixpair >> $log_file 2>&1

        date +"%Y/%m/%d %H:%M:%S.%N pairing finished" >> $log_file
        su mc -c \
        "zenity --info --timeout=10 --display=:0.0 --text=\"<span font_desc='40'>Play Station 3 Controller Pairing finished</span>\"" \
                >> $log_file 2>&1 &

    elif [ "$type" = "battery" ];then

        battery_level=$(tac /var/log/sixad | grep -o 'Battery ..' | head -n 1 | awk '{ printf("%d\n", $2) }')

        if [ $battery_level -lt 3 ];then
            su mc -c \
            "zenity --info --timeout=20 --display=:0.0 --text=\"<span font_desc='40'>Battery Level is low</span>\"" \
                    >> $log_file 2>&1 &
        fi

        date +"%Y/%m/%d %H:%M:%S.%N battery level $battery_level" >> $log_file
    fi

    (sleep 5; /bin/rm -f $log_file;) &

else
    date +"%Y/%m/%d %H:%M:%S.%N event hendler already finished" >> $log_file
fi

date +"%Y/%m/%d %H:%M:%S.%N $type END" >> $log_file
