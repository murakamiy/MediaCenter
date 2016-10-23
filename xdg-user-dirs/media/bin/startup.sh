#!/bin/bash
source $(dirname $0)/00.conf

if [ -f $MC_SESSION_RESTART ];then
    /bin/rm -f $MC_SESSION_RESTART
    exit
fi

log "start"

bash $MC_BIN_ATD regist
mkdir -p $MC_DIR_TMP
for f in $(find $MC_DIR_RECORDING $MC_DIR_RECORD_FINISHED $MC_DIR_ENCODING $MC_DIR_PLAY -type f -name '*.xml');do
    log "failed: $f"
    /bin/mv $f $MC_DIR_FAILED
done

/bin/rm $MC_STAT_POWEROFF
/bin/rm $MC_ABORT_SHUTDOWN
sudo $MC_BIN_SIXAD start

# LANG=C pidstat -dl 60 >> /home/mc/xdg-user-dirs/media/job/state/pidstat/$(date +%Y%m%d) &
# bash $($MC_BIN_REALPATH /home/mc/work/invoke.sh) &
# bash $MC_BIN_RRD_GPU &

log "end"
