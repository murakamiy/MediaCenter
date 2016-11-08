#!/bin/bash

watch_file=/tmp/play-station-controller

while true;do
    touch $watch_file
    inotifywait -e delete_self $watch_file
    startxfce4
    sleep 5
done
