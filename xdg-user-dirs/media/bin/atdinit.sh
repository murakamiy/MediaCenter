#!/bin/bash
source $(dirname $0)/00.conf

mode=$1

if [ "$mode" = "regist" ];then

    awk -v atd=$MC_BIN_ATD '
BEGIN {
    for (i = 1; i <= 3; i++) {
        system(sprintf("echo exec bash %s execute | at -t %s\n", atd, strftime("%Y%m%d%H%M", systime() + 60 * i + 10)))
    }
}'

elif [ "$mode" = "execute" ];then

    log "atdinit"

fi
