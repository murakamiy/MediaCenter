#!/bin/bash
source $(dirname $0)/00.conf

(
    touch $MC_SESSION_RESTART
    sleep 120
    /bin/rm -f $MC_SESSION_RESTART
) &

xfce4-session-logout --logout
