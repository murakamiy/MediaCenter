#!/bin/bash

# date --date "20131101 00:00:00" +%s
# 1383231600
#
# DS:データセット名:データ型:heatbeat:min:max
# RRA:CFタイプ:xff:steps:rows

db_file=/home/mc/xdg-user-dirs/media/bin/rrd/stat.rrd


rrdtool create $db_file \
--start 1383231600 \
--step 300 \
DS:CPU_USER:GAUGE:600:0:100 \
DS:CPU_NICE:GAUGE:600:0:100 \
DS:CPU_SYSTEM:GAUGE:600:0:100 \
DS:CPU_IOWAIT:GAUGE:600:0:100 \
DS:CPU_STEAL:GAUGE:600:0:100 \
DS:CPU_IDLE:GAUGE:600:0:100 \
DS:SSD_READ:GAUGE:600:0:600 \
DS:SSD_WRITE:GAUGE:600:0:600 \
DS:HD_ARRAY_1_READ:GAUGE:600:0:300 \
DS:HD_ARRAY_1_WRITE:GAUGE:600:0:300 \
DS:HD_ARRAY_2_READ:GAUGE:600:0:300 \
DS:HD_ARRAY_2_WRITE:GAUGE:600:0:300 \
DS:HD_ARRAY_3_READ:GAUGE:600:0:300 \
DS:HD_ARRAY_3_WRITE:GAUGE:600:0:300 \
DS:HD_RAID_READ:GAUGE:600:0:600 \
DS:HD_RAID_WRITE:GAUGE:600:0:600 \
DS:HD_READ:GAUGE:600:0:300 \
DS:HD_WRITE:GAUGE:600:0:300 \
DS:LOAD_AVERAGE:GAUGE:600:0:4 \
DS:MEMORY:GAUGE:600:0:7693 \
DS:DISK_USAGE:GAUGE:600:0:100 \
DS:TEMP_CPU:GAUGE:600:0:105 \
DS:TEMP_MOTHER_BORD_1:GAUGE:600:0:105 \
DS:TEMP_MOTHER_BORD_2:GAUGE:600:0:105 \
DS:VOLT_IN0:GAUGE:600:0:3.06 \
DS:VOLT_IN1:GAUGE:600:0:3.06 \
DS:VOLT_IN2:GAUGE:600:0:3.06 \
DS:VOLT_IN3:GAUGE:600:0:3.06 \
DS:VOLT_IN4:GAUGE:600:0:3.06 \
DS:VOLT_IN5:GAUGE:600:0:3.06 \
DS:VOLT_IN6:GAUGE:600:0:3.06 \
DS:VOLT_3VSB:GAUGE:600:0:6.12 \
DS:VOLT_VBAT:GAUGE:600:0:U \
DS:FAN1:GAUGE:600:0:1500 \
DS:FAN2:GAUGE:600:0:1600 \
RRA:AVERAGE:0.5:1:8640 \
RRA:AVERAGE:0.5:288:30 \
RRA:MIN:0.5:288:30 \
RRA:MAX:0.5:288:30
