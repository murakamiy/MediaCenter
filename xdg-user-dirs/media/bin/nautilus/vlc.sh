#!/bin/bash
source $(dirname $0)/../00.conf

(
touch $MC_DIR_RECORDING/vlc_$$.xml
sleep 1800
/bin/rm $MC_DIR_RECORDING/vlc_$$.xml
) &

exec $MC_BIN_MYVLC $2
