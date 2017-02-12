#!/bin/bash
source $(dirname $0)/00.conf

log "start"

mkdir -p $MC_DIR_TMP
mkdir -p $MC_DIR_FIFO
for f in $(find $MC_DIR_RECORDING $MC_DIR_RECORD_FINISHED $MC_DIR_ENCODING $MC_DIR_ENCODING_CPU $MC_DIR_ENCODING_GPU $MC_DIR_PLAY -type f -name '*.xml');do
    log "failed: $f"
    mv -f $f $MC_DIR_FAILED
done

rm -f $MC_STAT_POWEROFF
rm -f $MC_ABORT_SHUTDOWN

$MC_BIN_DISK_CONTROL -o

log "end"
