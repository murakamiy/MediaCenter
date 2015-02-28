#!/bin/bash
source $(dirname $0)/00.conf

mode=$1
if [ "$mode" = "" ];then
    mode=all
fi

function has_free_space() {

    used=$(df -Ph --sync | awk -v dev=$MC_DEVICE_USB_DISK_TS '{ if ($1 == dev) printf("%d\n", $5) }')
    if [ "$1" = "print" ];then
        log "used : $MC_DEVICE_USB_DISK_TS ${used}%"
    fi
    if [ -z "$used" ];then
        return 0
    fi
    if [ $used -lt 80 ];then
        return 0
    fi
    return 1
}

function move_to_hd() {
    file=$1
    dir=$2

    title=
    if [ $dir = $MC_DIR_TS_HD ];then
        title=$(print_title $MC_DIR_JOB_FINISHED/$(basename $file | awk -F . '{ print $1 }').xml)
    elif [ $dir = $MC_DIR_ENCODE_HD ];then
        title=$(print_title ${MC_DIR_ENCODE_FINISHED}/$(basename $file | awk -F . '{ print $1 }').xml)
    fi
    size=$(stat --format=%s $file)
    start=$(date +%s.%N)
    /bin/cp $file $dir
    /bin/rm $file
    end=$(date +%s.%N)
    speed=$(echo "scale=3; r = $size / ($end - $start); scale=0; r / 1024 / 1024" | bc)
    log "move to HD $mode : $speed MB/s $(($size / 1024 / 1024)) MB $(basename $dir) $title"
}

function order_of_deletion() {
    find $MC_DIR_TS_HD $MC_DIR_MP4_HD -type f -printf '%P %p\n' | sort -k 1 | awk '{ print $2 }'
}

function do_migrate() {

$MC_BIN_USB_MOUNT >> ${MC_DIR_LOG}/usb-disk.log 2>&1
mount | grep -q '^/dev/md0 on /home/mc/xdg-user-dirs/media/video/ts_hd'
if [ $? -ne 0 ];then
    log "ERROR: usb disk mount failed"
    /bin/cp ${MC_DIR_LOG}/usb-disk.log ${MC_DIR_LOG}/usb-disk.log.error
    return
fi

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

pct=$(($MC_SSD_THRESHOLD - 20))
has_free_space print
for ts in $(find $MC_DIR_TS -type f | sort);do

    if [ "$mode" = "lazy" ];then
        df=$(LANG=C df -P | grep '/$' | awk '{ printf("%d\n", $(NF - 1)) }')
        if [ $df -lt $pct ];then
            break
        fi
    fi

    fuser $ts
    if [ $? -eq 0 ];then
        continue
    fi

    move_to_hd $ts $MC_DIR_TS_HD
done

has_free_space print

}

log "hd migrate start"
do_migrate
log "hd migrate end"
