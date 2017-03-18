#!/bin/bash
source $(dirname $0)/00.conf

webdav_video_file=$MC_DIR_TMP/webdav_video_file
find $MC_DIR_WEBDAV -type f -name '*.mkv' -or -name '*.mp4' > $webdav_video_file

while true;do

    open=$(inotifywait --fromfile $webdav_video_file -e open --format "%w")
    vmtouch -qt $open

done &

while true;do

    close=$(inotifywait --fromfile $webdav_video_file -e close --format "%w")
    vmtouch -qe $close

done &
