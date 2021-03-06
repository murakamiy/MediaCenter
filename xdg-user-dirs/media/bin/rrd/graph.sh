#!/bin/bash

rrd_dir=/home/mc/xdg-user-dirs/media/bin/rrd
png_dir=${rrd_dir}/png


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
--width $width \
--height $height \
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
--width $width \
--height $height \
DEF:HD_1_W=$db_file:HD_ARRAY_1_WRITE:AVERAGE \
DEF:HD_2_W=$db_file:HD_ARRAY_2_WRITE:AVERAGE \
DEF:HD_ALL_W=$db_file:HD_RAID_WRITE:AVERAGE \
DEF:HD_1_R=$db_file:HD_ARRAY_1_READ:AVERAGE \
DEF:HD_2_R=$db_file:HD_ARRAY_2_READ:AVERAGE \
DEF:HD_ALL_R=$db_file:HD_RAID_READ:AVERAGE \
CDEF:HD_1_R_NEGATIVE=HD_1_R,-1,* \
CDEF:HD_2_R_NEGATIVE=HD_2_R,-1,* \
CDEF:HD_ALL_R_NEGATIVE=HD_ALL_R,-1,* \
CDEF:HD_1_W_NEGATIVE=HD_1_W,-1,* \
CDEF:HD_2_W_NEGATIVE=HD_2_W,-1,* \
CDEF:HD_ALL_W_NEGATIVE=HD_ALL_W,-1,* \
VDEF:HD_1_W_MAX=HD_1_W,MAXIMUM \
VDEF:HD_2_W_MAX=HD_2_W,MAXIMUM \
VDEF:HD_ALL_W_MAX=HD_ALL_W,MAXIMUM \
VDEF:HD_1_R_MAX=HD_1_R,MAXIMUM \
VDEF:HD_2_R_MAX=HD_2_R,MAXIMUM \
VDEF:HD_ALL_R_MAX=HD_ALL_R,MAXIMUM \
VDEF:HD_1_W_TOTAL=HD_1_W,TOTAL \
VDEF:HD_2_W_TOTAL=HD_2_W,TOTAL \
VDEF:HD_ALL_W_TOTAL=HD_ALL_W,TOTAL \
VDEF:HD_1_R_TOTAL=HD_1_R,TOTAL \
VDEF:HD_2_R_TOTAL=HD_2_R,TOTAL \
VDEF:HD_ALL_R_TOTAL=HD_ALL_R,TOTAL \
COMMENT:" " \
AREA:HD_1_W#FF4500:"HD1 write"  \
STACK:HD_2_W#FF6347:"HD2 write" \
COMMENT:" \j" \
COMMENT:" " \
AREA:HD_1_R_NEGATIVE#4B0082:"HD1 read"  \
STACK:HD_2_R_NEGATIVE#9400D3:"HD2 read"  \
COMMENT:" \j" \
COMMENT:" " \
LINE1:HD_ALL_W#000000:"raid write" \
LINE1:HD_ALL_R_NEGATIVE#000000:"raid read" \
COMMENT:" \j" \
COMMENT:" write maximum MB/s" \
GPRINT:HD_ALL_W_MAX:"raid \: %3.2lf" \
GPRINT:HD_1_W_MAX:"HD1 \: %3.2lf" \
GPRINT:HD_2_W_MAX:"HD2 \: %3.2lf" \
COMMENT:" \j" \
COMMENT:" read  maximum MB/s" \
GPRINT:HD_ALL_R_MAX:"raid \: %3.2lf" \
GPRINT:HD_1_R_MAX:"HD1 \: %3.2lf" \
GPRINT:HD_2_R_MAX:"HD2 \: %3.2lf" \
COMMENT:" \j" \
COMMENT:" write total MB/s" \
GPRINT:HD_ALL_W_TOTAL:"raid \: %3.2lf" \
GPRINT:HD_1_W_TOTAL:"HD1 \: %3.2lf" \
GPRINT:HD_2_W_TOTAL:"HD2 \: %3.2lf" \
COMMENT:" \j" \
COMMENT:" read  total MB/s" \
GPRINT:HD_ALL_R_TOTAL:"raid \: %3.2lf" \
GPRINT:HD_1_R_TOTAL:"HD1 \: %3.2lf" \
GPRINT:HD_2_R_TOTAL:"HD2 \: %3.2lf" \
COMMENT:" \j"

}

