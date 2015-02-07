#!/bin/bash
source $(dirname $0)/00.conf

log "start"

bash $MC_BIN_ATD regist
mkdir -p $MC_DIR_TMP
echo -n > ${MC_DIR_LOG}/usb-disk.log
for f in $(find $MC_DIR_RECORDING $MC_DIR_RECORD_FINISHED $MC_DIR_ENCODING $MC_DIR_PLAY -type f -name '*.xml');do
    log "failed: $f"
    /bin/mv $f $MC_DIR_FAILED
done
$MC_BIN_USB_CONTROL -w
$MC_BIN_USB_POWER_OFF >> ${MC_DIR_LOG}/usb-disk.log 2>&1
/bin/rm $MC_STAT_POWEROFF
/bin/rm $MC_ABORT_SHUTDOWN
sudo $MC_BIN_SIXAD start

size_spec=72
size_kb=$(cat /sys/fs/ext4/sda1/lifetime_write_kbytes)
size_tb=$(($size_kb / 1024 / 1024 / 1024))
size_remain=$(($size_spec - $size_tb))
zenity --info --no-wrap --timeout=30 --display=:0.0 --text="<span font_desc='40'>SSD LIFE: ${size_spec}TB - ${size_tb}TB = ${size_remain}TB</span>" &

bash $($MC_BIN_REALPATH /home/mc/work/invoke.sh) &

log "end"
