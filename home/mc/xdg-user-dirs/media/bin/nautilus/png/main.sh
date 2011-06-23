#!/bin/bash
source /home/mc/xdg-user-dirs/media/bin/00.conf

png_file="$1"
inode=$(stat --format='%i' $png_file)
base=$(basename $(find $MC_DIR_THUMB -inum $inode))

if [ -n "$base" ];then
    title_dir=$(dirname $png_file)
    if [ "$title_dir" = $MC_DIR_TITLE_TS ];then
        dir=$MC_DIR_TS
    elif [ "$title_dir" = $MC_DIR_TITLE_ENCODE ];then
        dir=$MC_DIR_ENCODE
    fi

    num=$(find $dir -type f -name "$base.*" | wc -l)
    if [ $num -ne 1 ];then
        zenity --info --display=:0.0 --text="<span font_desc='40'>something wrong\n\n $dir/$base</span>"
        exit
    fi
    video_file=$(find $dir -type f -name "$base.*")

    $(dirname $0)/action.sh $base $video_file "$png_file" $MC_DIR_RESUME
else
    eog $png_file
fi