function create_graph_io() {

LANG=C rrdtool graph ${png_dir}/${cycle}/io.png \
--title "IO HD $start_string" \
--imgformat PNG \
--start "$start_param" \
--end "$end_param" \
--x-grid $x_grid \
--upper-limit 10 \
--lower-limit -10 \
--rigid \
--width $width \
--height $height \
DEF:HD_R=$db_file:HD_READ:AVERAGE \
DEF:HD2_R=$db_file:HD2_READ:AVERAGE \
DEF:HD_W=$db_file:HD_WRITE:AVERAGE \
DEF:HD2_W=$db_file:HD2_WRITE:AVERAGE \
CDEF:HD_R_NEGATIVE=HD_R,-1,* \
CDEF:HD2_R_NEGATIVE=HD2_R,-1,* \
VDEF:HD_R_MAX=HD_R,MAXIMUM \
VDEF:HD2_R_MAX=HD2_R,MAXIMUM \
VDEF:HD_W_MAX=HD_W,MAXIMUM \
VDEF:HD2_W_MAX=HD2_W,MAXIMUM \
VDEF:HD_R_TOTAL=HD_R,TOTAL \
VDEF:HD2_R_TOTAL=HD2_R,TOTAL \
VDEF:HD_W_TOTAL=HD_W,TOTAL \
VDEF:HD2_W_TOTAL=HD2_W,TOTAL \
COMMENT:" " \
AREA:HD_W#FF0000:"HD2.5 write" \
STACK:HD2_W#FFFF00:"HD3.5 write" \
COMMENT:" \j" \
COMMENT:" " \
AREA:HD_R_NEGATIVE#9400D3:"HD2.5 read" \
STACK:HD2_R_NEGATIVE#00FF00:"HD3.5 read" \
COMMENT:" \j" \
COMMENT:" " \
COMMENT:" write maximum MB/s" \
GPRINT:HD_W_MAX:"HD2.5 \: %3.2lf" \
GPRINT:HD2_W_MAX:"HD3.5 \: %3.2lf" \
COMMENT:" \j" \
COMMENT:" " \
COMMENT:" read  maximum MB/s" \
GPRINT:HD_R_MAX:"HD2.5 \: %3.2lf" \
GPRINT:HD2_R_MAX:"HD3.5 \: %3.2lf" \
COMMENT:" \j" \
COMMENT:" " \
COMMENT:" write total MB/s" \
GPRINT:HD_W_TOTAL:"HD2.5 \: %3.2lf" \
GPRINT:HD2_W_TOTAL:"HD3.5 \: %3.2lf" \
COMMENT:" \j" \
COMMENT:" " \
COMMENT:" read  total MB" \
GPRINT:HD_R_TOTAL:"HD2.5 \: %3.2lf" \
GPRINT:HD2_R_TOTAL:"HD3.5 \: %3.2lf" \
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
--upper-limit 100 \
--lower-limit 30 \
--rigid \
--width $width \
--height $height \
DEF:TEMP_CPU=$db_file:TEMP_CPU:AVERAGE \
DEF:TEMP_MOTHER_BORD_1=$db_file:TEMP_MOTHER_BORD_1:AVERAGE \
DEF:TEMP_MOTHER_BORD_2=$db_file:TEMP_MOTHER_BORD_2:AVERAGE \
VDEF:TEMP_CPU_MIN=TEMP_CPU,MINIMUM \
VDEF:TEMP_CPU_MAX=TEMP_CPU,MAXIMUM \
VDEF:TEMP_MOTHER_BORD_1_MIN=TEMP_MOTHER_BORD_1,MINIMUM \
VDEF:TEMP_MOTHER_BORD_1_MAX=TEMP_MOTHER_BORD_1,MAXIMUM \
VDEF:TEMP_MOTHER_BORD_2_MIN=TEMP_MOTHER_BORD_2,MINIMUM \
VDEF:TEMP_MOTHER_BORD_2_MAX=TEMP_MOTHER_BORD_2,MAXIMUM \
COMMENT:" " \
AREA:TEMP_MOTHER_BORD_1#8B008B:"systin" \
AREA:TEMP_MOTHER_BORD_2#2E8B57:"cputin" \
AREA:TEMP_CPU#FF8C00:"cpu temp" \
COMMENT:" \j" \
COMMENT:"MIN " \
GPRINT:TEMP_CPU_MIN:"cpu temp \: %3.2lf C" \
GPRINT:TEMP_MOTHER_BORD_1_MIN:"systin \: %3.2lf C" \
GPRINT:TEMP_MOTHER_BORD_2_MIN:"cputin \: %3.2lf C" \
COMMENT:" \j" \
COMMENT:"MAX " \
GPRINT:TEMP_CPU_MAX:"cpu temp \: %3.2lf C" \
GPRINT:TEMP_MOTHER_BORD_1_MAX:"systin \: %3.2lf C" \
GPRINT:TEMP_MOTHER_BORD_2_MAX:"cputin \: %3.2lf C" \
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
--width $width \
--height $height \
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
--upper-limit 50  \
--width $width \
--height $height \
DEF:DISK_USAGE=$db_file:DISK_USAGE:AVERAGE \
VDEF:DISK_USAGE_MAX=DISK_USAGE,MAXIMUM \
COMMENT:" " \
AREA:DISK_USAGE#696969:"disk usage" \
COMMENT:" \j" \
COMMENT:" " \
GPRINT:DISK_USAGE_MAX:"disk usage max \: %3.0lf" \
COMMENT:" \j"

}

