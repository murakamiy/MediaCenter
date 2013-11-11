#!/bin/bash

# ssd  ata-TOSHIBA_THNSNH256GCST_73IS101WTPHY
# hd_1 ata-WDC_WD30EZRX-00D8PB0_WD-WMC4N0640397
# hd_2 ata-WDC_WD30EZRX-00D8PB0_WD-WMC4N0637164
# hd_3 ata-WDC_WD30EZRX-00D8PB0_WD-WMC4N0680500
# hd_4 ata-WDC_WD25EZRX-00MMMB0_WD-WCAWZ1234078


# smartctl 6.2 2013-07-26 r3841 [x86_64-linux-3.11-1-amd64] (local build)
# Copyright (C) 2002-13, Bruce Allen, Christian Franke, www.smartmontools.org
# 
# === START OF READ SMART DATA SECTION ===
# SMART Attributes Data Structure revision number: 16
# Vendor Specific SMART Attributes with Thresholds:
# ID# ATTRIBUTE_NAME          FLAG     VALUE WORST THRESH TYPE      UPDATED  WHEN_FAILED RAW_VALUE
#   1 Raw_Read_Error_Rate     0x002f   200   200   051    Pre-fail  Always       -       0
#   3 Spin_Up_Time            0x0027   147   143   021    Pre-fail  Always       -       9625
#   4 Start_Stop_Count        0x0032   096   096   000    Old_age   Always       -       4492
#   5 Reallocated_Sector_Ct   0x0033   200   200   140    Pre-fail  Always       -       0
#   7 Seek_Error_Rate         0x002e   200   200   000    Old_age   Always       -       0
#   9 Power_On_Hours          0x0032   085   085   000    Old_age   Always       -       11356
#  10 Spin_Retry_Count        0x0032   100   100   000    Old_age   Always       -       0
#  11 Calibration_Retry_Count 0x0032   100   100   000    Old_age   Always       -       0
#  12 Power_Cycle_Count       0x0032   098   098   000    Old_age   Always       -       2730
# 192 Power-Off_Retract_Count 0x0032   200   200   000    Old_age   Always       -       154
# 193 Load_Cycle_Count        0x0032   143   143   000    Old_age   Always       -       173265
# 194 Temperature_Celsius     0x0022   121   101   000    Old_age   Always       -       31
# 196 Reallocated_Event_Count 0x0032   200   200   000    Old_age   Always       -       0
# 197 Current_Pending_Sector  0x0032   200   200   000    Old_age   Always       -       0
# 198 Offline_Uncorrectable   0x0030   200   200   000    Old_age   Offline      -       0
# 199 UDMA_CRC_Error_Count    0x0032   200   200   000    Old_age   Always       -       0
# 200 Multi_Zone_Error_Rate   0x0008   200   200   000    Old_age   Offline      -       0

# HDD
# Raw_Read_Error   Raw_Read_Error_Rate
# Spin_Up_Time     Spin_Up_Time
# Start_Stop       Start_Stop_Count
# Reallocated_Sec  Reallocated_Sector_Ct
# Seek_Error_Rate  Seek_Error_Rate
# Power_On_Hours   Power_On_Hours
# Spin_Retry       Spin_Retry_Count
# Calibration_Ret  Calibration_Retry_Count
# Power_Cycle      Power_Cycle_Count
# Power_Off_Ret    Power_Off_Retract_Count
# Load_Cycle       Load_Cycle_Count
# Temperature      Temperature_Celsius
# Reallocated_Evt  Reallocated_Event_Count
# Current_Pending  Current_Pending_Sector
# Offline_Uncrect  Offline_Uncorrectable
# UDMA_CRC_Error   UDMA_CRC_Error_Count
# Multi_Zone_Err   Multi_Zone_Error_Rate



# smartctl 6.2 2013-07-26 r3841 [x86_64-linux-3.11-1-amd64] (local build)
# Copyright (C) 2002-13, Bruce Allen, Christian Franke, www.smartmontools.org
# 
# === START OF READ SMART DATA SECTION ===
# SMART Attributes Data Structure revision number: 16
# Vendor Specific SMART Attributes with Thresholds:
# ID# ATTRIBUTE_NAME          FLAG     VALUE WORST THRESH TYPE      UPDATED  WHEN_FAILED RAW_VALUE
#   1 Raw_Read_Error_Rate     0x000a   100   100   000    Old_age   Always       -       0
#   2 Throughput_Performance  0x0005   100   100   050    Pre-fail  Offline      -       0
#   3 Spin_Up_Time            0x0007   100   100   050    Pre-fail  Always       -       0
#   5 Reallocated_Sector_Ct   0x0013   100   100   050    Pre-fail  Always       -       0
#   7 Unknown_SSD_Attribute   0x000b   100   100   050    Pre-fail  Always       -       0
#   8 Unknown_SSD_Attribute   0x0005   100   100   050    Pre-fail  Offline      -       0
#   9 Power_On_Hours          0x0012   100   100   000    Old_age   Always       -       925
#  10 Unknown_SSD_Attribute   0x0013   100   100   050    Pre-fail  Always       -       0
#  12 Power_Cycle_Count       0x0012   100   100   000    Old_age   Always       -       486
# 167 Unknown_Attribute       0x0022   100   100   000    Old_age   Always       -       0
# 168 Unknown_Attribute       0x0012   100   100   000    Old_age   Always       -       0
# 169 Unknown_Attribute       0x0013   100   100   010    Pre-fail  Always       -       100
# 173 Unknown_Attribute       0x0012   196   196   000    Old_age   Always       -       0
# 175 Program_Fail_Count_Chip 0x0013   100   100   010    Pre-fail  Always       -       0
# 192 Power-Off_Retract_Count 0x0012   100   100   000    Old_age   Always       -       23
# 194 Temperature_Celsius     0x0023   076   062   020    Pre-fail  Always       -       24 (Min/Max 19/38)
# 197 Current_Pending_Sector  0x0012   100   100   000    Old_age   Always       -       0
# 240 Unknown_SSD_Attribute   0x0013   100   100   050    Pre-fail  Always       -       0


