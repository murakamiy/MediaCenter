#!/bin/bash
source $(dirname $0)/00.conf
export DISPLAY=:0

cron_time=$(sed -e 's/:/ /g' <<< $MC_CRON_TIME)
awk -v cron_time="$cron_time" 'BEGIN {
    date = strftime("%Y %m %d")
    date_time = sprintf("%s %s", date, cron_time)
    cron_epoch = mktime(date_time)

    if (60 * 60 * 3 < cron_epoch - systime()) {
        exit 0
    }
    else {
        exit 1
    }
}'

if [ $? -eq 1 ];then
    exit
fi

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

    log "d_encode start: $title $(hard_ware_info)"

    if [ -f ${MC_DIR_TS}/${job_file_ts} ];then
        input_ts_file=${MC_DIR_TS}/${job_file_ts}
    elif [ -f ${MC_DIR_TS_HD}/${job_file_ts} ];then
        input_ts_file=${MC_DIR_TS_HD}/${job_file_ts}
    fi

    time_start=$(awk 'BEGIN { print systime() }')

    nice -n 10 \
    gst-launch-1.0 -q \
     filesrc location=$input_ts_file \
     ! video/mpegts \
     ! tsdemux name=demux \
     demux. \
            ! queue \
              max-size-buffers=2000 \
              max-size-time=0 \
              max-size-bytes=0 \
            ! mpegvideoparse \
            ! vaapidecode \
            ! vaapipostproc \
              deinterlace-mode=auto \
              deinterlace-method=bob \
              scale-method=fast \
              height=$encode_height \
            ! vaapih264enc \
               tune=high-compression \
               rate-control=cqp \
               init-qp=32 \
               min-qp=20 \
            ! mux. \
     demux. \
            ! queue \
              max-size-buffers=2000 \
              max-size-time=0 \
              max-size-bytes=0 \
            ! faad plc=true \
            ! audioconvert \
            ! 'audio/x-raw,channels=6' \
            ! faac rate-control=ABR \
            ! mux. \
     matroskamux name=mux min-index-interval=10000000000 ! filesink location=${MC_DIR_MP4}/${job_file_mkv}

    if [ $? -eq 0 ];then

        time_end=$(awk 'BEGIN { print systime() }')
        (( took = (time_end - time_start) / 60 ))

        /bin/rm ${MC_DIR_ENCODING}/${job_file_xml}
        stat --format=%s ${MC_DIR_MP4}/${job_file_mkv} > ${MC_DIR_FILE_SIZE}/${job_file_mkv}

        log "d_encode end: $took min $title $(hard_ware_info)"
    else
        log "d_encode failed: $title $(hard_ware_info)"
        /bin/mv ${MC_DIR_ENCODING}/${job_file_xml} $MC_DIR_FAILED
    fi

    bash $MC_BIN_SAFE_SHUTDOWN
fi
