#!/bin/bash
source $(dirname $0)/00.conf
export DISPLAY=:0

lock_file=/tmp/downsize_encode_lock

lockfile-create $lock_file
if [ $? -ne 0 ];then
    echo "lockfile-create failed: $0"
    exit 1
fi
lockfile-touch $lock_file &
pid_lock=$!

xml=$(find $MC_DIR_DOWNSIZE_ENCODE_RESERVED -type f -name '*.xml' | sort | head -n 1)
if [ -n "$xml" ];then
    mv $xml $MC_DIR_ENCODING
fi

kill -TERM $pid_lock
lockfile-remove $lock_file


if [ -n "$xml" ];then

    job_file_base=$(basename $xml .xml)
    job_file_mkv=${job_file_base}.mkv
    job_file_xml=${job_file_base}.xml
    job_file_ts=${job_file_base}.ts

    title=$(print_title                                 ${MC_DIR_ENCODING}/${job_file_xml})
    original_file=$(xmlsel -t -m //original-file -v .   ${MC_DIR_ENCODING}/${job_file_xml})
    encode_width=$(xmlsel -t -m //encode-width   -v .   ${MC_DIR_ENCODING}/${job_file_xml})
    encode_height=$(xmlsel -t -m //encode-height -v .   ${MC_DIR_ENCODING}/${job_file_xml})
    encode_bitrate=$(xmlsel -t -m //encode-bitrate -v . ${MC_DIR_ENCODING}/${job_file_xml})
    rec_time=$(xmlsel -t -m //rec-time -v .             ${MC_DIR_ENCODING}/${job_file_xml})

    log "d_encode start: $title $(hard_ware_info)"
    time_start=$(awk 'BEGIN { print systime() }')

    input_ts_file=${MC_DIR_TS}/${job_file_ts}
    fifo=${MC_DIR_FIFO}/vaapi_$$
    mkfifo -m 644 $fifo


    nice -n 10 ffmpeg -y -loglevel quiet \
    -vaapi_device /dev/dri/renderD128 \
    -hwaccel vaapi -hwaccel_output_format vaapi \
    -i $fifo \
    -f matroska \
    -threads 1 \
    -vf 'format=nv12|vaapi,hwupload,scale_vaapi=w=640:h=360' \
    -vcodec h264_vaapi \
    -profile 100 -level 31 -qp 25 \
    -aspect 16:9 \
    -acodec aac \
    ${MC_DIR_TS}/${job_file_mkv} &
    pid_ffmpeg=$!

    dd if=$input_ts_file of=$fifo ibs=200M obs=512 &
    pid_read=$!


    (
        sleep $((rec_time))

        sleep 10
        kill -TERM $pid_read > /dev/null 2>&1
        sleep 10
        kill -KILL $pid_read > /dev/null 2>&1

        sleep 10
        kill -INT  $pid_ffmpeg > /dev/null 2>&1
        sleep 60
        kill -TERM $pid_ffmpeg > /dev/null 2>&1
        sleep 10
        kill -KILL $pid_ffmpeg > /dev/null 2>&1
    ) &

    wait $pid_read
    wait $pid_ffmpeg

    rm -f $fifo


    ffprobe -show_format ${MC_DIR_TS}/${job_file_mkv} > /dev/null 2>&1
    if [ $? -eq 0 ];then
        duration=$(ffprobe -show_format ${MC_DIR_TS}/${job_file_mkv} 2> /dev/null | grep ^duration= | awk -F = '{ printf("%d\n", $2) }')
        integrity=$(($rec_time - $duration))
        if [ "$integrity" -lt 180 ];then

            if [ "$original_file" = "release" ];then
                /bin/rm $input_ts_file
            fi

            /bin/rm ${MC_DIR_ENCODING}/${job_file_xml}
            stat --format=%s ${MC_DIR_TS}/${job_file_mkv} > ${MC_DIR_FILE_SIZE}/${job_file_mkv}

            time_end=$(awk 'BEGIN { print systime() }')
            (( took = (time_end - time_start) / 60 ))
            log "d_encode end: $took min $title $(hard_ware_info)"
        else
            log "d_encode failed: $title $(hard_ware_info)"
            /bin/mv ${MC_DIR_ENCODING}/${job_file_xml} $MC_DIR_FAILED
        fi
    else
        log "d_encode failed: $title $(hard_ware_info)"
        /bin/mv ${MC_DIR_ENCODING}/${job_file_xml} $MC_DIR_FAILED
    fi

    bash $MC_BIN_SAFE_SHUTDOWN
fi
