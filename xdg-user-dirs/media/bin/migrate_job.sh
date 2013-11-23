#!/bin/bash
source $(dirname $0)/00.conf
lock_file=/tmp/usb_migrate_job

lockfile-create $lock_file
lockfile-touch $lock_file &
pid_lock=$!

if [ -f $MC_STAT_MIGRATE ];then
    exit
fi
touch $MC_STAT_MIGRATE

kill -TERM $pid_lock
lockfile-remove $lock_file


log "start"
df=$(LANG=C df -P | grep '/$' | awk '{ printf("%d\n", $(NF - 1)) }')
if [ $df -gt $MC_SSD_THRESHOLD ];then
    $MC_BIN_USB_MOUNT >> ${MC_DIR_LOG}/usb-disk.log 2>&1
    bash $MC_BIN_MIGRATE lazy

    running=$(find $MC_DIR_PLAY $MC_DIR_ENCODING -type f -name '*.xml' -printf '%f ')
    if [ -z "$running" ];then
        $MC_BIN_USB_POWER_OFF >> ${MC_DIR_LOG}/usb-disk.log 2>&1
    fi
fi
log "end"


lockfile-create $lock_file
lockfile-touch $lock_file &
pid_lock=$!

/bin/rm $MC_STAT_MIGRATE

kill -TERM $pid_lock
lockfile-remove $lock_file
