#!/bin/bash

rrd_dir=/home/mc/xdg-user-dirs/media/bin/rrd
png_dir=${rrd_dir}/png
db_file=${rrd_dir}/stat.rrd


function create_graph_cpu() {

LANG=C rrdtool graph ${png_dir}/${cycle}/cpu.png \
--title "CPU usage $start_string" \
--imgformat PNG \
--start "$start_param" \
--end "$end_param" \
--x-grid $x_grid \
--upper-limit 100 \
--lower-limit 0 \
--rigid \
--width 700 \
--height 300 \
DEF:USER=$db_file:CPU_USER:AVERAGE \
DEF:NICE=$db_file:CPU_NICE:AVERAGE \
DEF:IOWAIT=$db_file:CPU_IOWAIT:AVERAGE \
DEF:SYSTEM=$db_file:CPU_SYSTEM:AVERAGE \
DEF:STEAL=$db_file:CPU_STEAL:AVERAGE \
DEF:IDLE=$db_file:CPU_IDLE:AVERAGE \
CDEF:CPU_ALL=USER,NICE,SYSTEM,IOWAIT,STEAL,+,+,+,+ \
VDEF:IOWAIT_MAX=IOWAIT,MAXIMUM \
VDEF:USER_MAX=USER,MAXIMUM \
VDEF:NICE_MAX=NICE,MAXIMUM \
COMMENT:" " \
AREA:NICE#0000FF:NICE \
STACK:USER#00FF00:USER \
STACK:SYSTEM#FFFF00:SYSTEM \
COMMENT:" \j" \
COMMENT:" " \
STACK:STEAL#000000:STEAL \
STACK:IOWAIT#FF0000:IOWAIT \
STACK:IDLE#00FFFF:IDLE \
COMMENT:" \j" \
COMMENT:" " \
GPRINT:CPU_ALL:MIN:"CPU usage minimum\: %2.2lf%%" \
GPRINT:CPU_ALL:MAX:"CPU usage maximum\: %2.2lf%%" \
GPRINT:CPU_ALL:AVERAGE:"CPU usage average\: %2.2lf%%" \
COMMENT:" \j" \
COMMENT:" " \
GPRINT:USER_MAX:"USER maximum\: %2.2lf%%" \
GPRINT:NICE_MAX:"NICE maximum\: %2.2lf%%" \
GPRINT:IOWAIT_MAX:"IO wait maximum\: %2.2lf%%" \
COMMENT:" \j"

}

