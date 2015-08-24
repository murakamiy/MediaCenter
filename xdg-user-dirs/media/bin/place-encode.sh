#!/bin/bash
source $(dirname $0)/00.conf

/usr/bin/thunar $MC_DIR_TITLE_ENCODE
$MC_BIN_DISK_CONTROL -u
