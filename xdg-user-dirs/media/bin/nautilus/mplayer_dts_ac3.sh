#!/bin/bash
source $(dirname $0)/../00.conf

resume=${4}/$(basename ${2})
seek=

if [ -f $resume ];then
    length=$(grep ANS_LENGTH $resume | tail -n 1 | awk -F '=' '{ printf("%d\n", $2) }')
    percent=$(grep ANS_PERCENT_POSITION $resume | tail -n 1 | awk -F '=' '{ printf("%d\n", $2) }')
    if [ -n "$length" -a -n "$percent" ];then
        seek_time=$(($length * $percent / 100))
        seek=" -s $seek_time "
    fi
fi

$MC_BIN_MYMPLAYER -r $resume $seek -a $2