function create_graph_io_raid() {

LANG=C rrdtool graph ${png_dir}/${cycle}/io_raid.png \
--title "IO HD raid $start_string" \
--imgformat PNG \
--start "$start_param" \
--end "$end_param" \
--x-grid $x_grid \
--upper-limit 10 \
--lower-limit -10 \
--rigid \
--width 700 \
--height 300 \
DEF:HD_1_W=$db_file:HD_ARRAY_1_WRITE:AVERAGE \
DEF:HD_2_W=$db_file:HD_ARRAY_2_WRITE:AVERAGE \
DEF:HD_3_W=$db_file:HD_ARRAY_3_WRITE:AVERAGE \
DEF:HD_ALL_W=$db_file:HD_RAID_WRITE:AVERAGE \
DEF:HD_1_R=$db_file:HD_ARRAY_1_READ:AVERAGE \
DEF:HD_2_R=$db_file:HD_ARRAY_2_READ:AVERAGE \
DEF:HD_3_R=$db_file:HD_ARRAY_3_READ:AVERAGE \
DEF:HD_ALL_R=$db_file:HD_RAID_READ:AVERAGE \
CDEF:HD_1_R_NEGATIVE=HD_1_R,-1,* \
CDEF:HD_2_R_NEGATIVE=HD_2_R,-1,* \
CDEF:HD_3_R_NEGATIVE=HD_3_R,-1,* \
CDEF:HD_ALL_R_NEGATIVE=HD_ALL_R,-1,* \
CDEF:HD_1_W_NEGATIVE=HD_1_W,-1,* \
CDEF:HD_2_W_NEGATIVE=HD_2_W,-1,* \
CDEF:HD_3_W_NEGATIVE=HD_3_W,-1,* \
CDEF:HD_ALL_W_NEGATIVE=HD_ALL_W,-1,* \
VDEF:HD_1_W_MAX=HD_1_W,MAXIMUM \
VDEF:HD_2_W_MAX=HD_2_W,MAXIMUM \
VDEF:HD_3_W_MAX=HD_3_W,MAXIMUM \
VDEF:HD_ALL_W_MAX=HD_ALL_W,MAXIMUM \
VDEF:HD_1_R_MAX=HD_1_R,MAXIMUM \
VDEF:HD_2_R_MAX=HD_2_R,MAXIMUM \
VDEF:HD_3_R_MAX=HD_3_R,MAXIMUM \
VDEF:HD_ALL_R_MAX=HD_ALL_R,MAXIMUM \
VDEF:HD_1_W_TOTAL=HD_1_W,TOTAL \
VDEF:HD_2_W_TOTAL=HD_2_W,TOTAL \
VDEF:HD_3_W_TOTAL=HD_3_W,TOTAL \
VDEF:HD_ALL_W_TOTAL=HD_ALL_W,TOTAL \
VDEF:HD_1_R_TOTAL=HD_1_R,TOTAL \
VDEF:HD_2_R_TOTAL=HD_2_R,TOTAL \
VDEF:HD_3_R_TOTAL=HD_3_R,TOTAL \
VDEF:HD_ALL_R_TOTAL=HD_ALL_R,TOTAL \
COMMENT:" " \
AREA:HD_1_W#FF4500:"HD1 write"  \
STACK:HD_2_W#FF6347:"HD2 write" \
STACK:HD_3_W#FF7F50:"HD3 write" \
COMMENT:" \j" \
COMMENT:" " \
AREA:HD_1_R_NEGATIVE#4B0082:"HD1 read"  \
STACK:HD_2_R_NEGATIVE#9400D3:"HD2 read"  \
STACK:HD_3_R_NEGATIVE#9370DB:"HD3 read" \
COMMENT:" \j" \
COMMENT:" " \
LINE1:HD_ALL_W#000000:"raid write" \
LINE1:HD_ALL_R_NEGATIVE#000000:"raid read" \
COMMENT:" \j" \
COMMENT:" write maximum MB/s" \
GPRINT:HD_ALL_W_MAX:"raid \: %3.2lf" \
GPRINT:HD_1_W_MAX:"HD1 \: %3.2lf" \
GPRINT:HD_2_W_MAX:"HD2 \: %3.2lf" \
GPRINT:HD_3_W_MAX:"HD3 \: %3.2lf" \
COMMENT:" \j" \
COMMENT:" read  maximum MB/s" \
GPRINT:HD_ALL_R_MAX:"raid \: %3.2lf" \
GPRINT:HD_1_R_MAX:"HD1 \: %3.2lf" \
GPRINT:HD_2_R_MAX:"HD2 \: %3.2lf" \
GPRINT:HD_3_R_MAX:"HD3 \: %3.2lf" \
COMMENT:" \j" \
COMMENT:" write total MB/s" \
GPRINT:HD_ALL_W_TOTAL:"raid \: %3.2lf" \
GPRINT:HD_1_W_TOTAL:"HD1 \: %3.2lf" \
GPRINT:HD_2_W_TOTAL:"HD2 \: %3.2lf" \
GPRINT:HD_3_W_TOTAL:"HD3 \: %3.2lf" \
COMMENT:" \j" \
COMMENT:" read  total MB/s" \
GPRINT:HD_ALL_R_TOTAL:"raid \: %3.2lf" \
GPRINT:HD_1_R_TOTAL:"HD1 \: %3.2lf" \
GPRINT:HD_2_R_TOTAL:"HD2 \: %3.2lf" \
GPRINT:HD_3_R_TOTAL:"HD3 \: %3.2lf" \
COMMENT:" \j"

}

