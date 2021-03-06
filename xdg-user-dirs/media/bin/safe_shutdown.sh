#!/bin/bash
source $(dirname $0)/00.conf

function do_shutdown() {
    touch $MC_STAT_POWEROFF

#     for p in $(ps -ef | grep $MC_BIN_HTTP_CACHE | awk '{ print $2 }' );do
#         kill $p
#     done

    echo disconnect | sudo /usr/bin/bluetoothctl
    sleep 5
    echo power off | sudo bluetoothctl
    $MC_BIN_DISK_CONTROL -m
    sleep 5

cat << EOF | at -M now
xfce4-session-logout --logout
sudo $MC_BIN_WAKEUPTOOL -w -t $wakeup_time
EOF

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
wakeup_time=$(python2 $MC_BIN_WAKEUP_TIME $next_job_time)

if [ "$0" = $MC_BIN_SAFE_SHUTDOWN_GUI ];then
    gui=true
else
    gui=false
fi

if [ $gui = false ];then
running=$(find $MC_DIR_PLAY -type f -name '*.xml' -printf '%f ')
if [ -n "$running" ];then
    echo playing movie
    echo $running
    return
fi
fi

running=$(netstat -n --tcp | grep ESTABLISHED | awk '{ split($4, arr, ":"); if (80 == arr[2]) print $4 }')
if [ -n "$running" ];then
    echo playing movie remote
    echo $running
    return
fi

running=$(find $MC_DIR_RECORDING $MC_DIR_RECORD_FINISHED $MC_DIR_ENCODING $MC_DIR_ENCODING_CPU $MC_DIR_ENCODING_GPU -type f -name '*.xml' -printf '%f ')
if [ -n "$running" ];then
    echo job is running
    echo $running
    if [ $gui = true ];then
        zenity --warning --no-wrap --timeout=10 --display=:0.0 --text="<span font_desc='40'>job is running</span>" &
    fi
    return
fi

dev=$($MC_BIN_DISK_CONTROL -l)
dev_base=$(sed -e 's@/dev/@@' <<< $dev)
used=$(df -h | grep "^$dev" | awk '{ print $3 }')
write_s=$(echo "$(cat /sys/fs/ext4/$dev_base/session_write_kbytes) / 1024 / 1024" | bc)
write_t=$(echo "scale=2; $(cat /sys/fs/ext4/$dev_base/lifetime_write_kbytes) / 1024 / 1024 / 1024" | bc)
log "hd  used=$used session=${write_s}G total=${write_t}T"

dev=$($MC_BIN_DISK_CONTROL -S)
dev_base=$(sed -e 's@/dev/@@' <<< $dev)
used=$(df -h | grep "^$dev" | awk '{ print $3 }')
write_s=$(echo "scale=2; $(cat /sys/fs/ext4/$dev_base/session_write_kbytes) / 1024 / 1024" | bc)
write_t=$(echo "scale=2; $(cat /sys/fs/ext4/$dev_base/lifetime_write_kbytes) / 1024 / 1024 / 1024" | bc)
log "ssd used=$used session=${write_s}G total=${write_t}T"

if [ $wakeup_time -ne -1 ];then
    next_wakeup_time=$(awk -v epoc=$wakeup_time 'BEGIN { print strftime("%Y/%m/%d %H:%M:%S", epoc) }')

    if [ -z "$SSH_CONNECTION" ];then
        if [ $gui = true ];then
            timeout=5
        else
            timeout=60
        fi

        echo -e "computer will be shutdown in $timeout seconds.\nto cancel shutdown type\n\n\nmd abort\n\n" | write mc

        xrandr -display :0 > /dev/null 2>&1
        if [ $? -eq 0 ];then
            zenity --question --no-wrap --timeout=$timeout --display=:0.0 --text="<span font_desc='40'>next wakeup: $next_wakeup_time\n\nShutDown ?</span>"
        else
            sleep $timeout
        fi

        if [ $? -ne 1 ];then
            if [ -e $MC_ABORT_SHUTDOWN ];then
                /bin/rm $MC_ABORT_SHUTDOWN
                log "shutdown cancelled"
            else
                log "shutdown=yes : X Server"
                log "next wakeup time: $next_wakeup_time"
                log "next job file : $next_job_file"
                do_shutdown
            fi
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
