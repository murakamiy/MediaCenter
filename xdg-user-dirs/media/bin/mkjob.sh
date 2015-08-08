#!/bin/bash
source $(dirname $0)/00.conf

log "start: $(hard_ware_info)"

touch ${MC_DIR_RECORDING}/mkjob.xml
trash-empty

rec_time=60
prefix_digital=digital
prefix_bs_cs=bs_cs

log 'starting epgdump_py digital'
array=($(awk '{ print $1 }' $MC_FILE_CHANNEL_DIGITAL))
prefix=$prefix_digital
for ((i = 0; i < ${#array[@]}; i++));do
    if [ $i -eq 0 ];then
        fifo_dir=/tmp/pt3/fifo
        mkdir -p $fifo_dir
        fifo_epg=${fifo_dir}/epg_$$
        mkfifo -m 644 $fifo_epg

        touch ${MC_DIR_TMP}/${prefix}_${array[$i]}.ts
        tail --follow --retry --sleep-interval=0.5 ${MC_DIR_TMP}/${prefix}_${array[$i]}.ts > $fifo_epg &
        pid_tail=$!
        $MC_BIN_REC ${array[$i]} $rec_time ${MC_DIR_TMP}/${prefix}_${array[$i]}.ts &
        pid_rec=$!

        arr=($(python $MC_BIN_EPGTIME $fifo_epg))
        update=${arr[0]}
        update_time=${arr[1]}
        sys_time=${arr[2]}
        epg_time=${arr[3]}

        if [ "$update" = "true" ];then
            sudo /bin/date $update_time
        fi
        log "time: update=$update sys=$sys_time epg=$epg_time"
        kill -TERM $pid_tail
        rm -f $fifo_epg
        wait $pid_rec
    else
        $MC_BIN_REC ${array[$i]} $rec_time ${MC_DIR_TMP}/${prefix}_${array[$i]}.ts
    fi
    (
        python $MC_BIN_EPGDUMP -e -c ${array[$i]} -i ${MC_DIR_TMP}/${prefix}_${array[$i]}.ts -o ${MC_DIR_EPG}/${prefix}_${array[$i]}.xml
        /bin/rm ${MC_DIR_TMP}/${prefix}_${array[$i]}.ts
    ) &
    pid_epg_digital_dump=$!
    if [ $i -eq $((${#array[@]} -1)) ];then
        wait $pid_epg_digital_dump
    fi
done &
pid_epg_digital=$!

if [ "$MC_RESERVE_SATELLITE" = "true" ];then
log 'starting epgdump_py bs cs'
array=(BS15_0 CS2 CS4)
prefix=$prefix_bs_cs
for ((i = 0; i < ${#array[@]}; i++));do
    $MC_BIN_REC ${array[$i]} $rec_time ${MC_DIR_TMP}/${prefix}_${array[$i]}.ts
    if [ "${array[$i]:0:2}" = "BS" ];then
        epg_param=" -b "
    elif [ "${array[$i]:0:2}" = "CS" ];then
        epg_param=" -s "
    fi
    (
        python $MC_BIN_EPGDUMP -e -d $epg_param -i ${MC_DIR_TMP}/${prefix}_${array[$i]}.ts -o ${MC_DIR_EPG}/${prefix}_${array[$i]}.xml
        /bin/rm ${MC_DIR_TMP}/${prefix}_${array[$i]}.ts
    ) &
    pid_epg_bs_cs_dump=$!
    if [ $i -eq $((${#array[@]} -1)) ];then
        wait $pid_epg_bs_cs_dump
    fi
done &
pid_epg_bs_cs=$!
fi

bash $MC_BIN_MIGRATE &
pid_mig_array=$!
bash $MC_BIN_SMB &
pid_smb=$!

log 'starting title'
find $MC_DIR_TITLE_TS_NEW -type f -ctime +7 -delete

log 'starting smb_play'
bash $MC_BIN_SMB_PLAY

log 'starting aggregate'
python ${MC_DIR_DB_RATING}/aggregate.py >> ${MC_DIR_DB_RATING}/log 2>&1
log 'end aggregate'

if [ "$MC_RESERVE_SATELLITE" = "true" ];then
    wait $pid_epg_bs_cs
    wait $pid_epg_digital
    log 'starting find program'
    python $MC_BIN_RESERVER "${prefix_digital}_*.xml" "${prefix_bs_cs}_*.xml"
else
    wait $pid_epg_digital
    log 'starting find program'
    python $MC_BIN_RESERVER "${prefix_digital}_*.xml"
fi

log 'starting rrd'
bash $MC_BIN_RRD

log 'starting xml format'
for f in $(find $MC_DIR_RESERVED $MC_DIR_EPG -type f -name '*.xml');do
    temp_file=$(mktemp)
    xmlstarlet format --encode utf-8 $f > $temp_file
    /bin/mv $temp_file $f
done

wait $pid_smb
wait $pid_mig_array
bash $MC_BIN_MIGRATE_MP4

find $MC_DIR_TITLE_TS -type d -delete

/bin/rm -f ${MC_DIR_RECORDING}/mkjob.xml

log "end: $(hard_ware_info)"

bash $MC_BIN_SAFE_SHUTDOWN
