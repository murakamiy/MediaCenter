#!/bin/bash
source $(dirname $0)/00.conf

smbclient -A ~/.smbauth -c "mkdir contents"      $MC_SMB_SERVER
smbclient -A ~/.smbauth -c "mkdir favorite"      $MC_SMB_SERVER
smbclient -A ~/.smbauth -c "mkdir graph"         $MC_SMB_SERVER
smbclient -A ~/.smbauth -c "mkdir graph/daily"   $MC_SMB_SERVER
smbclient -A ~/.smbauth -c "mkdir graph/monthly" $MC_SMB_SERVER
smbclient -A ~/.smbauth -c "mkdir graph/weekly"  $MC_SMB_SERVER
smbclient -A ~/.smbauth -c "mkdir log"           $MC_SMB_SERVER
smbclient -A ~/.smbauth -c "mkdir play_time"     $MC_SMB_SERVER
