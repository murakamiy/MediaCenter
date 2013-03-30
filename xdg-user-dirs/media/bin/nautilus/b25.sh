#!/bin/bash
source $(dirname $0)/../00.conf

xml=${MC_DIR_JOB_FINISHED}/${5}
title=$(xmlsel -t -m '//title' -v '.' $xml)

killall zenity
zenity --question --display=:0.0 --text="<span font_desc='40'>Descrambler ?\n\n$title</span>"
if [ $? -eq 0 ];then
    b25 $2 ${2}.tmp
    mv -f ${2}.tmp $2
    zenity --info --timeout=10 --display=:0.0 --text="<span font_desc='40'>Descrambler finished.\n\n$title</span>"
fi
