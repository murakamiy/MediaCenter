#!/bin/bash

log_file=/tmp/ibm-usb-keyboard

date +"%Y/%m/%d %H:%M:%S.%N START" >> $log_file

(
sleep 3
su mc -c "xmodmap -display :0.0 ~/.Xmodmap"  >> $log_file 2>&1
) &

date +"%Y/%m/%d %H:%M:%S.%N END" >> $log_file
