#!/bin/bash

if [ -z "$MC_DIR_FILE_SIZE" -o ! -d "$MC_DIR_FILE_SIZE" ];then
    exit
fi

size_spec=72 # terabyte

rrd_dir=/home/mc/xdg-user-dirs/media/bin/rrd
png_dir=${rrd_dir}/png

font_name=/usr/share/fonts/truetype/takao-gothic/TakaoPGothic.ttf
font_color=black

today=$(awk 'BEGIN { printf("%s\n", strftime("%Y%m%d", systime())) }')
one_day_before=$(awk 'BEGIN { printf("%s\n", strftime("%Y%m%d", systime() - 60 * 60 * 24)) }')
two_day_before=$(awk 'BEGIN { printf("%s\n", strftime("%Y%m%d", systime() - 60 * 60 * 48)) }')
yesterday=$one_day_before

cat /sys/fs/ext4/sdb1/lifetime_write_kbytes > ${MC_DIR_FILE_SIZE}/tbw_${today}

if [ -f ${MC_DIR_FILE_SIZE}/tbw_${two_day_before} ];then

    size_new=$(cat ${MC_DIR_FILE_SIZE}/tbw_${one_day_before})
    size_old=$(cat ${MC_DIR_FILE_SIZE}/tbw_${two_day_before})
    written_yesterday=$(echo "($size_new - $size_old) / 1024 / 1024" | bc)
    written_total=$(echo "$size_new / 1024 / 1024 / 1024" | bc)
    remain=$(echo "100 - $written_total * 100 / $size_spec" | bc)

    size_ts=$(find $MC_DIR_FILE_SIZE -type f -name "${yesterday}*.ts" -exec cat '{}' \; | awk '
BEGIN { ttl = 0 }
{ ttl += $1 / 1024 / 1024 }
END { printf("%.1f", ttl / 1024) }')

    size_mkv=$(find $MC_DIR_FILE_SIZE -type f -name "${yesterday}*.mkv" -exec cat '{}' \; | awk '
BEGIN { ttl = 0 }
{ ttl += $1 / 1024 / 1024 }
END { printf("%.1f", ttl / 1024) }')

    if [ $written_yesterday -lt 40 ];then
        color=green
    elif [ $written_yesterday -lt 80 ];then
        color=yellow
    else
        color=red
    fi

    convert -size 640x360 xc:$color \
    -font $font_name -pointsize 34 -fill $font_color \
    -draw "text 10,50 'SSD Total Bytes Written  $yesterday'" \
    -font $font_name -pointsize 34 -fill $font_color \
    -draw "text 10,100 'ts : $size_ts GB        mkv : $size_mkv GB'" \
    -font $font_name -pointsize 110 -fill $font_color \
    -draw "text 10,220 '$written_yesterday GB'" \
    -font $font_name -pointsize 110 -fill $font_color \
    -draw "text 10,330 '$remain %'" \
    ${png_dir}/daily/dw.png

fi

find $MC_DIR_FILE_SIZE -type f -ctime +7 -delete
