#!/bin/bash
source $(dirname $0)/00.conf

function has_free_space() {

    used=$(df -Ph --sync | awk -v dev=$MC_DEVICE_USB_DISK_TS '{ if ($1 == dev) printf("%d\n", $5) }')
    log "used : $MC_DEVICE_USB_DISK_TS ${used}%"
    if [ -z "$used" ];then
        return 0
    fi
    if [ $used -lt 70 ];then
        return 0
    fi
    return 1
}

sleep 10
if [ "$1" = "array" ];then

    log "start ts_hd"
    for ts in $(find $MC_DIR_TS_HD -type f | sort);do

        has_free_space
        if [ $? -eq 0 ];then
            break
        fi

        xml=${MC_DIR_JOB_FINISHED}/$(basename $ts .ts).xml
        png_thumb=${MC_DIR_THUMB}/$(basename $ts)

        if [ -f "$png_thumb" ];then
            inode=$(stat --format='%i' $png_thumb)
            find $MC_DIR_TITLE_TS -inum $inode -delete
        fi

        log "delete : $ts $png_thumb $xml"
        /bin/rm -f $ts $png_thumb $xml

    done

    for ts in $(find $MC_DIR_TS -type f);do
        log "move to hard disk : $ts"
        sync
        /bin/mv $ts $MC_DIR_TS_HD
    done
    log "end ts_hd"

elif [ "$1" = "encode" ];then

    log "start encode"
    for en in $(find $MC_DIR_ENCODE -type f);do
        log "move to hard disk : $en"
        /bin/mv $en $MC_DIR_ENCODE_HD
    done
    log "end encode"

fi