function create_graph_io() {

LANG=C rrdtool graph ${png_dir}/${cycle}/io.png \
--title "IO SSD HD $start_string" \
--imgformat PNG \
--start "$start_param" \
--end "$end_param" \
--x-grid $x_grid \
--upper-limit 10 \
--lower-limit -10 \
--rigid \
--width 700 \
--height 300 \
DEF:SSD_R=$db_file:SSD_READ:AVERAGE \
DEF:HD_R=$db_file:HD_READ:AVERAGE \
DEF:SSD_W=$db_file:SSD_WRITE:AVERAGE \
DEF:HD_W=$db_file:HD_WRITE:AVERAGE \
CDEF:SSD_R_NEGATIVE=SSD_R,-1,* \
CDEF:HD_R_NEGATIVE=HD_R,-1,* \
VDEF:SSD_R_MAX=SSD_R,MAXIMUM \
VDEF:HD_R_MAX=HD_R,MAXIMUM \
VDEF:SSD_W_MAX=SSD_W,MAXIMUM \
VDEF:HD_W_MAX=HD_W,MAXIMUM \
VDEF:SSD_R_TOTAL=SSD_R,TOTAL \
VDEF:HD_R_TOTAL=HD_R,TOTAL \
VDEF:SSD_W_TOTAL=SSD_W,TOTAL \
VDEF:HD_W_TOTAL=HD_W,TOTAL \
COMMENT:" " \
AREA:SSD_W#FF8C00:"SSD write" \
STACK:HD_W#FFFF00:"HD write" \
COMMENT:" \j" \
COMMENT:" " \
AREA:SSD_R_NEGATIVE#0000FF:"SSD read" \
STACK:HD_R_NEGATIVE#00FF00:"HD read" \
COMMENT:" \j" \
COMMENT:" " \
COMMENT:" write maximum MB/s" \
GPRINT:SSD_W_MAX:"SSD \: %3.2lf" \
GPRINT:HD_W_MAX:"HD \: %3.2lf" \
COMMENT:" \j" \
COMMENT:" " \
COMMENT:" read  maximum MB/s" \
GPRINT:SSD_R_MAX:"SSD \: %3.2lf" \
GPRINT:HD_R_MAX:"HD \: %3.2lf" \
COMMENT:" \j" \
COMMENT:" " \
COMMENT:" write total MB/s" \
GPRINT:SSD_W_TOTAL:"SSD \: %3.2lf" \
GPRINT:HD_W_TOTAL:"HD \: %3.2lf" \
COMMENT:" \j" \
COMMENT:" " \
COMMENT:" read  total MB/s" \
GPRINT:SSD_R_TOTAL:"SSD \: %3.2lf" \
GPRINT:HD_R_TOTAL:"HD \: %3.2lf" \
COMMENT:" \j"

}

function create_graph_temp() {

LANG=C rrdtool graph ${png_dir}/${cycle}/temp.png \
--title "Temparature $start_string" \
--imgformat PNG \
--start "$start_param" \
--end "$end_param" \
--x-grid $x_grid \
--alt-y-grid \
--upper-limit 70 \
--lower-limit 30 \
--rigid \
--width 700 \
--height 300 \
DEF:LOAD_AVERAGE=$db_file:LOAD_AVERAGE:AVERAGE \
DEF:TEMP_CPU=$db_file:TEMP_CPU:AVERAGE \
DEF:FAN1=$db_file:FAN1:AVERAGE \
CDEF:LOAD_AVERAGE_PERCENT=LOAD_AVERAGE,25,1,*,* \
CDEF:TEMP_CPU_PERCENT=TEMP_CPU \
CDEF:FAN1_PERCENT=FAN1,100,*,2000,/,30,- \
VDEF:LOAD_AVERAGE_MAX=LOAD_AVERAGE,MAXIMUM \
VDEF:TEMP_CPU_MAX=TEMP_CPU,MAXIMUM \
VDEF:FAN1_MAX=FAN1,MAXIMUM \
VDEF:LOAD_AVERAGE_MIN=LOAD_AVERAGE,MINIMUM \
VDEF:TEMP_CPU_MIN=TEMP_CPU,MINIMUM \
VDEF:FAN1_MIN=FAN1,MINIMUM \
COMMENT:" " \
AREA:LOAD_AVERAGE_PERCENT#FF1493:"load average" \
AREA:FAN1_PERCENT#6A5ACD:"fan1" \
AREA:TEMP_CPU_PERCENT#FF8C00:"cpu temp" \
COMMENT:" \j" \
COMMENT:"MIN " \
GPRINT:LOAD_AVERAGE_MIN:"load average \: %3.2lf" \
GPRINT:FAN1_MIN:"fan1 \: %4.0lf RPM" \
GPRINT:TEMP_CPU_MIN:"cpu temp \: %3.2lf C" \
COMMENT:" \j" \
COMMENT:"MAX " \
GPRINT:LOAD_AVERAGE_MAX:"load average \: %3.2lf" \
GPRINT:FAN1_MAX:"fan1 \: %4.0lf RPM" \
GPRINT:TEMP_CPU_MAX:"cpu temp \: %3.2lf C" \
COMMENT:" \j"

}


