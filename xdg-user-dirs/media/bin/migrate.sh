#!/bin/bash
source $(dirname $0)/00.conf

mode=$1

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

    title=$(print_title ${dir}/$(basename $file | awk -F . '{ print $1 }').xml)
    size=$(stat --format=%s $file)
    start=$(date +%s.%N)
    /bin/mv $file $dir
    end=$(date +%s.%N)
    speed=$(echo "scale=3; r = $size / ($end - $start); scale=0; r / 1024 / 1024" | bc)
    log "move to hard disk : $speed MB/s $(($size / 1024 / 1024)) MB $(basename $dir) $title"
}

log "start ts_hd"

total_size=0
total_count=0
last_date=
has_free_space print
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

    last_date=$(basename $ts | awk -F - '{ print $1 }')
    size=$(stat --format=%s $ts)
    total_size=$(($total_size + $size))
    total_count=$(($total_count + 1))

    /bin/rm -f $ts $png_thumb $xml
done

if [ $total_count -ne 0 ];then
    log "hd delete $total_count files $(($total_size / 1024 / 1024 / 1024))GB $last_date"
fi

has_free_space print
for ts in $(find $MC_DIR_TS -type f);do

    df=$(LANG=C df -P | grep '/$' | awk '{ printf("%d\n", $(NF - 1)) }')
    if [ "$mode" = "lazy" -a $df -lt 50 ];then
        break
    fi

    fuser $ts
    if [ $? -eq 0 ];then
        continue
    fi

    move_to_hd $ts $MC_DIR_TS_HD
done

has_free_space print
log "end ts_hd"
