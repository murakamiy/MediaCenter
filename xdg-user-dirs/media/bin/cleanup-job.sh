#!/bin/bash
source $(dirname $0)/00.conf

log "start"

mkjob=false
if [ -f ${MC_DIR_RECORDING}/mkjob.xml ];then
    mkjob=true
fi

find $MC_DIR_RECORDING $MC_DIR_RECORD_FINISHED $MC_DIR_ENCODING -type f -name '*.xml' -delete

if [ $mkjob = "true" ];then
    bash /home/mc/xdg-user-dirs/media/bin/mkjob.sh
fi

log "end"
