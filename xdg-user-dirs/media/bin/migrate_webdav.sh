#!/bin/bash
source $(dirname $0)/00.conf

function has_free_space() {

    used=$(df -Ph --sync | awk -v mount=/ '{ if ($6 == mount) printf("%d\n", $5) }')

    if [ "$1" = "print" ];then
        log "used : $mount ${used}%"
    fi
    if [ -z "$used" ];then
        return 0
    fi
    if [ $used -lt 50 ];then
        return 0
    fi
    return 1
}

function order_of_deletion() {
    find $MC_DIR_ENCODE_DOWNSIZE -type f -printf '%TY%Tm%Td%TH%TM %p\n' | sort -k 1 | awk '{ print $2 }'
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
        ts_file=${MC_DIR_TS}/$(basename $video_file .${ext}).ts

        last_date=$(basename $video_file | awk -F - '{ print $1 }')
        size=$(stat --format=%s $video_file)
        total_size=$(($total_size + $size))
        total_count=$(($total_count + 1))

        inode=$(stat --format='%i' $video_file)
        find $MC_DIR_ENCODE_DOWNSIZE $MC_DIR_WEBDAV_CONTENTS -inum $inode -delete

        if [ ! -f $ts_file ];then
            rm -f $png_thumb $xml
            if [ -f "$png_thumb" ];then
                inode=$(stat --format='%i' $png_thumb)
                find $MC_DIR_TITLE_TS -inum $inode -delete
            fi
        fi
    done

    rmdir $MC_DIR_WEBDAV_CONTENTS/*
    if [ $total_count -ne 0 ];then
        log "hd delete $total_count files $(($total_size / 1024 / 1024))MB $last_date"
    fi
    has_free_space print
}

log "hd_small migrate start"
do_migrate
log "hd_small migrate end"
