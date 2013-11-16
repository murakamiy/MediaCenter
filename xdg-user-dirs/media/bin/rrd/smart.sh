#!/bin/bash

rrd_dir=/home/mc/xdg-user-dirs/media/bin/rrd
png_dir=${rrd_dir}/png
db_file=${rrd_dir}/smart.rrd

start_date_str=$(awk 'BEGIN { printf("%s\n", strftime("%Y/%m", systime() - 60 * 60 * 24)) }')
start_date=$(awk 'BEGIN { printf("%s\n", strftime("%Y%m01", systime() - 60 * 60 * 24)) }')


function smart_attr() {

    sudo /usr/sbin/smartctl -A /dev/disk/by-id/$1 |
    awk '
    BEGIN {
        value = 0
    }

    /^ID#.+RAW_VALUE$/ { 
        value = 1
        next
    }

    {
        if (value == 1) {
            print $10
        }
    }'

}

arr=($(smart_attr ata-WDC_WD30EZRX-00D8PB0_WD-WMC4N0640397))
HD1_Raw_Read_Error=${arr[0]}
HD1_Spin_Up_Time=${arr[1]}
HD1_Start_Stop=${arr[2]}
HD1_Reallocated_Sec=${arr[3]}
HD1_Seek_Error_Rate=${arr[4]}
HD1_Power_On_Hours=${arr[5]}
HD1_Spin_Retry=${arr[6]}
HD1_Calibration_Ret=${arr[7]}
HD1_Power_Cycle=${arr[8]}
HD1_Power_Off_Ret=${arr[9]}
HD1_Load_Cycle=${arr[10]}
HD1_Temperature=${arr[11]}
HD1_Reallocated_Evt=${arr[12]}
HD1_Current_Pending=${arr[13]}
HD1_Offline_Uncrect=${arr[14]}
HD1_UDMA_CRC_Error=${arr[15]}
HD1_Multi_Zone_Err=${arr[16]}

arr=($(smart_attr ata-WDC_WD30EZRX-00D8PB0_WD-WMC4N0637164))
HD2_Raw_Read_Error=${arr[0]}
HD2_Spin_Up_Time=${arr[1]}
HD2_Start_Stop=${arr[2]}
HD2_Reallocated_Sec=${arr[3]}
HD2_Seek_Error_Rate=${arr[4]}
HD2_Power_On_Hours=${arr[5]}
HD2_Spin_Retry=${arr[6]}
HD2_Calibration_Ret=${arr[7]}
HD2_Power_Cycle=${arr[8]}
HD2_Power_Off_Ret=${arr[9]}
HD2_Load_Cycle=${arr[10]}
HD2_Temperature=${arr[11]}
HD2_Reallocated_Evt=${arr[12]}
HD2_Current_Pending=${arr[13]}
HD2_Offline_Uncrect=${arr[14]}
HD2_UDMA_CRC_Error=${arr[15]}
HD2_Multi_Zone_Err=${arr[16]}

arr=($(smart_attr ata-WDC_WD30EZRX-00D8PB0_WD-WMC4N0680500))
HD3_Raw_Read_Error=${arr[0]}
HD3_Spin_Up_Time=${arr[1]}
HD3_Start_Stop=${arr[2]}
HD3_Reallocated_Sec=${arr[3]}
HD3_Seek_Error_Rate=${arr[4]}
HD3_Power_On_Hours=${arr[5]}
HD3_Spin_Retry=${arr[6]}
HD3_Calibration_Ret=${arr[7]}
HD3_Power_Cycle=${arr[8]}
HD3_Power_Off_Ret=${arr[9]}
HD3_Load_Cycle=${arr[10]}
HD3_Temperature=${arr[11]}
HD3_Reallocated_Evt=${arr[12]}
HD3_Current_Pending=${arr[13]}
HD3_Offline_Uncrect=${arr[14]}
HD3_UDMA_CRC_Error=${arr[15]}
HD3_Multi_Zone_Err=${arr[16]}

