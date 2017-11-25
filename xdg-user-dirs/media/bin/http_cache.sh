#!/bin/bash
source $(dirname $0)/00.conf

webdav_video_file=$MC_DIR_TMP/webdav_video_file

while true;do

    touch --date='2000/01/01' ${MC_DIR_WEBDAV}/empty.mkv
    find $MC_DIR_WEBDAV -type f -name '*.mkv' -or -name '*.mp4' > $webdav_video_file
    open=$(inotifywait --fromfile $webdav_video_file -e open --format "%w")
    vmtouch -qt $open
    sleep 60

done &

while true;do

    touch --date='2000/01/01' ${MC_DIR_WEBDAV}/empty.mkv
    find $MC_DIR_WEBDAV -type f -name '*.mkv' -or -name '*.mp4' > $webdav_video_file
    close=$(inotifywait --fromfile $webdav_video_file -e close --format "%w")
    vmtouch -qe $close
    sleep 60

done &
