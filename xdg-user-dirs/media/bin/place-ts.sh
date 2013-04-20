#!/bin/bash
source $(dirname $0)/00.conf

$MC_BIN_USB_POWER_ON
/usr/bin/nautilus $MC_DIR_TITLE_TS
