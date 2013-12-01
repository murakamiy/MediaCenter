#!/bin/bash
source $(dirname $0)/00.conf
lock_file=/tmp/smb_copy_job_lock

function copy_mp4() {
    cd $MC_DIR_MP4
    mp4=$(find . -type f -size +10M -printf '%TY%Tm%Td %TT %f\n' | sort | head -n 1 | awk '{ print $3}')

    if [ -n "$mp4" ];then
        fuser "$mp4"
        if [ $? -ne 0 ];then
            disk_size=$(smbclient -A ~/.smbauth -c ls $MC_SMB_SERVER | tail -n 1 | awk '{ print $1 }')
            disk_avail=$(smbclient -A ~/.smbauth -c ls $MC_SMB_SERVER | tail -n 1 | awk '{ print $6 }')
            disk_avail_gb=$(echo "$MC_SMB_DISK_SIZE_GB * $disk_avail / $disk_size" | bc)
            log "smb job put avail:${disk_avail_gb}GB $(ls -sh $mp4)"

            smbclient -A ~/.smbauth -D contents -c "put \"$mp4\"" $MC_SMB_SERVER
            smbclient -A ~/.smbauth -D contents -c "ls \"$mp4\"" $MC_SMB_SERVER
            if [ $? -eq 0 ];then
                /bin/rm "$mp4"
            fi
        fi
    fi
}



lockfile-create $lock_file
lockfile-touch $lock_file &
pid_lock=$!

copy_mp4

kill -TERM $pid_lock
lockfile-remove $lock_file
