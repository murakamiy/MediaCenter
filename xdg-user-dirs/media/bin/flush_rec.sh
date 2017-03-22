#!/bin/bash
source $(dirname $0)/00.conf

cache_size=$(( 1024 * 1024 * 200 ))
evict_threshold=$(( cache_size * 2 ))

while true;do
    sleep 60

    for xml in $(find $MC_DIR_RECORDING -type f -name '*.xml');do
        base=$(basename $xml .xml)
        ts_file=${MC_DIR_TS}/${base}.ts

        if [ -f $ts_file ];then
            file_size=$(stat --format=%s $ts_file)

            if [ $file_size -gt $evict_threshold ];then
                evict_size=$(( file_size - cache_size ))
                vmtouch -q -e -p $evict_size $ts_file
            fi
        fi
    done

done
