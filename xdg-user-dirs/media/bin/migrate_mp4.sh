#!/bin/bash
source $(dirname $0)/00.conf

for mp4 in $(find $MC_DIR_MP4 -type f | sort);do

    fuser $mp4
    if [ $? -eq 0 ];then
        continue
    fi

    /bin/cp $mp4 $MC_DIR_MP4_HD
    /bin/rm $mp4

done
