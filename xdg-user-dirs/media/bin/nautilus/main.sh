#!/bin/bash
source $(dirname $0)/../00.conf

function safe_finish() {
    kill -TERM $pid_play
    killall mymplayer
    killall myvlc
}

png_file="$1"
inode=$(stat --format='%i' $png_file)
thumb_file=$(basename $(find $MC_DIR_THUMB -inum $inode))

if [ -n "$thumb_file" ];then

    base=$(echo $thumb_file | awk -F . '{ print $1 }')
    xml_file=${base}.xml
    play_stat=false

    echo $png_file | grep -q $MC_DIR_TITLE_TS
    if [ $? -eq 0 ];then
        play_stat=true
        for dir in "$MC_DIR_TS_HD $MC_DIR_TS $MC_DIR_MP4_HD $MC_DIR_MP4";do
            video_file=$(find $dir -type f -name $thumb_file | sort | head -n 1)
            if [ -n "$video_file" ];then
                break
            fi
        done
    else
        echo $png_file | grep -q $MC_DIR_TITLE_ENCODE
        if [ $? -eq 0 ];then
            video_file=$(find $MC_DIR_ENCODE_HD -type f -name $thumb_file | sort | head -n 1)
        else
            zenity --info --display=:0.0 --text="<span font_desc='40'>something wrong 1\n\n $png_file</span>"
            exit
        fi
    fi

    if [ -z "$video_file" ];then
        zenity --info --display=:0.0 --text="<span font_desc='40'>something wrong 2\n\n $png_file</span>"
        exit
    fi

    if [ "$play_stat" = "true" ];then
        trap safe_finish 1 2 3 15
        python ${MC_DIR_DB_RATING}/play.py ${MC_DIR_JOB_FINISHED}/${xml_file} >> ${MC_DIR_DB_RATING}/log 2>&1 &
        pid_play=$!
    fi

    $(dirname $0)/action.sh $thumb_file $video_file "$png_file" $xml_file

    safe_finish
else
    eog $png_file
fi
