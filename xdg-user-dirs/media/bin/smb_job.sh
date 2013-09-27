#!/bin/bash
source $(dirname $0)/00.conf
lock_file=/tmp/smb_copy_job_lock

function copy_mp4() {

    avail=$(smbclient -A ~/.smbauth -c ls $MC_SMB_SERVER | tail -n 1 | awk -F . '{ print $2 }')
    log "smb job start $avail"

    cd $MC_DIR_MP4
    mp4=$(find . -type f -size -500M -size +10M -printf '%TY%Tm%Td %TT %f\n' | sort | head -n 1 | awk '{ print $3}')
    fuser "$mp4"
    if [ $? -ne 0 ];then
        smbclient -A ~/.smbauth -D contents -c "put $mp4" $MC_SMB_SERVER
        /bin/rm "$mp4"
    fi

    avail=$(smbclient -A ~/.smbauth -c ls $MC_SMB_SERVER | tail -n 1 | awk -F . '{ print $2 }')
    log "smb job end $avail"
}



lockfile-create $lock_file
lockfile-touch $lock_file &
pid_lock=$!

copy_mp4

kill -TERM $pid_lock
lockfile-remove $lock_file
