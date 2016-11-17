#!/bin/bash
source $(dirname $0)/00.conf

case $1 in
    login_session)
        watch_file=/tmp/play-station-controller
        while true;do
            touch $watch_file
            inotifywait -e delete_self $watch_file
            startxfce4
            sleep 3
        done
        ;;
    logout_session)
        echo disconnect | sudo /usr/bin/bluetoothctl
        find $MC_DIR_PLAY -type f -name '*.xml' -delete
        xfce4-session-logout --logout
        ;;
esac
