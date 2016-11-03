#!/bin/bash

watch_file=/tmp/play-station-controller-add

touch $watch_file
inotifywait -e attrib $watch_file

startxfce4
# export DISPLAY=:0
# xset dpms force on
# 
# chvt 2
# sleep 10
# chvt 1
