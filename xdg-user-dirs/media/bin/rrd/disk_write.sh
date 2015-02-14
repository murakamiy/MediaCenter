#!/bin/bash

rrd_dir=/home/mc/xdg-user-dirs/media/bin/rrd
png_dir=${rrd_dir}/png

font_name=/usr/share/fonts/truetype/takao-gothic/TakaoPGothic.ttf
font_color=black

cat /sys/fs/ext4/sda1/lifetime_write_kbytes > ${rrd_dir}/tbw_today

if [ -f ${rrd_dir}/tbw_yesterday ];then

    size_today=$(cat ${rrd_dir}/tbw_today)
    size_yesterday=$(cat ${rrd_dir}/tbw_yesterday)
    written=$(echo "($size_today - $size_yesterday) / 1024 / 1024" | bc)
    today=$(date +%Y/%m/%d)

    if [ $written -lt 40 ];then
        color=green
    elif [ $written -lt 80 ];then
        color=yellow
    else
        color=red
    fi

    convert -size 640x360 xc:$color \
    -font $font_name -pointsize 50 -fill $font_color \
    -draw "text 10,60 'SSD Total Bytes Written'" \
    -font $font_name -pointsize 60 -fill $font_color \
    -draw "text 10,140 '$today'" \
    -font $font_name -pointsize 140 -fill $font_color \
    -draw "text 10,320 '$written GB'" \
    ${png_dir}/daily/dw.png

fi

/bin/mv ${rrd_dir}/tbw_today ${rrd_dir}/tbw_yesterday
