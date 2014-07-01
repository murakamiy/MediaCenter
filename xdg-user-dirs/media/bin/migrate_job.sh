#!/bin/bash
source $(dirname $0)/00.conf

function do_migrate() {

df=$(LANG=C df -P | grep '/$' | awk '{ printf("%d\n", $(NF - 1)) }')
if [ $df -gt $MC_SSD_THRESHOLD ];then
    bash $MC_BIN_MIGRATE lazy

    running=$(find $MC_DIR_PLAY $MC_DIR_ENCODING -type f -name '*.xml' -printf '%f ')
    if [ -z "$running" ];then
        $MC_BIN_USB_POWER_OFF >> ${MC_DIR_LOG}/usb-disk.log 2>&1
    fi
fi

}

lock_file=/tmp/usb_migrate_job
lockfile-create $lock_file
if [ $? -ne 0 ];then
    echo "lockfile-create failed: $0"
    exit 1
fi
lockfile-touch $lock_file &
pid_lock=$!

do_migrate

kill -TERM $pid_lock
lockfile-remove $lock_file
