#!/bin/bash
source $(dirname $0)/00.conf

mode=$1
if [ "$mode" = "" ];then
    mode=all
fi

function has_free_space() {

    dev=$($MC_BIN_DISK_CONTROL -l)

    used=$(df -Ph --sync | awk -v dev=$dev '{ if ($1 == dev) printf("%d\n", $5) }')
    if [ "$1" = "print" ];then
        log "used : $dev ${used}%"
    fi
    if [ -z "$used" ];then
        return 0
    fi
    if [ $used -lt 70 ];then
        return 0
    fi
    return 1
}

function order_of_deletion() {
    find $MC_DIR_TS -type f -printf '%P %p\n' | sort -k 1 | awk '{ print $2 }'
}

function do_migrate() {

total_size=0
total_count=0
last_date=
has_free_space print
for video_file in $(order_of_deletion);do

    has_free_space
    if [ $? -eq 0 ];then
        break
    fi

    ext=$(basename $video_file | awk -F . '{ print $2 }')
    xml=${MC_DIR_JOB_FINISHED}/$(basename $video_file .${ext}).xml
    png_thumb=${MC_DIR_THUMB}/$(basename $video_file)

    if [ -f "$png_thumb" ];then
        inode=$(stat --format='%i' $png_thumb)
        find $MC_DIR_TITLE_TS -inum $inode -delete
    fi

    last_date=$(basename $video_file | awk -F - '{ print $1 }')
    size=$(stat --format=%s $video_file)
    total_size=$(($total_size + $size))
    total_count=$(($total_count + 1))

    /bin/rm -f $video_file $png_thumb $xml
done

if [ $total_count -ne 0 ];then
    log "hd delete $total_count files $(($total_size / 1024 / 1024 / 1024))GB $last_date"
fi
has_free_space print

}

log "hd migrate start"
do_migrate
log "hd migrate end"
