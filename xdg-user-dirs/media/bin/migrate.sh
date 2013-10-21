#!/bin/bash
source $(dirname $0)/00.conf

function has_free_space() {

    arr=($($MC_BIN_USB_CONTROL -d))
    used=$(df -Ph --sync | awk -v dev=${arr[1]}1 '{ if ($1 == dev) printf("%d\n", $5) }')
    if [ "$1" = "print" ];then
        log "used : ${arr[1]}1 ${used}%"
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
    /bin/mv $file $dir
    end=$(date +%s.%N)
    speed=$(echo "scale=3; r = $size / ($end - $start); scale=0; r / 1024 / 1024" | bc)
    log "move to hard disk : $speed MB/s $(($size / 1024 / 1024)) MB $(basename $dir) $title"
}

log "start ts_hd"

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

    file_info=$(ls -sh $ts | sed -e "s@$MC_DIR_TS_HD/@@")
    log "delete : $file_info $png_thumb $xml"
    /bin/rm -f $ts $png_thumb $xml

done

has_free_space print
for ts in $(find $MC_DIR_TS -type f);do

    fuser $ts
    if [ $? -eq 0 ];then
        continue
    fi

    move_to_hd $ts $MC_DIR_TS_HD
done

has_free_space print
log "end ts_hd"