function create_graph_gpu() {

LANG=C rrdtool graph ${png_dir}/${cycle}/gpu.png \
--title "GPU usage $start_string" \
--imgformat PNG \
--start "$start_param" \
--end "$end_param" \
--x-grid $x_grid \
--upper-limit 100  \
--width $width \
--height $height \
DEF:GPU_RENDER=$db_file:GPU_RENDER:AVERAGE \
DEF:GPU_BITSTREAM=$db_file:GPU_BITSTREAM:AVERAGE \
VDEF:GPU_RENDER_MAX=GPU_RENDER,MAXIMUM \
VDEF:GPU_BITSTREAM_MAX=GPU_BITSTREAM,MAXIMUM \
COMMENT:" " \
AREA:GPU_RENDER#FF8C00:"render" \
AREA:GPU_BITSTREAM#FFFF00:"bitstream" \
COMMENT:" \j" \
COMMENT:"MAX" \
GPRINT:GPU_RENDER_MAX:"render max\: %2.0lf%%" \
GPRINT:GPU_BITSTREAM_MAX:"bitstream max\: %2.0lf%%" \
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
--width $width \
--height $height \
DEF:T_Prefer=$db_file:T_Prefer:MAX \
DEF:T_Random=$db_file:T_Random:MAX \
DEF:S_Prefer=$db_file:S_Prefer:MAX \
DEF:S_Random=$db_file:S_Random:MAX \
DEF:Encode=$db_file:Encode:MAX \
CDEF:S_Prefer_G=S_Prefer,-1,* \
CDEF:S_Random_G=S_Random,-1,* \
CDEF:Encode_G=Encode,-1,* \
COMMENT:" " \
AREA:T_Prefer#FF8C00:"t_prefer" \
STACK:T_Random#8A2BE2:"t_random" \
STACK:Encode#696969:"encode" \
AREA:S_Prefer_G#FF8C00:"s_prefer" \
STACK:S_Random_G#8A2BE2:"s_random" \
STACK:Encode_G#696969:"encode" \
COMMENT:" \j"

}


yesterday=$(awk 'BEGIN { printf("%s\n", strftime("%Y%m%d", systime() - 60 * 60 * 24)) }')

cycle=daily
start_string=$(awk 'BEGIN { printf("%s\n", strftime("%Y/%m/%d", systime() - 60 * 60 * 24)) }')
start_param=$(awk 'BEGIN { printf("%s\n", strftime("%m/%d/%Y 00:00", systime() - 60 * 60 * 24)) }')
end_param='start+24h'
x_grid='HOUR:1:HOUR:1:HOUR:1:0:%H'
width=700
height=300

db_file=${rrd_dir}/stat.rrd
create_graph_cpu
create_graph_io
create_graph_temp
create_graph_mem
create_graph_du

# db_file=${rrd_dir}/gpu.rrd
# create_graph_gpu
db_file=${rrd_dir}/rec.rrd
create_graph_rec


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
width=2500
height=300

db_file=${rrd_dir}/stat.rrd
create_graph_cpu
create_graph_io
create_graph_temp
create_graph_mem
create_graph_du

# db_file=${rrd_dir}/gpu.rrd
# create_graph_gpu
db_file=${rrd_dir}/rec.rrd
create_graph_rec


cycle=monthly
start_string=$(awk 'BEGIN { printf("%s\n", strftime("%Y/%m", systime() - 60 * 60 * 24)) }')
start_param=$(awk 'BEGIN { printf("%s\n", strftime("%Y%m01", systime() - 60 * 60 * 24)) }')
end_param='start+1MONTH'
x_grid='DAY:1:DAY:1:DAY:1:0:%d'
width=10000
height=300

db_file=${rrd_dir}/stat.rrd
create_graph_cpu
create_graph_io
create_graph_temp
create_graph_mem
create_graph_du

# db_file=${rrd_dir}/gpu.rrd
# create_graph_gpu
db_file=${rrd_dir}/rec.rrd
create_graph_rec



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
