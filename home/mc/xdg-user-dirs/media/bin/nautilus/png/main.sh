#!/bin/bash
source /home/mc/xdg-user-dirs/media/bin/00.conf

function safe_finish() {
    kill -TERM $pid_play
    killall mymplayer
}

png_file="$1"
inode=$(stat --format='%i' $png_file)
thumb_file=$(basename $(find $MC_DIR_THUMB -inum $inode))
base=$(echo $thumb_file | awk -F . '{ print $1 }')

if [ -n "$thumb_file" ];then
    title_dir=$(dirname $png_file)
    if [ "$title_dir" = $MC_DIR_TITLE_ENCODE ];then
        dir=$MC_DIR_ENCODE
    else
        dir=$MC_DIR_TS
    fi

    num=$(find $dir -type f -name $thumb_file | wc -l)
    if [ $num -ne 1 ];then
        zenity --info --display=:0.0 --text="<span font_desc='40'>something wrong\n\n $dir/$thumb_file</span>"
        exit
    fi
    video_file=$(find $dir -type f -name $thumb_file)

    if [ $dir = $MC_DIR_TS ];then
        trap safe_finish 1 2 3 15
        python ${MC_DIR_DB}/play.py ${MC_DIR_JOB_FINISHED}/${base}.xml >> ${MC_DIR_DB}/log 2>&1 &
        pid_play=$!
    fi

    $(dirname $0)/action.sh $thumb_file $video_file "$png_file" $MC_DIR_RESUME

    safe_finish
else
    eog $png_file
fi
