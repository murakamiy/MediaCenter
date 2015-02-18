#!/bin/bash

size_spec=72 # terabyte

rrd_dir=/home/mc/xdg-user-dirs/media/bin/rrd
png_dir=${rrd_dir}/png

font_name=/usr/share/fonts/truetype/takao-gothic/TakaoPGothic.ttf
font_color=black

cat /sys/fs/ext4/sda1/lifetime_write_kbytes > ${rrd_dir}/tbw_today

if [ -f ${rrd_dir}/tbw_yesterday ];then

    size_today=$(cat ${rrd_dir}/tbw_today)
    size_yesterday=$(cat ${rrd_dir}/tbw_yesterday)
    written_today=$(echo "($size_today - $size_yesterday) / 1024 / 1024" | bc)
    written_total=$(echo "$size_today / 1024 / 1024 / 1024" | bc)
    remain=$(echo "100 - $written_total * 100 / $size_spec" | bc)
    today=$(date +%Y/%m/%d)

    if [ -n "$MC_DIR_FILE_SIZE" -a -d "$MC_DIR_FILE_SIZE" ];then

        size_ts=$(find $MC_DIR_FILE_SIZE -type f -name '*.ts' -exec cat '{}' \; | awk '
BEGIN { ttl = 0 }
{ ttl += $1 / 1024 / 1024 }
END { printf("%.1f", ttl / 1024) }')
        size_mp4=$(find $MC_DIR_FILE_SIZE -type f -name '*.mp4' -exec cat '{}' \; | awk '
BEGIN { ttl = 0 }
{ ttl += $1 / 1024 / 1024 }
END { printf("%.1f", ttl / 1024) }')

        find $MC_DIR_FILE_SIZE -type f -delete
    fi

    if [ $written_today -lt 40 ];then
        color=green
    elif [ $written_today -lt 80 ];then
        color=yellow
    else
        color=red
    fi

    convert -size 640x360 xc:$color \
    -font $font_name -pointsize 34 -fill $font_color \
    -draw "text 10,50 'SSD Total Bytes Written  $today'" \
    -font $font_name -pointsize 34 -fill $font_color \
    -draw "text 10,100 'ts : $size_ts GB        mp4 : $size_mp4 GB'" \
    -font $font_name -pointsize 110 -fill $font_color \
    -draw "text 10,220 '$written_today GB'" \
    -font $font_name -pointsize 110 -fill $font_color \
    -draw "text 10,330 '$remain %'" \
    ${png_dir}/daily/dw.png

fi

/bin/mv ${rrd_dir}/tbw_today ${rrd_dir}/tbw_yesterday
