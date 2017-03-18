#!/bin/bash
source $(dirname $0)/00.conf

mkdir -p $MC_DIR_REC_DISPATCH_WAIT

while true;do

    inotifywait -e create $MC_DIR_REC_DISPATCH_WAIT
    sleep 0.1

    for f in $(find $MC_DIR_REC_DISPATCH_WAIT -type f);do
        sleep 0.1
        rm -f $f
    done
    for f in $(find $MC_DIR_REC_DISPATCH_WAIT -type f);do
        sleep 0.1
        rm -f $f
    done
done
