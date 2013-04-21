#!/bin/bash
source $(dirname $0)/00.conf

$MC_BIN_DISK_POWER_CONTROL -k
/usr/bin/nautilus $MC_DIR_TITLE_ENCODE
$MC_BIN_USB_POWER_ON
