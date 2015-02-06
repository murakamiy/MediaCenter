#!/bin/bash
source $(dirname $0)/../00.conf

(
touch $MC_DIR_PLAY/mplayer_$$.xml
sleep 1800
/bin/rm $MC_DIR_PLAY/mplayer_$$.xml
) &

exec $MC_BIN_MYMPLAYER $2
