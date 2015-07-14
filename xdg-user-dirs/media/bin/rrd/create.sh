#!/bin/bash

start_date=$(date --date "20131101 00:00:00" +%s)

db_file=/home/mc/xdg-user-dirs/media/bin/rrd/stat.rrd
rrdtool create $db_file \
--start $start_date \
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
DS:MEMORY_USED:GAUGE:600:0:7693 \
DS:MEMORY_FREE:GAUGE:600:0:7693 \
DS:MEMORY_SHARED:GAUGE:600:0:7693 \
DS:MEMORY_BUFFERS:GAUGE:600:0:7693 \
DS:MEMORY_CACHED:GAUGE:600:0:7693 \
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
DS:FAN1:GAUGE:600:0:5000 \
DS:FAN2:GAUGE:600:0:5000 \
RRA:AVERAGE:0.5:1:10080 \
RRA:AVERAGE:0.5:288:35 \
RRA:MIN:0.5:288:35 \
RRA:MAX:0.5:288:35


# S.M.A.R.T. HD
# Spin_Up_Time     Spin_Up_Time
# Start_Stop       Start_Stop_Count
# Power_On_Hours   Power_On_Hours
# Power_Cycle      Power_Cycle_Count
# Power_Off_Ret    Power_Off_Retract_Count
# Load_Cycle       Load_Cycle_Count
# Temperature      Temperature_Celsius
# Raw_Read_Error   Raw_Read_Error_Rate
# Reallocated_Sec  Reallocated_Sector_Ct
# Seek_Error_Rate  Seek_Error_Rate
# Spin_Retry       Spin_Retry_Count
# Calibration_Ret  Calibration_Retry_Count
# Reallocated_Evt  Reallocated_Event_Count
# Current_Pending  Current_Pending_Sector
# UDMA_CRC_Error   UDMA_CRC_Error_Count
# Offline_Uncrect  Offline_Uncorrectable
# Multi_Zone_Err   Multi_Zone_Error_Rate

# S.M.A.R.T. SSD
# Power_On_Hours   Power_On_Hours
# Power_Cycle      Power_Cycle_Count
# Power_Off_Ret    Power_Off_Retract_Count
# Temperature      Temperature_Celsius
# Spin_Up_Time     Spin_Up_Time
# Throughput_Perf  Throughput_Performance
# Raw_Read_Error   Raw_Read_Error_Rate
# Reallocated_Sec  Reallocated_Sector_Ct
# Program_Fail_Ct  Program_Fail_Count_Chip
# Current_Pending  Current_Pending_Sector