arr=($(smart_attr ata-WDC_WD25EZRX-00MMMB0_WD-WCAWZ1234078))
HD4_Raw_Read_Error=${arr[0]}
HD4_Spin_Up_Time=${arr[1]}
HD4_Start_Stop=${arr[2]}
HD4_Reallocated_Sec=${arr[3]}
HD4_Seek_Error_Rate=${arr[4]}
HD4_Power_On_Hours=${arr[5]}
HD4_Spin_Retry=${arr[6]}
HD4_Calibration_Ret=${arr[7]}
HD4_Power_Cycle=${arr[8]}
HD4_Power_Off_Ret=${arr[9]}
HD4_Load_Cycle=${arr[10]}
HD4_Temperature=${arr[11]}
HD4_Reallocated_Evt=${arr[12]}
HD4_Current_Pending=${arr[13]}
HD4_Offline_Uncrect=${arr[14]}
HD4_UDMA_CRC_Error=${arr[15]}
HD4_Multi_Zone_Err=${arr[16]}

arr=($(smart_attr ata-TOSHIBA_THNSNH256GCST_73IS101WTPHY))
SSD_Raw_Read_Error=${arr[0]}
SSD_Throughput_Perf=${arr[1]}
SSD_Spin_Up_Time=${arr[2]}
SSD_Reallocated_Sec=${arr[3]}
SSD_Power_On_Hours=${arr[6]}
SSD_Power_Cycle=${arr[8]}
SSD_Program_Fail_Ct=${arr[13]}
SSD_Power_Off_Ret=${arr[14]}
SSD_Temperature=${arr[15]}
SSD_Current_Pending=${arr[16]}