function create_graph_mem() {

LANG=C rrdtool graph ${png_dir}/${cycle}/mem.png \
--title "Memory usage $start_string" \
--imgformat PNG \
--start "$start_param" \
--end "$end_param" \
--x-grid $x_grid \
--upper-limit 8000 \
--width 700 \
--height 300 \
DEF:USED=$db_file:MEMORY_USED:AVERAGE \
DEF:FREE=$db_file:MEMORY_FREE:AVERAGE \
DEF:SHARED=$db_file:MEMORY_SHARED:AVERAGE \
DEF:BUFFERS=$db_file:MEMORY_BUFFERS:AVERAGE \
DEF:CACHED=$db_file:MEMORY_CACHED:AVERAGE \
VDEF:USED_MAX=USED,MAXIMUM \
VDEF:FREE_MAX=FREE,MAXIMUM \
VDEF:SHARED_MAX=SHARED,MAXIMUM \
VDEF:BUFFERS_MAX=BUFFERS,MAXIMUM \
VDEF:CACHED_MAX=CACHED,MAXIMUM \
VDEF:USED_MIN=USED,MINIMUM \
VDEF:FREE_MIN=FREE,MINIMUM \
VDEF:SHARED_MIN=SHARED,MINIMUM \
VDEF:BUFFERS_MIN=BUFFERS,MINIMUM \
VDEF:CACHED_MIN=CACHED,MINIMUM \
COMMENT:" " \
AREA:USED#FFFF00:"used" \
STACK:SHARED#FF8C00:"shared" \
STACK:CACHED#00FF00:"cached" \
STACK:BUFFERS#8A2BE2:"buffers" \
STACK:FREE#0000FF:"free" \
COMMENT:" \j" \
COMMENT:"MIN " \
GPRINT:USED_MIN:"used \: %4.0lf" \
GPRINT:SHARED_MIN:"shared \: %4.0lf" \
GPRINT:CACHED_MIN:"cached \: %4.0lf" \
GPRINT:BUFFERS_MIN:"buffers \: %4.0lf" \
GPRINT:FREE_MIN:"free \: %4.0lf" \
COMMENT:" \j" \
COMMENT:"MAX " \
GPRINT:USED_MAX:"used \: %4.0lf" \
GPRINT:SHARED_MAX:"shared \: %4.0lf" \
GPRINT:CACHED_MAX:"cached \: %4.0lf" \
GPRINT:BUFFERS_MAX:"buffers \: %4.0lf" \
GPRINT:FREE_MAX:"free \: %4.0lf" \
COMMENT:" \j"

}


function create_graph_du() {

LANG=C rrdtool graph ${png_dir}/${cycle}/du.png \
--title "Disk usage $start_string" \
--imgformat PNG \
--start "$start_param" \
--end "$end_param" \
--x-grid $x_grid \
--upper-limit 100  \
--width 700 \
--height 300 \
DEF:DISK_USAGE=$db_file:DISK_USAGE:AVERAGE \
VDEF:DISK_USAGE_MAX=DISK_USAGE,MAXIMUM \
COMMENT:" " \
AREA:DISK_USAGE#696969:"disk usage" \
COMMENT:" \j" \
COMMENT:" " \
GPRINT:DISK_USAGE_MAX:"disk usage max \: %3.0lf" \
COMMENT:" \j"

}