db_file=/home/mc/xdg-user-dirs/media/bin/rrd/smart.rrd
rrdtool create $db_file \
--start $start_date \
--step 86400 \
DS:HD1_Raw_Read_Error:GAUGE:172800:0:U \
DS:HD1_Spin_Up_Time:GAUGE:172800:0:U \
DS:HD1_Start_Stop:GAUGE:172800:0:U \
DS:HD1_Reallocated_Sec:GAUGE:172800:0:U \
DS:HD1_Seek_Error_Rate:GAUGE:172800:0:U \
DS:HD1_Power_On_Hours:GAUGE:172800:0:U \
DS:HD1_Spin_Retry:GAUGE:172800:0:U \
DS:HD1_Calibration_Ret:GAUGE:172800:0:U \
DS:HD1_Power_Cycle:GAUGE:172800:0:U \
DS:HD1_Power_Off_Ret:GAUGE:172800:0:U \
DS:HD1_Load_Cycle:GAUGE:172800:0:U \
DS:HD1_Temperature:GAUGE:172800:0:U \
DS:HD1_Reallocated_Evt:GAUGE:172800:0:U \
DS:HD1_Current_Pending:GAUGE:172800:0:U \
DS:HD1_Offline_Uncrect:GAUGE:172800:0:U \
DS:HD1_UDMA_CRC_Error:GAUGE:172800:0:U \
DS:HD1_Multi_Zone_Err:GAUGE:172800:0:U \
DS:HD2_Raw_Read_Error:GAUGE:172800:0:U \
DS:HD2_Spin_Up_Time:GAUGE:172800:0:U \
DS:HD2_Start_Stop:GAUGE:172800:0:U \
DS:HD2_Reallocated_Sec:GAUGE:172800:0:U \
DS:HD2_Seek_Error_Rate:GAUGE:172800:0:U \
DS:HD2_Power_On_Hours:GAUGE:172800:0:U \
DS:HD2_Spin_Retry:GAUGE:172800:0:U \
DS:HD2_Calibration_Ret:GAUGE:172800:0:U \
DS:HD2_Power_Cycle:GAUGE:172800:0:U \
DS:HD2_Power_Off_Ret:GAUGE:172800:0:U \
DS:HD2_Load_Cycle:GAUGE:172800:0:U \
DS:HD2_Temperature:GAUGE:172800:0:U \
DS:HD2_Reallocated_Evt:GAUGE:172800:0:U \
DS:HD2_Current_Pending:GAUGE:172800:0:U \
DS:HD2_Offline_Uncrect:GAUGE:172800:0:U \
DS:HD2_UDMA_CRC_Error:GAUGE:172800:0:U \
DS:HD2_Multi_Zone_Err:GAUGE:172800:0:U \
DS:HD3_Raw_Read_Error:GAUGE:172800:0:U \
DS:HD3_Spin_Up_Time:GAUGE:172800:0:U \
DS:HD3_Start_Stop:GAUGE:172800:0:U \
DS:HD3_Reallocated_Sec:GAUGE:172800:0:U \
DS:HD3_Seek_Error_Rate:GAUGE:172800:0:U \
DS:HD3_Power_On_Hours:GAUGE:172800:0:U \
DS:HD3_Spin_Retry:GAUGE:172800:0:U \
DS:HD3_Calibration_Ret:GAUGE:172800:0:U \
DS:HD3_Power_Cycle:GAUGE:172800:0:U \
DS:HD3_Power_Off_Ret:GAUGE:172800:0:U \
DS:HD3_Load_Cycle:GAUGE:172800:0:U \
DS:HD3_Temperature:GAUGE:172800:0:U \
DS:HD3_Reallocated_Evt:GAUGE:172800:0:U \
DS:HD3_Current_Pending:GAUGE:172800:0:U \
DS:HD3_Offline_Uncrect:GAUGE:172800:0:U \
DS:HD3_UDMA_CRC_Error:GAUGE:172800:0:U \
DS:HD3_Multi_Zone_Err:GAUGE:172800:0:U \
DS:HD4_Raw_Read_Error:GAUGE:172800:0:U \
DS:HD4_Spin_Up_Time:GAUGE:172800:0:U \
DS:HD4_Start_Stop:GAUGE:172800:0:U \
DS:HD4_Reallocated_Sec:GAUGE:172800:0:U \
DS:HD4_Seek_Error_Rate:GAUGE:172800:0:U \
DS:HD4_Power_On_Hours:GAUGE:172800:0:U \
DS:HD4_Spin_Retry:GAUGE:172800:0:U \
DS:HD4_Calibration_Ret:GAUGE:172800:0:U \
DS:HD4_Power_Cycle:GAUGE:172800:0:U \
DS:HD4_Power_Off_Ret:GAUGE:172800:0:U \
DS:HD4_Load_Cycle:GAUGE:172800:0:U \
DS:HD4_Temperature:GAUGE:172800:0:U \
DS:HD4_Reallocated_Evt:GAUGE:172800:0:U \
DS:HD4_Current_Pending:GAUGE:172800:0:U \
DS:HD4_Offline_Uncrect:GAUGE:172800:0:U \
DS:HD4_UDMA_CRC_Error:GAUGE:172800:0:U \
DS:HD4_Multi_Zone_Err:GAUGE:172800:0:U \
DS:SSD_Raw_Read_Error:GAUGE:172800:0:U \
DS:SSD_Throughput_Perf:GAUGE:172800:0:U \
DS:SSD_Spin_Up_Time:GAUGE:172800:0:U \
DS:SSD_Reallocated_Sec:GAUGE:172800:0:U \
DS:SSD_Power_On_Hours:GAUGE:172800:0:U \
DS:SSD_Power_Cycle:GAUGE:172800:0:U \
DS:SSD_Program_Fail_Ct:GAUGE:172800:0:U \
DS:SSD_Power_Off_Ret:GAUGE:172800:0:U \
DS:SSD_Temperature:GAUGE:172800:0:U \
DS:SSD_Current_Pending:GAUGE:172800:0:U \
RRA:LAST:0.5:1:35 \
RRA:MAX:0.5:35:1


db_file=/home/mc/xdg-user-dirs/media/bin/rrd/rec.rrd
rrdtool create $db_file \
--start $start_date \
--step 60 \
DS:T_Prefer:GAUGE:120:0:3 \
DS:T_Random:GAUGE:120:0:3 \
DS:S_Prefer:GAUGE:120:0:3 \
DS:S_Random:GAUGE:120:0:3 \
RRA:MAX:0.5:5:10080


db_file=/home/mc/xdg-user-dirs/media/bin/rrd/gpu.rrd
rrdtool create $db_file \
--start $start_date \
--step 300 \
DS:GPU_RENDER:GAUGE:600:0:100 \
DS:GPU_BITSTREAM:GAUGE:600:0:100 \
DS:GPU_BLITTER:GAUGE:600:0:100 \
RRA:AVERAGE:0.5:1:10080 \
RRA:AVERAGE:0.5:288:35 \
RRA:MIN:0.5:288:35 \
RRA:MAX:0.5:288:35