# cat << EOF
# HD1_Raw_Read_Error   $HD1_Raw_Read_Error
# HD1_Spin_Up_Time     $HD1_Spin_Up_Time
# HD1_Start_Stop       $HD1_Start_Stop
# HD1_Reallocated_Sec  $HD1_Reallocated_Sec
# HD1_Seek_Error_Rate  $HD1_Seek_Error_Rate
# HD1_Power_On_Hours   $HD1_Power_On_Hours
# HD1_Spin_Retry       $HD1_Spin_Retry
# HD1_Calibration_Ret  $HD1_Calibration_Ret
# HD1_Power_Cycle      $HD1_Power_Cycle
# HD1_Power_Off_Ret    $HD1_Power_Off_Ret
# HD1_Load_Cycle       $HD1_Load_Cycle
# HD1_Temperature      $HD1_Temperature
# HD1_Reallocated_Evt  $HD1_Reallocated_Evt
# HD1_Current_Pending  $HD1_Current_Pending
# HD1_Offline_Uncrect  $HD1_Offline_Uncrect
# HD1_UDMA_CRC_Error   $HD1_UDMA_CRC_Error
# HD1_Multi_Zone_Err   $HD1_Multi_Zone_Err
# HD2_Raw_Read_Error   $HD2_Raw_Read_Error
# HD2_Spin_Up_Time     $HD2_Spin_Up_Time
# HD2_Start_Stop       $HD2_Start_Stop
# HD2_Reallocated_Sec  $HD2_Reallocated_Sec
# HD2_Seek_Error_Rate  $HD2_Seek_Error_Rate
# HD2_Power_On_Hours   $HD2_Power_On_Hours
# HD2_Spin_Retry       $HD2_Spin_Retry
# HD2_Calibration_Ret  $HD2_Calibration_Ret
# HD2_Power_Cycle      $HD2_Power_Cycle
# HD2_Power_Off_Ret    $HD2_Power_Off_Ret
# HD2_Load_Cycle       $HD2_Load_Cycle
# HD2_Temperature      $HD2_Temperature
# HD2_Reallocated_Evt  $HD2_Reallocated_Evt
# HD2_Current_Pending  $HD2_Current_Pending
# HD2_Offline_Uncrect  $HD2_Offline_Uncrect
# HD2_UDMA_CRC_Error   $HD2_UDMA_CRC_Error
# HD2_Multi_Zone_Err   $HD2_Multi_Zone_Err
# HD3_Raw_Read_Error   $HD3_Raw_Read_Error
# HD3_Spin_Up_Time     $HD3_Spin_Up_Time
# HD3_Start_Stop       $HD3_Start_Stop
# HD3_Reallocated_Sec  $HD3_Reallocated_Sec
# HD3_Seek_Error_Rate  $HD3_Seek_Error_Rate
# HD3_Power_On_Hours   $HD3_Power_On_Hours
# HD3_Spin_Retry       $HD3_Spin_Retry
# HD3_Calibration_Ret  $HD3_Calibration_Ret
# HD3_Power_Cycle      $HD3_Power_Cycle
# HD3_Power_Off_Ret    $HD3_Power_Off_Ret
# HD3_Load_Cycle       $HD3_Load_Cycle
# HD3_Temperature      $HD3_Temperature
# HD3_Reallocated_Evt  $HD3_Reallocated_Evt
# HD3_Current_Pending  $HD3_Current_Pending
# HD3_Offline_Uncrect  $HD3_Offline_Uncrect
# HD3_UDMA_CRC_Error   $HD3_UDMA_CRC_Error
# HD3_Multi_Zone_Err   $HD3_Multi_Zone_Err
# HD4_Raw_Read_Error   $HD4_Raw_Read_Error
# HD4_Spin_Up_Time     $HD4_Spin_Up_Time
# HD4_Start_Stop       $HD4_Start_Stop
# HD4_Reallocated_Sec  $HD4_Reallocated_Sec
# HD4_Seek_Error_Rate  $HD4_Seek_Error_Rate
# HD4_Power_On_Hours   $HD4_Power_On_Hours
# HD4_Spin_Retry       $HD4_Spin_Retry
# HD4_Calibration_Ret  $HD4_Calibration_Ret
# HD4_Power_Cycle      $HD4_Power_Cycle
# HD4_Power_Off_Ret    $HD4_Power_Off_Ret
# HD4_Load_Cycle       $HD4_Load_Cycle
# HD4_Temperature      $HD4_Temperature
# HD4_Reallocated_Evt  $HD4_Reallocated_Evt
# HD4_Current_Pending  $HD4_Current_Pending
# HD4_Offline_Uncrect  $HD4_Offline_Uncrect
# HD4_UDMA_CRC_Error   $HD4_UDMA_CRC_Error
# HD4_Multi_Zone_Err   $HD4_Multi_Zone_Err
# SSD_Raw_Read_Error   $SSD_Raw_Read_Error
# SSD_Throughput_Perf  $SSD_Throughput_Perf
# SSD_Spin_Up_Time     $SSD_Spin_Up_Time
# SSD_Reallocated_Sec  $SSD_Reallocated_Sec
# SSD_Power_On_Hours   $SSD_Power_On_Hours
# SSD_Power_Cycle      $SSD_Power_Cycle
# SSD_Program_Fail_Ct  $SSD_Program_Fail_Ct
# SSD_Power_Off_Ret    $SSD_Power_Off_Ret
# SSD_Temperature      $SSD_Temperature
# SSD_Current_Pending  $SSD_Current_Pending
# EOF


