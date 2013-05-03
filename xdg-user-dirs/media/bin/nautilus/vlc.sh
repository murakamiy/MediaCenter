#!/bin/bash
source $(dirname $0)/../00.conf

(
touch $MC_DIR_RECORDING/vlc_$$.xml
sleep 3600
/bin/rm $MC_DIR_RECORDING/vlc_$$.xml
) &

$MC_BIN_MYVLC $2
