#!/bin/bash
source $(dirname $0)/00.conf

webdav_video_file=$MC_DIR_TMP/webdav_video_file

while true;do

    find $MC_DIR_WEBDAV -type f -name '*.mkv' -or -name '*.mp4' > $webdav_video_file
    open=$(inotifywait --fromfile $webdav_video_file -e open --format "%w")
    vmtouch -qt $open
    sleep 10

done &

while true;do

    find $MC_DIR_WEBDAV -type f -name '*.mkv' -or -name '*.mp4' > $webdav_video_file
    close=$(inotifywait --fromfile $webdav_video_file -e close --format "%w")
    vmtouch -qe $close
    sleep 10

done &
