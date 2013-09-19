#!/bin/bash
source $(dirname $0)/00.conf
log=/tmp/$(basename $0)

arr=($($MC_BIN_USB_CONTROL -d))
echo -e "\nusb disk device : ${arr[@]}\n" >> $log

if [ -e /home/mc/xdg-user-dirs/media/job/state/usb_disk/power_on ];then
    date +"%Y/%m/%d %H:%M:%S.%N power on usb_disk" >> $log

    if [ -e /home/mc/xdg-user-dirs/media/job/state/usb_disk/mount ];then
        date +"%Y/%m/%d %H:%M:%S.%N mount usb_disk" >> $log

        mount -o noatime,stripe=512 $MC_DEVICE_USB_DISK_TS /mnt/hd_array
        mount -o noatime ${arr[2]}1 /mnt/hd
        mount -o noatime ${arr[3]}1 /mnt/hd2
        mount --bind /mnt/hd_array/ts_hd /home/mc/xdg-user-dirs/media/video/ts_hd
        mount --bind /mnt/hd/encode_hd   /home/mc/xdg-user-dirs/media/video/encode_hd
    fi
else
    date +"%Y/%m/%d %H:%M:%S.%N power off usb_disk" >> $log
    /home/mc/xdg-user-dirs/media/ubin/usb-disk-power-off >> $log 2>&1
fi
