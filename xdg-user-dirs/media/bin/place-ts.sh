#!/bin/bash
source $(dirname $0)/00.conf

$MC_BIN_USB_POWER_ON
/usr/bin/nautilus /home/mc/xdg-user-dirs/media/video/title_ts
