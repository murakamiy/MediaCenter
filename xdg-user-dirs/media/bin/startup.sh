#!/bin/bash
source $(dirname $0)/00.conf

echo -n > ${MC_DIR_LOG}/usb-disk.log

log "start"

find $MC_DIR_RECORDING $MC_DIR_RECORD_FINISHED $MC_DIR_ENCODING $MC_DIR_PLAY -type f -name '*.xml' -delete

df=$(LANG=C df -P | grep '/$' | awk '{ printf("%d\n", $(NF - 1)) }')
if [ $df -gt $MC_SSD_THRESHOLD ];then
    $MC_BIN_USB_MOUNT > ${MC_DIR_LOG}/usb-disk.log 2>&1
    bash $MC_BIN_MIGRATE lazy
fi

running=$(find $MC_DIR_PLAY $MC_DIR_ENCODING -type f -name '*.xml' -printf '%f ')
if [ -z "$running" ];then
    $MC_BIN_USB_POWER_OFF >> ${MC_DIR_LOG}/usb-disk.log 2>&1
fi

log "end"
