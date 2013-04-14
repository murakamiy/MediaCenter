#!/bin/bash
source $(dirname $0)/00.conf

function is_job_running() {
    running=$(find $MC_DIR_RECORDING $MC_DIR_RECORD_FINISHED $MC_DIR_ENCODING -type f -name '*.xml')
    ps auxc | grep -q mplayer
    mplayer=$?
    ps auxc | grep -q vlc
    vlc=$?
    ps auxc | grep ^mc | grep -q sshd
    ssh=$?
    if [ -n "$running" -o "$mplayer" -eq 0 -o "$vlc" -eq 0 -o "$ssh" -eq 0 ];then
        log "running jobs: $running"
        ret=0
    else
        ret=1
    fi
    return $ret
}
function get_next_job_time() {
    now=$(awk 'BEGIN { print systime() }')
    next_job_time=0
    for f in $(ls $MC_DIR_RESERVED | sort -t '-' --key=1,2 -n);do
        next_job_time=$(xmlsel -t -m "//epoch[@type='start']" -v '.' ${MC_DIR_RESERVED}/$f)
        if [ $next_job_time -gt $now ];then
            log "next_job_file: $f"
            break
        fi
    done

    echo $next_job_time
}

timeout=60
while getopts 't:' opt;do
    case $opt in
        t)
            timeout=$OPTARG
            ;;
    esac
done

is_job_running 
if [ $? -eq 0 ];then
    echo job is running
    zenity --warning --no-wrap --timeout=$timeout --display=:0.0 --text="<span font_desc='40'>job is running</span>"
    exit
fi

next_job_time=$(get_next_job_time)
wakeup_time=$(python $MC_BIN_WAKEUP_TIME $next_job_time)

if [ $wakeup_time -ne -1 ];then
    next_wakeup_time=$(awk -v epoc=$wakeup_time 'BEGIN { print strftime("%Y/%m/%d %H:%M:%S", epoc) }')
    log
    echo "next wakeup time: $next_wakeup_time\n\nShutDown ?"
    zenity --question --no-wrap --timeout=$timeout --display=:0.0 --text="<span font_desc='40'>next wakeup time: $next_wakeup_time\n\nShutDown ?</span>"
    if [ $? -ne 1 ];then
        $MC_BIN_USB_POWER_OFF
        sudo $MC_BIN_WAKEUPTOOL -w -t $wakeup_time
    fi
else
    log
    echo next job will be executed soon
    zenity --warning --no-wrap --timeout=$timeout --display=:0.0 --text="<span font_desc='40'>next job will be executed soon</span>"
fi
