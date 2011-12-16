#!/bin/bash

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

echo mymplayer -t -r $resume $seek $2
mymplayer -t -r $resume $seek $2
