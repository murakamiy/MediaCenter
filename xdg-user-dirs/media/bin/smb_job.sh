#!/bin/bash
source $(dirname $0)/00.conf
source $(dirname $0)/smb_func.sh

lock_file=/tmp/smb_copy_job_lock

lockfile-create $lock_file
lockfile-touch $lock_file &
pid_lock=$!

smb_copy_mp4

kill -TERM $pid_lock
lockfile-remove $lock_file
