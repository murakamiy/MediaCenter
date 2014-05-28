#!/bin/bash
source $(dirname $0)/00.conf
source $(dirname $0)/smb_func.sh

lock_file=/tmp/smb_copy_job_lock

lockfile-create $lock_file
if [ $? -ne 0 ];then
    echo "lockfile-create failed: $0"
    exit 1
fi
lockfile-touch $lock_file &
pid_lock=$!

smb_copy_mp4 one

kill -TERM $pid_lock
lockfile-remove $lock_file