rrdtool update $db_file \
N:$HD1_Raw_Read_Error:$HD1_Spin_Up_Time:$HD1_Start_Stop:$HD1_Reallocated_Sec:$HD1_Seek_Error_Rate:$HD1_Power_On_Hours:$HD1_Spin_Retry:$HD1_Calibration_Ret:$HD1_Power_Cycle:$HD1_Power_Off_Ret:$HD1_Load_Cycle:$HD1_Temperature:$HD1_Reallocated_Evt:$HD1_Current_Pending:$HD1_Offline_Uncrect:$HD1_UDMA_CRC_Error:$HD1_Multi_Zone_Err:$HD2_Raw_Read_Error:$HD2_Spin_Up_Time:$HD2_Start_Stop:$HD2_Reallocated_Sec:$HD2_Seek_Error_Rate:$HD2_Power_On_Hours:$HD2_Spin_Retry:$HD2_Calibration_Ret:$HD2_Power_Cycle:$HD2_Power_Off_Ret:$HD2_Load_Cycle:$HD2_Temperature:$HD2_Reallocated_Evt:$HD2_Current_Pending:$HD2_Offline_Uncrect:$HD2_UDMA_CRC_Error:$HD2_Multi_Zone_Err:$HD3_Raw_Read_Error:$HD3_Spin_Up_Time:$HD3_Start_Stop:$HD3_Reallocated_Sec:$HD3_Seek_Error_Rate:$HD3_Power_On_Hours:$HD3_Spin_Retry:$HD3_Calibration_Ret:$HD3_Power_Cycle:$HD3_Power_Off_Ret:$HD3_Load_Cycle:$HD3_Temperature:$HD3_Reallocated_Evt:$HD3_Current_Pending:$HD3_Offline_Uncrect:$HD3_UDMA_CRC_Error:$HD3_Multi_Zone_Err:$HD4_Raw_Read_Error:$HD4_Spin_Up_Time:$HD4_Start_Stop:$HD4_Reallocated_Sec:$HD4_Seek_Error_Rate:$HD4_Power_On_Hours:$HD4_Spin_Retry:$HD4_Calibration_Ret:$HD4_Power_Cycle:$HD4_Power_Off_Ret:$HD4_Load_Cycle:$HD4_Temperature:$HD4_Reallocated_Evt:$HD4_Current_Pending:$HD4_Offline_Uncrect:$HD4_UDMA_CRC_Error:$HD4_Multi_Zone_Err:$SSD_Raw_Read_Error:$SSD_Throughput_Perf:$SSD_Spin_Up_Time:$SSD_Reallocated_Sec:$SSD_Power_On_Hours:$SSD_Power_Cycle:$SSD_Program_Fail_Ct:$SSD_Power_Off_Ret:$SSD_Temperature:$SSD_Current_Pending



