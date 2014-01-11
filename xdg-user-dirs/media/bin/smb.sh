#!/bin/bash

source $(dirname $0)/00.conf

smb_dir=contents

disk_size=$(smbclient -A ~/.smbauth -c ls $MC_SMB_SERVER | tail -n 1 | awk '{ print $1 }')
disk_avail=$(smbclient -A ~/.smbauth -c ls $MC_SMB_SERVER | tail -n 1 | awk '{ print $6 }')
disk_avail_gb=$(echo "$MC_SMB_DISK_SIZE_GB * $disk_avail / $disk_size" | bc)
log "smb migrate start avail:${disk_avail_gb}GB"

for f in $(smbclient -A ~/.smbauth -D $smb_dir -c "ls" $MC_SMB_SERVER |
    egrep '[[:space:]]A[[:space:]]+[0-9]+[[:space:]]' |
    awk '{ print $1 }' | grep '^\.');do

    smbclient -A ~/.smbauth -D $smb_dir -c "del \"$f\"" $MC_SMB_SERVER

done

total_size=0
total_count=0
for f in $(smbclient -A ~/.smbauth -D $smb_dir -c "ls" $MC_SMB_SERVER |
    egrep '[[:space:]]A[[:space:]]+[0-9]+[[:space:]]' |
    awk -F '[[:space:]]A[[:space:]]+[0-9]+[[:space:]]' '
    {
        "date +%Y%m%d%H%M%S -d \""$2"\"" | getline time
        printf("%d\t%s\n", time, $1)
    }' | sort -k 1 -n -r | sed -n -e '251,$p' | awk '{ print $2 }');do

    size=$(smbclient -A ~/.smbauth -D $smb_dir -c "ls \"$f\"" $MC_SMB_SERVER |
    head -n 1 | awk -F ' A ' '{ print $2 }' | awk '{ print $1}')
    total_size=$(($total_size + $size))
    total_count=$(($total_count + 1))

    smbclient -A ~/.smbauth -D $smb_dir -c "del \"$f\"" $MC_SMB_SERVER

done

log "smb delete $total_count files $(($total_size / 1024 / 1024))MB"

cd $MC_DIR_TMP
for f in $(cd $MC_DIR_MP4; find . -name '*.mp4' -size +10M -printf '%f\n');do
    fuser "${MC_DIR_MP4}/$f"
    if [ $? -ne 0 ];then
        cp "${MC_DIR_MP4}/$f" $MC_DIR_TMP
        log "smb migrate put $(ls -sh $f)"
        smbclient -A ~/.smbauth -D $smb_dir -c "put \"$f\"" $MC_SMB_SERVER
        /bin/rm "${MC_DIR_MP4}/$f"
        /bin/rm "${MC_DIR_TMP}/$f"
    fi
done

disk_size=$(smbclient -A ~/.smbauth -c ls $MC_SMB_SERVER | tail -n 1 | awk '{ print $1 }')
disk_avail=$(smbclient -A ~/.smbauth -c ls $MC_SMB_SERVER | tail -n 1 | awk '{ print $6 }')
disk_avail_gb=$(echo "$MC_SMB_DISK_SIZE_GB * $disk_avail / $disk_size" | bc)
log "smb migrate end   avail:${disk_avail_gb}GB"

find $MC_DIR_MP4 -ctime +5 -delete
