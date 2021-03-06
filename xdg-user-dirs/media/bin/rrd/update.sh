#!/bin/bash

db_file=/home/mc/xdg-user-dirs/media/bin/rrd/stat.rrd

iostat_arr=($(LANG=C iostat -ym -j ID 60 1 |
awk '
BEGIN {
    CPU_USER = 0
    CPU_NICE = 0
    CPU_SYSTEM = 0
    CPU_IOWAIT = 0
    CPU_STEAL = 0
    CPU_IDLE = 0
    HD_READ = 0
    HD_WRITE = 0
    HD2_READ = 0
    HD2_WRITE = 0

    cpu_line = 0
    hd_line = 0
    hd2_line = 0
}

/^avg-cpu: / {
    cpu_line = 1
    next
}
/^ata-TOSHIBA_MQ01ABD050_55DTT3QDT/ {
    hd_line = 1
    next
}
/^ata-WDC_WD60EFRX-68L0BN1_WD-WX11D6651KFD/ {
    hd2_line = 1
    next
}

{
    if (cpu_line == 1) {
        cpu_line = 0
        CPU_USER = $1
        CPU_NICE = $2
        CPU_SYSTEM = $3
        CPU_IOWAIT = $4
        CPU_STEAL = $5
        CPU_IDLE = $6
    }
    else if (hd2_line == 1) {
        hd2_line = 0
        HD2_READ = $2
        HD2_WRITE = $3
    }
    else if (hd_line == 1) {
        hd_line = 0
        HD_READ = $2
        HD_WRITE = $3
    }
}

END {

    printf("%s %s %s %s %s %s %s %s %s %s\n",
            CPU_USER,
            CPU_NICE,
            CPU_SYSTEM,
            CPU_IOWAIT,
            CPU_STEAL,
            CPU_IDLE,
            HD_READ,
            HD_WRITE,
            HD2_READ,
            HD2_WRITE)
}'))

CPU_USER=${iostat_arr[0]}
CPU_NICE=${iostat_arr[1]}
CPU_SYSTEM=${iostat_arr[2]}
CPU_IOWAIT=${iostat_arr[3]}
CPU_STEAL=${iostat_arr[4]}
CPU_IDLE=${iostat_arr[5]}
SSD_READ=0
SSD_WRITE=0
HD_ARRAY_1_READ=0
HD_ARRAY_1_WRITE=0
HD_ARRAY_2_READ=0
HD_ARRAY_2_WRITE=0
HD_ARRAY_3_READ=0
HD_ARRAY_3_WRITE=0
HD_RAID_READ=0
HD_RAID_WRITE=0
HD_READ=${iostat_arr[6]}
HD_WRITE=${iostat_arr[7]}
HD2_READ=${iostat_arr[8]}
HD2_WRITE=${iostat_arr[9]}

LOAD_AVERAGE=$(uptime | awk -F 'load average: ' '{ print $2 }' | awk -F , '{ print $1 }')
DISK_USAGE=$(LANG=C df -P | grep '/mnt/hd_small$' | awk '{ printf("%d\n", $(NF - 1)) }')

mem_arr=($(free -m | grep '^Mem:' | awk '
{
    total = $2
    used = $3
    free = $4
    shared = $5
    buffers = 0
    cached = $6

    printf("%d %d %d %d %d %d\n", used, free, shared, buffers, cached, total)
}'))

MEMORY_USED=${mem_arr[0]}
MEMORY_FREE=${mem_arr[1]}
MEMORY_SHARED=${mem_arr[2]}
MEMORY_BUFFERS=${mem_arr[3]}
MEMORY_CACHED=${mem_arr[4]}
MEMORY_TOTAL=${mem_arr[5]}


sensors_arr=($(LANG=C sensors -A | awk '
BEGIN {

    TEMP_CPU = 0
    TEMP_CPU_0 = 0
    TEMP_CPU_1 = 0
    TEMP_CPU_2 = 0
    TEMP_CPU_3 = 0
    TEMP_MOTHER_BORD_1 = 0
    TEMP_MOTHER_BORD_2 = 0
    VOLT_IN0 = 0
    VOLT_IN1 = 0
    VOLT_IN2 = 0
    VOLT_IN3 = 0
    VOLT_IN4 = 0
    VOLT_IN5 = 0
    VOLT_IN6 = 0
    VOLT_3VSB = 0
    VOLT_VBAT = 0
    FAN1 = 0
    FAN2 = 0
}

{
    if (match($0, "^Core 0:") != 0) {
        TEMP_CPU_0 = $3
    }
    else if (match($0, "^Core 1:") != 0) {
        TEMP_CPU_1 = $3
    }
    else if (match($0, "^Core 2:") != 0) {
        TEMP_CPU_2 = $3
    }
    else if (match($0, "^Core 3:") != 0) {
        TEMP_CPU_3 = $3
    }
    else if (match($1, "fan1:") != 0) {
        FAN1 = $2
    }
    else if (match($1, "fan2:") != 0) {
        FAN2 = $2
    }
    else if (match($1, "SYSTIN:") != 0) {
        TEMP_MOTHER_BORD_1 = $2
    }
    else if (match($1, "CPUTIN:") != 0) {
        TEMP_MOTHER_BORD_2 = $2
    }
}

END {
    TEMP_CPU = (TEMP_CPU_0 + TEMP_CPU_1 + TEMP_CPU_2 + TEMP_CPU_3) / 4

    printf("%.1f %.1f %.1f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %d %d\n",
            TEMP_CPU,
            TEMP_MOTHER_BORD_1,
            TEMP_MOTHER_BORD_2,
            VOLT_IN0,
            VOLT_IN1,
            VOLT_IN2,
            VOLT_IN3,
            VOLT_IN4,
            VOLT_IN5,
            VOLT_IN6,
            VOLT_3VSB,
            VOLT_VBAT,
            FAN1,
            FAN2)
}'))

TEMP_CPU=${sensors_arr[0]}
TEMP_MOTHER_BORD_1=${sensors_arr[1]}
TEMP_MOTHER_BORD_2=${sensors_arr[2]}
VOLT_IN0=${sensors_arr[3]}
VOLT_IN1=${sensors_arr[4]}
VOLT_IN2=${sensors_arr[5]}
VOLT_IN3=${sensors_arr[6]}
VOLT_IN4=${sensors_arr[7]}
VOLT_IN5=${sensors_arr[8]}
VOLT_IN6=${sensors_arr[9]}
VOLT_3VSB=${sensors_arr[10]}
VOLT_VBAT=${sensors_arr[11]}
FAN1=${sensors_arr[12]}
FAN2=${sensors_arr[13]}


# cat << EOF
# CPU_USER            $CPU_USER
# CPU_NICE            $CPU_NICE
# CPU_SYSTEM          $CPU_SYSTEM
# CPU_IOWAIT          $CPU_IOWAIT
# CPU_STEAL           $CPU_STEAL
# CPU_IDLE            $CPU_IDLE
# SSD_READ            $SSD_READ
# SSD_WRITE           $SSD_WRITE
# HD_ARRAY_1_READ     $HD_ARRAY_1_READ
# HD_ARRAY_1_WRITE    $HD_ARRAY_1_WRITE
# HD_ARRAY_2_READ     $HD_ARRAY_2_READ
# HD_ARRAY_2_WRITE    $HD_ARRAY_2_WRITE
# HD_ARRAY_3_READ     $HD_ARRAY_3_READ
# HD_ARRAY_3_WRITE    $HD_ARRAY_3_WRITE
# HD_RAID_READ        $HD_RAID_READ
# HD_RAID_WRITE       $HD_RAID_WRITE
# HD_READ             $HD_READ
# HD_WRITE            $HD_WRITE
# LOAD_AVERAGE        $LOAD_AVERAGE
# MEMORY_USED         $MEMORY_USED
# MEMORY_FREE         $MEMORY_FREE
# MEMORY_SHARED       $MEMORY_SHARED
# MEMORY_BUFFERS      $MEMORY_BUFFERS
# MEMORY_CACHED       $MEMORY_CACHED
# DISK_USAGE          $DISK_USAGE
# TEMP_CPU            $TEMP_CPU
# TEMP_MOTHER_BORD_1  $TEMP_MOTHER_BORD_1
# TEMP_MOTHER_BORD_2  $TEMP_MOTHER_BORD_2
# VOLT_IN0            $VOLT_IN0
# VOLT_IN1            $VOLT_IN1
# VOLT_IN2            $VOLT_IN2
# VOLT_IN3            $VOLT_IN3
# VOLT_IN4            $VOLT_IN4
# VOLT_IN5            $VOLT_IN5
# VOLT_IN6            $VOLT_IN6
# VOLT_3VSB           $VOLT_3VSB
# VOLT_VBAT           $VOLT_VBAT
# FAN1                $FAN1
# FAN2                $FAN2
# EOF


rrdtool update $db_file \
N:$CPU_USER:$CPU_NICE:$CPU_SYSTEM:$CPU_IOWAIT:$CPU_STEAL:$CPU_IDLE:$SSD_READ:$SSD_WRITE:$HD_ARRAY_1_READ:$HD_ARRAY_1_WRITE:$HD_ARRAY_2_READ:$HD_ARRAY_2_WRITE:$HD_ARRAY_3_READ:$HD_ARRAY_3_WRITE:$HD_RAID_READ:$HD_RAID_WRITE:$HD_READ:$HD_WRITE:$HD2_READ:$HD2_WRITE:$LOAD_AVERAGE:$MEMORY_USED:$MEMORY_FREE:$MEMORY_SHARED:$MEMORY_BUFFERS:$MEMORY_CACHED:$DISK_USAGE:$TEMP_CPU:$TEMP_MOTHER_BORD_1:$TEMP_MOTHER_BORD_2:$VOLT_IN0:$VOLT_IN1:$VOLT_IN2:$VOLT_IN3:$VOLT_IN4:$VOLT_IN5:$VOLT_IN6:$VOLT_3VSB:$VOLT_VBAT:$FAN1:$FAN2
