#!/bin/bash
source $(dirname $0)/00.conf

function do_encode_ffmpeg() {
    local base=$1
    local input=${MC_DIR_TS}/${base}.ts
    local output=${MC_DIR_ENCODE}/${base}.mp4

    ffmpeg -y -i $input \
    -f mp4 \
    -vsync 1 \
    -vcodec libx264 -fpre ${MC_DIR_BIN}/libx264-normal.ffpreset \
    -acodec copy \
    -s 960x540 -threads 3 \
    -r 30000/1001 \
    $output

#     -acodec libfaac -ab 256k \
#     -acodec libmp3lame -ac 2 -ar 48000 -ab 256k \
}
function do_encode_mencoder() {
    local base=$1
    local input=${MC_DIR_TS}/${base}.ts
    local output=${MC_DIR_ENCODE}/${base}.mp4

    mencoder $input -quiet \
    -of lavf -lavfopts format=mp4 \
    -ovc x264 -x264encopts crf=25.0:threads=3 \
    -vf scale=960:540 \
    -oac faac -faacopts quality=1000 \
    -o $output

#     -oac mp3lame -lameopts preset=extreme \
#     -oac faac -faacopts br=256 \
}
function is_encoding_job_running() {
    local running=$(find $MC_DIR_ENCODING -type f -name '*.xml' -printf '%f')
    if [ -n "$running" ];then
        log "encoding job: $running"
        ret=0
    else
        ret=1
    fi
    return $ret
}

is_encoding_job_running
if [ $? -eq 0 ];then
    exit
fi

xml=$(find $MC_DIR_ENCODE_RESERVED -type f -name '*.xml' | head -n 1)
if [ -n "$xml" ];then
    time_start=$(awk 'BEGIN { print systime() }')
    base=$(basename $xml .xml)

    mv $xml $MC_DIR_ENCODING

    do_encode_ffmpeg $base
#     do_encode_mencoder $base

    if [ $? -eq 0 ];then
        title=$(print_title ${MC_DIR_ENCODING}/${base}.xml | sed -e 's/[/"*[:space:]]/_/g')_$(echo $base | awk -F '-' '{ printf("%s_%s", $1, $2) }')
        ln -f "${MC_DIR_THUMB}/${base}" "${MC_DIR_TITLE_ENCODE}/${title}.png"
        touch -t 200001010000 "${MC_DIR_TITLE_ENCODE}/${title}.png"
        time_end=$(awk 'BEGIN { print systime() }')
        (( took = (time_end - time_start) / 60 ))
        log "encoding $base $title time: $took minutes"
        mv ${MC_DIR_ENCODING}/${base}.xml $MC_DIR_ENCODE_FINISHED
    else
        mv ${MC_DIR_ENCODING}/${base}.xml $MC_DIR_FAILED
    fi

    bash $MC_BIN_SAFE_SHUTDOWN
fi
