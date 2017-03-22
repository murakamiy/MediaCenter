#!/bin/bash
source $(dirname $0)/00.conf

job_file_base=$1
job_file_xml=${job_file_base}.xml
job_file_ts=${job_file_base}.ts

if [ ! -f ${MC_DIR_RESERVED}/${job_file_xml} ];then
    log "file not found: $job_file_xml"
    exit
fi

rec_dispatch_wait=${MC_DIR_REC_DISPATCH_WAIT}/${job_file_base}
title=$(print_title ${MC_DIR_RESERVED}/${job_file_xml})
start=$(xmlsel -t -m "//epoch[@type='start']" -v '.' ${MC_DIR_RESERVED}/${job_file_xml})
end=$(xmlsel -t -m "//epoch[@type='stop']" -v '.' ${MC_DIR_RESERVED}/${job_file_xml})
rec_channel=$(xmlsel -t -m //rec-channel -v . ${MC_DIR_RESERVED}/${job_file_xml})
rec_time=$(xmlsel -t -m //rec-time -v . ${MC_DIR_RESERVED}/${job_file_xml})
channel=$(xmlsel -t -m //programme -v @channel ${MC_DIR_RESERVED}/${job_file_xml})
broadcasting=$(xmlsel -t -m '//broadcasting' -v '.' ${MC_DIR_RESERVED}/${job_file_xml})
foundby=$(xmlsel -t -m //foundby -v . ${MC_DIR_RESERVED}/${job_file_xml} | sed -e 's/Finder//')
do_encode=$(xmlsel -t -m //do-encode -v . ${MC_DIR_RESERVED}/${job_file_xml})
now=$(awk 'BEGIN { print systime() }')
((now = now - 120))

# bash $MC_BIN_SMB_JOB &
# bash $MC_BIN_DOWNSIZE_ENCODE &

running=$(find $MC_DIR_RECORDING -type f -name '*.xml' | wc -l)
if [ $running -ge 4 ];then
    log "failed: $job_file_xml"
    log "caused by: $(find $MC_DIR_RECORDING -type f -name '*.xml')"
    mv ${MC_DIR_RESERVED}/${job_file_xml} $MC_DIR_FAILED
else
    if [ $now -lt $start ];then
        log "rec start: $title $(hard_ware_info)"
        mv ${MC_DIR_RESERVED}/${job_file_xml} $MC_DIR_RECORDING

        if [ "$broadcasting" = "BS" ];then
            channel_file=$MC_FILE_CHANNEL_BS
        elif [ "$broadcasting" = "CS" ];then
            channel_file=$MC_FILE_CHANNEL_CS
        elif [ "$broadcasting" = "Digital" ];then
            channel_file=$MC_FILE_CHANNEL_DIGITAL
        fi
        ch_array=($(awk -F '\t' -v channel=$rec_channel '{ if ($1 == channel) printf("%s %s", $2, $4) }' $channel_file))

        now=$(awk 'BEGIN { print systime() }')
        rec_time_adjust=$(($end - $now - 20))
        rec_ts_file=${MC_DIR_TS}/${job_file_ts}

        touch $rec_dispatch_wait
        inotifywait -e delete_self $rec_dispatch_wait
        $MC_BIN_REC --b25 --sid ${ch_array[0]} $rec_channel $rec_time_adjust $rec_ts_file

        mv ${MC_DIR_RECORDING}/${job_file_xml} $MC_DIR_RECORD_FINISHED

        job_file_path=${MC_DIR_TS}/${job_file_ts}
        thumb_file=${MC_DIR_THUMB}/${job_file_ts}

        bash $MC_BIN_THUMB $job_file_path ${thumb_file}.png
        if [ $? -eq 0 ];then
            mv ${thumb_file}.png $thumb_file
        else
            cp $MC_FILE_THUMB $thumb_file
        fi

        foundby_dir="${MC_DIR_TITLE_TS}/${foundby}"
        mkdir -p "$foundby_dir"
        for i in $(seq -w 1 99);do
            if [ ! -e "${foundby_dir}/${title}_${i}.png" ];then
                break
            fi
        done
        ln $thumb_file "${foundby_dir}/${title}_${i}.png"

        today=$(date +%Y%m%d)
        foundby_dir="${MC_DIR_TITLE_TS_NEW}/${foundby}"
        mkdir -p "$foundby_dir"
        for i in $(seq -w 1 99);do
            if [ ! -e "${foundby_dir}/${today}_${title}_${i}.png" ];then
                break
            fi
        done
        ln $thumb_file "${foundby_dir}/${today}_${title}_${i}.png"

        ffprobe -show_format $job_file_path > /dev/null 2>&1
        if [ $? -eq 0 ];then
            duration=$(ffprobe -show_format $job_file_path 2> /dev/null | grep ^duration= | awk -F = '{ printf("%d\n", $2) }')
            integrity=$(($rec_time - $duration))
            if [ "$integrity" -lt 60 ];then
                python2 ${MC_DIR_DB_RATING}/create.py ${MC_DIR_RECORD_FINISHED}/${job_file_xml} >> ${MC_DIR_DB_RATING}/log 2>&1
                if [ "$do_encode" = "True" ];then
                    cp ${MC_DIR_RECORD_FINISHED}/${job_file_xml} $MC_DIR_DOWNSIZE_ENCODE_RESERVED
                fi
            else
                log "failed: $title ts_duration=$duration rec_time=$rec_time"
            fi
        else
            log "failed: $title ts_duration=$duration rec_time=$rec_time"
        fi

        stat --format=%s ${MC_DIR_TS}/${job_file_ts}  > ${MC_DIR_FILE_SIZE}/${job_file_ts}
        vmtouch -q -e $job_file_path

        mv ${MC_DIR_RECORD_FINISHED}/${job_file_xml} $MC_DIR_JOB_FINISHED
        log "rec end: $title $(hard_ware_info)"

        bash $MC_BIN_SAFE_SHUTDOWN
    else
        log "failed: $job_file_xml"
        log "caused by: not in time now=$now start=$start"
        mv ${MC_DIR_RESERVED}/${job_file_xml} $MC_DIR_FAILED
    fi
fi
