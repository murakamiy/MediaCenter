#!/bin/bash

resume=${4}/$(basename ${2})
seek=

if [ -f $resume ];then
    length=$(grep ANS_LENGTH $resume | tail -n 1 | awk -F '=' '{ printf("%d\n", $2) }')
    percent=$(grep ANS_PERCENT_POSITION $resume | tail -n 1 | awk -F '=' '{ printf("%d\n", $2) }')
    seek_time=$(($length * $percent / 100))
    seek=" -s $seek_time "
fi

mymplayer -t -r $resume $seek $2