LANG=C rrdtool graph ${png_dir}/monthly/smart_error.png \
--title "S.M.A.R.T error $start_date_str" \
--imgformat PNG \
--start $start_date \
--end start+1MONTH \
--x-grid DAY:1:DAY:1:DAY:1:0:%d \
--width 700 \
--height 300 \
--lower-limit 0 \
DEF:HD1_Raw_Read_Error=$db_file:HD1_Raw_Read_Error:LAST \
DEF:HD1_Reallocated_Sec=$db_file:HD1_Reallocated_Sec:LAST \
DEF:HD1_Seek_Error_Rate=$db_file:HD1_Seek_Error_Rate:LAST \
DEF:HD1_Spin_Retry=$db_file:HD1_Spin_Retry:LAST \
DEF:HD1_Calibration_Ret=$db_file:HD1_Calibration_Ret:LAST \
DEF:HD1_Reallocated_Evt=$db_file:HD1_Reallocated_Evt:LAST \
DEF:HD1_Current_Pending=$db_file:HD1_Current_Pending:LAST \
DEF:HD1_UDMA_CRC_Error=$db_file:HD1_UDMA_CRC_Error:LAST \
DEF:HD2_Raw_Read_Error=$db_file:HD2_Raw_Read_Error:LAST \
DEF:HD2_Reallocated_Sec=$db_file:HD2_Reallocated_Sec:LAST \
DEF:HD2_Seek_Error_Rate=$db_file:HD2_Seek_Error_Rate:LAST \
DEF:HD2_Spin_Retry=$db_file:HD2_Spin_Retry:LAST \
DEF:HD2_Calibration_Ret=$db_file:HD2_Calibration_Ret:LAST \
DEF:HD2_Reallocated_Evt=$db_file:HD2_Reallocated_Evt:LAST \
DEF:HD2_Current_Pending=$db_file:HD2_Current_Pending:LAST \
DEF:HD2_UDMA_CRC_Error=$db_file:HD2_UDMA_CRC_Error:LAST \
DEF:HD3_Raw_Read_Error=$db_file:HD3_Raw_Read_Error:LAST \
DEF:HD3_Reallocated_Sec=$db_file:HD3_Reallocated_Sec:LAST \
DEF:HD3_Seek_Error_Rate=$db_file:HD3_Seek_Error_Rate:LAST \
DEF:HD3_Spin_Retry=$db_file:HD3_Spin_Retry:LAST \
DEF:HD3_Calibration_Ret=$db_file:HD3_Calibration_Ret:LAST \
DEF:HD3_Reallocated_Evt=$db_file:HD3_Reallocated_Evt:LAST \
DEF:HD3_Current_Pending=$db_file:HD3_Current_Pending:LAST \
DEF:HD3_UDMA_CRC_Error=$db_file:HD3_UDMA_CRC_Error:LAST \
DEF:HD4_Raw_Read_Error=$db_file:HD4_Raw_Read_Error:LAST \
DEF:HD4_Reallocated_Sec=$db_file:HD4_Reallocated_Sec:LAST \
DEF:HD4_Seek_Error_Rate=$db_file:HD4_Seek_Error_Rate:LAST \
DEF:HD4_Spin_Retry=$db_file:HD4_Spin_Retry:LAST \
DEF:HD4_Calibration_Ret=$db_file:HD4_Calibration_Ret:LAST \
DEF:HD4_Reallocated_Evt=$db_file:HD4_Reallocated_Evt:LAST \
DEF:HD4_Current_Pending=$db_file:HD4_Current_Pending:LAST \
DEF:HD4_UDMA_CRC_Error=$db_file:HD4_UDMA_CRC_Error:LAST \
DEF:SSD_Raw_Read_Error=$db_file:SSD_Raw_Read_Error:LAST \
DEF:SSD_Reallocated_Sec=$db_file:SSD_Reallocated_Sec:LAST \
DEF:SSD_Program_Fail_Ct=$db_file:SSD_Program_Fail_Ct:LAST \
DEF:SSD_Current_Pending=$db_file:SSD_Current_Pending:LAST \
CDEF:SSD_ERROR_COUNT=SSD_Raw_Read_Error,SSD_Reallocated_Sec,SSD_Program_Fail_Ct,SSD_Current_Pending,+,+,+ \
VDEF:SSD_ERROR_COUNT_MAX=SSD_ERROR_COUNT,MAXIMUM \
CDEF:HD1_ERROR_COUNT=HD1_Raw_Read_Error,HD1_Reallocated_Sec,HD1_Seek_Error_Rate,HD1_Spin_Retry,HD1_Calibration_Ret,HD1_Reallocated_Evt,HD1_Current_Pending,HD1_UDMA_CRC_Error,+,+,+,+,+,+,+ \
CDEF:HD2_ERROR_COUNT=HD2_Raw_Read_Error,HD2_Reallocated_Sec,HD2_Seek_Error_Rate,HD2_Spin_Retry,HD2_Calibration_Ret,HD2_Reallocated_Evt,HD2_Current_Pending,HD2_UDMA_CRC_Error,+,+,+,+,+,+,+ \
CDEF:HD3_ERROR_COUNT=HD3_Raw_Read_Error,HD3_Reallocated_Sec,HD3_Seek_Error_Rate,HD3_Spin_Retry,HD3_Calibration_Ret,HD3_Reallocated_Evt,HD3_Current_Pending,HD3_UDMA_CRC_Error,+,+,+,+,+,+,+ \
CDEF:HD4_ERROR_COUNT=HD4_Raw_Read_Error,HD4_Reallocated_Sec,HD4_Seek_Error_Rate,HD4_Spin_Retry,HD4_Calibration_Ret,HD4_Reallocated_Evt,HD4_Current_Pending,HD4_UDMA_CRC_Error,+,+,+,+,+,+,+ \
VDEF:HD1_ERROR_COUNT_MAX=HD1_ERROR_COUNT,MAXIMUM \
VDEF:HD2_ERROR_COUNT_MAX=HD2_ERROR_COUNT,MAXIMUM \
VDEF:HD3_ERROR_COUNT_MAX=HD3_ERROR_COUNT,MAXIMUM \
VDEF:HD4_ERROR_COUNT_MAX=HD4_ERROR_COUNT,MAXIMUM \
COMMENT:" " \
AREA:HD1_ERROR_COUNT#7B68EE:"HD1": \
STACK:HD2_ERROR_COUNT#1E90FF:"HD2": \
STACK:HD3_ERROR_COUNT#7CFC00:"HD3": \
STACK:HD4_ERROR_COUNT#FFFF00:"HD4": \
STACK:SSD_ERROR_COUNT#FFA500:"SSD": \
COMMENT:" \j" \
COMMENT:" " \
COMMENT:" error count MAX" \
GPRINT:HD1_ERROR_COUNT_MAX:"HD1 \: %3.0lf" \
GPRINT:HD2_ERROR_COUNT_MAX:"HD2 \: %3.0lf" \
GPRINT:HD3_ERROR_COUNT_MAX:"HD3 \: %3.0lf" \
GPRINT:HD4_ERROR_COUNT_MAX:"HD4 \: %3.0lf" \
GPRINT:SSD_ERROR_COUNT_MAX:"SSD \: %3.0lf" \
COMMENT:" \j"


