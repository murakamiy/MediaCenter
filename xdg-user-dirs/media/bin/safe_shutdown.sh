#!/bin/bash
source $(dirname $0)/00.conf

function do_shutdown() {
    $MC_BIN_USB_POWER_OFF
    sudo $MC_BIN_USB_CONTROL -e
    touch $MC_STAT_POWEROFF
    sudo $MC_BIN_WAKEUPTOOL -w -t $wakeup_time
}

function do_safe_shutdown() {

if [ -e $MC_STAT_POWEROFF ];then
    log "another shutdown is running"
    return
fi

next_job_file=
next_job_time=0
now=$(awk 'BEGIN { print systime() }')
for f in $(ls $MC_DIR_RESERVED | sort -t '-' --key=1,2 -n);do
    next_job_time=$(xmlsel -t -m "//epoch[@type='start']" -v '.' ${MC_DIR_RESERVED}/$f)
    if [ $next_job_time -gt $now ];then
        next_job_file=$f
        break
    fi
done

wakeup_time=$(python $MC_BIN_WAKEUP_TIME $next_job_time)

running=$(find $MC_DIR_PLAY -type f -name '*.xml' -printf '%f ')
if [ -n "$running" ];then
    echo playing movie
    echo $running
    return
fi

running=$(find $MC_DIR_RECORDING $MC_DIR_RECORD_FINISHED $MC_DIR_ENCODING -type f -name '*.xml' -printf '%f ')
if [ -n "$running" ];then
    echo job is running
    echo $running
    return
fi

log $(df -h | grep ^/dev/sda | awk '{ printf("disk used=%s avail=%s\n", $3, $4) }')

if [ $wakeup_time -ne -1 ];then
    next_wakeup_time=$(awk -v epoc=$wakeup_time 'BEGIN { print strftime("%Y/%m/%d %H:%M:%S", epoc) }')

    if [ -z "$SSH_CONNECTION" ];then
        zenity --question --no-wrap --timeout=60 --display=:0.0 --text="<span font_desc='40'>next wakeup time: $next_wakeup_time\n\nShutDown ?</span>"
        if [ $? -ne 1 ];then
            log "shutdown=yes : X Server"
            log "next wakeup time: $next_wakeup_time"
            log "next job file : $next_job_file"
            do_shutdown
        fi
    else
        echo "next wakeup time: $next_wakeup_time\n\n"
        sleep 5
        log "shutdown=yes : console"
        log "next wakeup time: $next_wakeup_time"
        log "next job file : $next_job_file"
        do_shutdown
    fi
else
    log "shutdown=no"
    log "next job file : $next_job_file"
    echo next job will be executed soon
    zenity --warning --no-wrap --timeout=3 --display=:0.0 --text="<span font_desc='40'>next job will be executed soon</span>"
fi

}

lock_file=/tmp/mc_safe_shutdown
lockfile-create $lock_file
if [ $? -ne 0 ];then
    echo "lockfile-create failed: $0"
    exit 1
fi
lockfile-touch $lock_file &
pid_lock=$!

do_safe_shutdown

kill -TERM $pid_lock
lockfile-remove $lock_file
