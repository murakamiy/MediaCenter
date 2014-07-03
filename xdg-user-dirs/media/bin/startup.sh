#!/bin/bash
source $(dirname $0)/00.conf

log "start"

mkdir -p $MC_DIR_TMP
echo -n > ${MC_DIR_LOG}/usb-disk.log
find $MC_DIR_RECORDING $MC_DIR_RECORD_FINISHED $MC_DIR_ENCODING $MC_DIR_PLAY -type f -name '*.xml' -delete
$MC_BIN_USB_CONTROL -w
$MC_BIN_USB_POWER_OFF >> ${MC_DIR_LOG}/usb-disk.log 2>&1
sudo /etc/init.d/sixad restart
/bin/rm $MC_STAT_POWEROFF
bash $($MC_BIN_REALPATH /home/mc/work/invoke.sh)

log "end"
