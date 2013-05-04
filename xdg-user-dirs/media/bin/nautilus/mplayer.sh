#!/bin/bash
source $(dirname $0)/../00.conf

(
touch $MC_DIR_RECORDING/mplayer_$$.xml
sleep 1800
/bin/rm $MC_DIR_RECORDING/mplayer_$$.xml
) &

exec $MC_BIN_MYMPLAYER -t $2
