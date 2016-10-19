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

    if [ -f ${MC_DIR_TS}/${job_file_ts} ];then
        input_ts_file=${MC_DIR_TS}/${job_file_ts}
    elif [ -f ${MC_DIR_TS_HD}/${job_file_ts} ];then
        input_ts_file=${MC_DIR_TS_HD}/${job_file_ts}
    fi

    time_start=$(awk 'BEGIN { print systime() }')

    fifo_dir=/tmp/pt3/fifo
    mkdir -p $fifo_dir
    fifo_ffmpeg=${fifo_dir}/ffmpeg_$$
    mkfifo -m 644 $fifo_ffmpeg

    nice -n 10 \
    gst-launch-1.0 -q filesrc location=$fifo_ffmpeg \
     ! queue \
       max-size-buffers=0 \
       max-size-time=0 \
       max-size-bytes=100000000 \
     ! tsparse \
     ! tsdemux name=demux \
     demux. \
            ! queue \
            ! mpegvideoparse \
            ! vaapidecodebin \
              deinterlace-method=none \
            ! vaapipostproc \
              deinterlace-mode=interlaced \
              deinterlace-method=bob \
              scale-method=fast \
              height=$encode_height \
            ! videorate \
              max-rate=30 \
            ! vaapih264enc \
               tune=high-compression \
               rate-control=cqp \
               init-qp=32 \
               min-qp=20 \
            ! mux. \
     demux. \
            ! queue \
            ! aacparse \
            ! avdec_aac \
            ! avenc_aac \
            ! mux. \
     matroskamux name=mux min-index-interval=10000000000 ! filesink location=${MC_DIR_MP4}/${job_file_mkv} &
    pid_gst=$!

    nice -n 10 \
    ffmpeg -y \
    -loglevel quiet \
    -i $input_ts_file \
    -threads 1 \
    -vcodec copy \
    -acodec copy \
    -f mpegts $fifo_ffmpeg &
    pid_ffmpeg=$!


    (
        sleep $((rec_time * 2))

        sleep 10
        kill -TERM $pid_ffmpeg > /dev/null 2>&1
        sleep 10
        kill -KILL $pid_ffmpeg > /dev/null 2>&1

        sleep 10
        kill -TERM $pid_gst > /dev/null 2>&1
        sleep 10
        kill -KILL $pid_gst > /dev/null 2>&1
    ) &

    wait $pid_ffmpeg
    wait $pid_gst

    rm -f $fifo_ffmpeg

    ffprobe -show_format ${MC_DIR_MP4}/${job_file_mkv} > /dev/null 2>&1
    if [ $? -eq 0 ];then
        duration=$(ffprobe -show_format ${MC_DIR_MP4}/${job_file_mkv} 2> /dev/null | grep ^duration= | awk -F = '{ printf("%d\n", $2) }')
        integrity=$(($rec_time - $duration))
        if [ "$integrity" -lt 180 ];then

            if [ "$original_file" = "release" ];then
                /bin/rm $input_ts_file
            fi

            /bin/rm ${MC_DIR_ENCODING}/${job_file_xml}
            stat --format=%s ${MC_DIR_MP4}/${job_file_mkv} > ${MC_DIR_FILE_SIZE}/${job_file_mkv}

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
