#!/bin/bash

log=/tmp/$(basename $0)

echo '##################################################' >> $log

mount | grep -q '/mnt/ssd_array/video'
if [ $? -ne 0 ];then
    date +"%Y/%m/%d %H:%M:%S.%N mount ssd_array" >> $log
    mount --bind /mnt/ssd_array/video /home/mc/xdg-user-dirs/media/video
fi

if [ -e /home/mc/xdg-user-dirs/media/job/state/usb_disk/power_on ];then
    date +"%Y/%m/%d %H:%M:%S.%N power on usb_disk" >> $log

    hdparm -W1 /dev/sdc 
    hdparm -W1 /dev/sdd 
    hdparm -W1 /dev/sde 
    hdparm -W1 /dev/sdf 

    if [ -e /home/mc/xdg-user-dirs/media/job/state/usb_disk/mount ];then
        date +"%Y/%m/%d %H:%M:%S.%N mount usb_disk" >> $log

        mount -o noatime,stripe=4 /dev/md0p1 /mnt/hd_array
        mount -o noatime /dev/sde1 /mnt/hd
        mount -o noatime /dev/sdf1 /mnt/hd2
        mount --bind /mnt/hd_array/ts_hd /home/mc/xdg-user-dirs/media/video/ts_hd
        mount --bind /mnt/hd/encode_hd   /home/mc/xdg-user-dirs/media/video/encode_hd
    fi
else
    date +"%Y/%m/%d %H:%M:%S.%N power off usb_disk" >> $log
    /home/mc/xdg-user-dirs/media/ubin/usb-disk-power-off >> $log 2>&1
fi