LANG=C rrdtool graph ${png_dir}/monthly/smart_temp.png \
--title "S.M.A.R.T temparature $start_date_str" \
--imgformat PNG \
--start $start_date \
--end start+1MONTH \
--x-grid DAY:1:DAY:1:DAY:1:0:%d \
--width 700 \
--height 300 \
--lower-limit 0 \
DEF:HD1=$db_file:HD1_Temperature:LAST \
DEF:HD2=$db_file:HD2_Temperature:LAST \
DEF:HD3=$db_file:HD3_Temperature:LAST \
DEF:HD4=$db_file:HD4_Temperature:LAST \
DEF:SSD=$db_file:SSD_Temperature:LAST \
VDEF:HD1_MAX=HD1,MAXIMUM \
VDEF:HD2_MAX=HD2,MAXIMUM \
VDEF:HD3_MAX=HD3,MAXIMUM \
VDEF:HD4_MAX=HD4,MAXIMUM \
VDEF:SSD_MAX=SSD,MAXIMUM \
VDEF:HD1_MIN=HD1,MINIMUM \
VDEF:HD2_MIN=HD2,MINIMUM \
VDEF:HD3_MIN=HD3,MINIMUM \
VDEF:HD4_MIN=HD4,MINIMUM \
VDEF:SSD_MIN=SSD,MINIMUM \
COMMENT:" " \
AREA:HD1#7B68EE:HD1: \
STACK:HD2#1E90FF:HD2: \
STACK:HD3#7CFC00:HD3: \
STACK:HD4#FFFF00:HD4: \
STACK:SSD#FFA500:SSD: \
COMMENT:" \j" \
COMMENT:" " \
COMMENT:" temparature MIN" \
GPRINT:HD1_MIN:"HD1 \: %3.0lf" \
GPRINT:HD2_MIN:"HD2 \: %3.0lf" \
GPRINT:HD3_MIN:"HD3 \: %3.0lf" \
GPRINT:HD4_MIN:"HD4 \: %3.0lf" \
GPRINT:SSD_MIN:"SSD \: %3.0lf" \
COMMENT:" \j" \
COMMENT:" " \
COMMENT:" temparature MAX" \
GPRINT:HD1_MAX:"HD1 \: %3.0lf" \
GPRINT:HD2_MAX:"HD2 \: %3.0lf" \
GPRINT:HD3_MAX:"HD3 \: %3.0lf" \
GPRINT:HD4_MAX:"HD4 \: %3.0lf" \
GPRINT:SSD_MAX:"SSD \: %3.0lf" \
COMMENT:" \j"