function create_graph_rec() {

LANG=C rrdtool graph ${png_dir}/${cycle}/rec.png \
--title "Reserve $start_string" \
--imgformat PNG \
--start "$start_param" \
--end "$end_param" \
--x-grid $x_grid \
--upper-limit 2.5 \
--lower-limit -2.5 \
--rigid \
--width 700 \
--height 300 \
DEF:T_Prefer=$db_file:T_Prefer:MAX \
DEF:T_Random=$db_file:T_Random:MAX \
DEF:S_Prefer=$db_file:S_Prefer:MAX \
DEF:S_Random=$db_file:S_Random:MAX \
CDEF:S_Prefer_G=S_Prefer,-1,* \
CDEF:S_Random_G=S_Random,-1,* \
COMMENT:" " \
AREA:T_Prefer#FF8C00:"t_prefer" \
STACK:T_Random#8A2BE2:"t_random" \
AREA:S_Prefer_G#FF8C00:"s_prefer" \
STACK:S_Random_G#8A2BE2:"s_random" \
COMMENT:" \j"

}


yesterday=$(awk 'BEGIN { printf("%s\n", strftime("%Y%m%d", systime() - 60 * 60 * 24)) }')

cycle=daily
start_string=$(awk 'BEGIN { printf("%s\n", strftime("%Y/%m/%d", systime() - 60 * 60 * 24)) }')
start_param=$(awk 'BEGIN { printf("%s\n", strftime("%m/%d/%Y 00:00", systime() - 60 * 60 * 24)) }')
end_param='start+24h'
x_grid='HOUR:1:HOUR:1:HOUR:1:0:%H'
create_graph_cpu
create_graph_io_raid
create_graph_io
create_graph_temp
create_graph_mem
create_graph_du

db_file=${rrd_dir}/rec.rrd
create_graph_rec
db_file=${rrd_dir}/stat.rrd


cycle=weekly
start_string=$(awk 'BEGIN { printf("%s\n", strftime("%Y%mw%V\n", systime() - 60 * 60 * 24)) }')
start_param=$(awk '
BEGIN {
    yesterday = systime() - (60 * 60 * 24)
    offset = (strtonum(strftime("%u", yesterday)) - 1) * 60 * 60 * 24
    printf("%s\n", strftime("%m/%d/%Y 00:00", yesterday - offset))
}')
end_param='start+1WEEK'
x_grid='HOUR:12:HOUR:12:DAY:1:0:%d'
create_graph_cpu
create_graph_io_raid
create_graph_io
create_graph_temp
create_graph_mem
create_graph_du

db_file=${rrd_dir}/rec.rrd
create_graph_rec
db_file=${rrd_dir}/stat.rrd


cycle=monthly
start_string=$(awk 'BEGIN { printf("%s\n", strftime("%Y/%m", systime() - 60 * 60 * 24)) }')
start_param=$(awk 'BEGIN { printf("%s\n", strftime("%Y%m01", systime() - 60 * 60 * 24)) }')
end_param='start+1MONTH'
x_grid='DAY:1:DAY:1:DAY:1:0:%d'
create_graph_cpu
create_graph_io_raid
create_graph_io
create_graph_temp
create_graph_mem
create_graph_du

db_file=${rrd_dir}/rec.rrd
create_graph_rec
db_file=${rrd_dir}/stat.rrd



# week debug
# awk '
# BEGIN {
#     for (i = 0; i < 100; i++) {
#         today = systime() + (60 * 60 * 24 * i)
#         yesterday = today - (60 * 60 * 24)
# 
#         week_start_offset = (strtonum(strftime("%u", yesterday)) - 1) * 60 * 60 * 24
#         week_span = yesterday - week_start_offset
# 
# 
#         printf("%s %s %s %s\n", strftime("%Y%m%d", today), strftime("%u", today), strftime("%Y%mw%V", today), strftime("%Y%m%d", week_span))
#     }
# }'
