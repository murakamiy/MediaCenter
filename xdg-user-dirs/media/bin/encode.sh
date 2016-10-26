#!/bin/bash
source $(dirname $0)/00.conf

function do_encode_ffmpeg() {
    local base=$1
    local input=${MC_DIR_TS}/${base}.ts
    local output=${MC_DIR_ENCODE}/${base}.mp4

    fifo=${MC_DIR_FIFO}/x264_$$
    mkfifo -m 644 $fifo

    nice -n 5 \
    ffmpeg -y -i $fifo -f mp4 \
        -loglevel quiet \
        -threads 2 \
        -s 1280x720 \
        -r 30000/1001 \
        -vcodec h264 \
        -profile:v high \
        -preset:v faster \
        -crf 25 -level 31 \
        -acodec aac -b:a 256k \
        $output &
    pid_ffmpeg=$!

    dd if=$input of=$fifo ibs=100M obs=512 &
    pid_read=$!

    wait $pid_read
    wait $pid_ffmpeg

    rm -f $fifo
}

xml=$(find $MC_DIR_ENCODE_RESERVED -type f -name '*.xml' | sort | head -n 1)
if [ -n "$xml" ];then
    time_start=$(awk 'BEGIN { print systime() }')
    base=$(basename $xml .xml)
    title=$(print_title $xml)
    title=${title}_$(echo $base | awk -F '-' '{ printf("%s_%s", $1, $2) }')
    log "encode start: $title $(hard_ware_info)"
    mv $xml $MC_DIR_ENCODING

    do_encode_ffmpeg $base

    if [ $? -eq 0 ];then
        time_end=$(awk 'BEGIN { print systime() }')
        (( took = (time_end - time_start) / 60 ))
        mv ${MC_DIR_ENCODING}/${base}.xml $MC_DIR_ENCODE_FINISHED

        thumb_file=${MC_DIR_THUMB}/${base}.mp4
        bash $MC_BIN_THUMB ${MC_DIR_ENCODE}/${base}.mp4 ${thumb_file}.png
        if [ $? -eq 0 ];then
            mv ${thumb_file}.png $thumb_file
        else
            cp $MC_FILE_THUMB $thumb_file
        fi

        mp4tags -c "$title" ${MC_DIR_ENCODE}/${base}.mp4

        ln -f $thumb_file "${MC_DIR_TITLE_ENCODE}/${title}.png"
        touch -t 200001010000 "${MC_DIR_TITLE_ENCODE}/${title}.png"

        log "encode end: $took min $title $(hard_ware_info)"
    else
        log "encode failed: $title $(hard_ware_info)"
        mv ${MC_DIR_ENCODING}/${base}.xml $MC_DIR_FAILED
    fi

    bash $MC_BIN_SAFE_SHUTDOWN
fi
