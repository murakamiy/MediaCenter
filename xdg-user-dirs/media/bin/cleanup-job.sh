#!/bin/bash
source $(dirname $0)/00.conf

log "start"

find $MC_DIR_RECORDING $MC_DIR_RECORD_FINISHED $MC_DIR_ENCODING $MC_DIR_PLAY -type f -name '*.xml' -delete

log "end"
