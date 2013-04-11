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

for ts in $(find $MC_DIR_TS_HD -type f | sort);do

    has_free_space
    if [ $? -eq 0 ];then
        break
    fi

    xml=${MC_DIR_JOB_FINISHED}/$(basename $ts .ts).xml
    png_thumb=${MC_DIR_THUMB}/$(basename $ts)
    png_title=

    if [ -f "$png_thumb" ];then
        inode=$(stat --format='%i' $png_thumb)
        png_title=$(find $MC_DIR_TITLE_TS -inum $inode)
    fi

    log "delete : $ts $png_title $png_thumb $xml"
    /bin/rm $ts "$png_title" $png_thumb $xml

done

for ts in $(find $MC_DIR_TS -type f);do
    log "move to hard disk : $ts"
    /bin/mv $ts $MC_DIR_TS_HD
done &

for en in $(find $MC_DIR_ENCODE -type f);do
    log "move to hard disk : $en"
    /bin/mv $en $MC_DIR_ENCODE_HD
done