# 0  Raw_Read_Error_Rate
# 1  Throughput_Performance
# 2  Spin_Up_Time
# 3  Reallocated_Sector_Ct
# 4  Unknown_SSD_Attribute
# 5  Unknown_SSD_Attribute
# 6  Power_On_Hours
# 7  Unknown_SSD_Attribute
# 8  Power_Cycle_Count
# 9  Unknown_Attribute
# 10 Unknown_Attribute
# 11 Unknown_Attribute
# 12 Unknown_Attribute
# 13 Program_Fail_Count_Chip
# 14 Power-Off_Retract_Count
# 15 Temperature_Celsius
# 16 Current_Pending_Sector
# 17 Unknown_SSD_Attribute

# SSD
# Raw_Read_Error   Raw_Read_Error_Rate        0
# Throughput_Perf  Throughput_Performance     1
# Spin_Up_Time     Spin_Up_Time               2
# Reallocated_Sec  Reallocated_Sector_Ct      3
# Power_On_Hours   Power_On_Hours             6
# Power_Cycle      Power_Cycle_Count          8
# Program_Fail_Ct  Program_Fail_Count_Chip    13
# Power_Off_Ret    Power_Off_Retract_Count    14
# Temperature      Temperature_Celsius        15
# Current_Pending  Current_Pending_Sector     16

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


db_file=/home/mc/xdg-user-dirs/media/bin/rrd/smart.rrd
rrdtool update $db_file \
N:$HD1_Raw_Read_Error:$HD1_Spin_Up_Time:$HD1_Start_Stop:$HD1_Reallocated_Sec:$HD1_Seek_Error_Rate:$HD1_Power_On_Hours:$HD1_Spin_Retry:$HD1_Calibration_Ret:$HD1_Power_Cycle:$HD1_Power_Off_Ret:$HD1_Load_Cycle:$HD1_Temperature:$HD1_Reallocated_Evt:$HD1_Current_Pending:$HD1_Offline_Uncrect:$HD1_UDMA_CRC_Error:$HD1_Multi_Zone_Err:$HD2_Raw_Read_Error:$HD2_Spin_Up_Time:$HD2_Start_Stop:$HD2_Reallocated_Sec:$HD2_Seek_Error_Rate:$HD2_Power_On_Hours:$HD2_Spin_Retry:$HD2_Calibration_Ret:$HD2_Power_Cycle:$HD2_Power_Off_Ret:$HD2_Load_Cycle:$HD2_Temperature:$HD2_Reallocated_Evt:$HD2_Current_Pending:$HD2_Offline_Uncrect:$HD2_UDMA_CRC_Error:$HD2_Multi_Zone_Err:$HD3_Raw_Read_Error:$HD3_Spin_Up_Time:$HD3_Start_Stop:$HD3_Reallocated_Sec:$HD3_Seek_Error_Rate:$HD3_Power_On_Hours:$HD3_Spin_Retry:$HD3_Calibration_Ret:$HD3_Power_Cycle:$HD3_Power_Off_Ret:$HD3_Load_Cycle:$HD3_Temperature:$HD3_Reallocated_Evt:$HD3_Current_Pending:$HD3_Offline_Uncrect:$HD3_UDMA_CRC_Error:$HD3_Multi_Zone_Err:$HD4_Raw_Read_Error:$HD4_Spin_Up_Time:$HD4_Start_Stop:$HD4_Reallocated_Sec:$HD4_Seek_Error_Rate:$HD4_Power_On_Hours:$HD4_Spin_Retry:$HD4_Calibration_Ret:$HD4_Power_Cycle:$HD4_Power_Off_Ret:$HD4_Load_Cycle:$HD4_Temperature:$HD4_Reallocated_Evt:$HD4_Current_Pending:$HD4_Offline_Uncrect:$HD4_UDMA_CRC_Error:$HD4_Multi_Zone_Err:$SSD_Raw_Read_Error:$SSD_Throughput_Perf:$SSD_Spin_Up_Time:$SSD_Reallocated_Sec:$SSD_Power_On_Hours:$SSD_Power_Cycle:$SSD_Program_Fail_Ct:$SSD_Power_Off_Ret:$SSD_Temperature:$SSD_Current_Pending



