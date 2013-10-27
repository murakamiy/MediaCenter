#!/bin/bash
source $(dirname $0)/00.conf

function do_encode_ffmpeg() {
    local base=$1
    local input=${MC_DIR_TS_HD}/${base}.ts
    local output=${MC_DIR_ENCODE_HD}/${base}.mp4

    avconv -y -i $input \
        -loglevel quiet \
        -threads 2 \
        -f mp4 \
        -s 1280x720 \
        -vsync 1 \
        -r 30000/1001 \
        -vcodec libx264 -acodec libvo_aacenc \
        -profile:v main -crf 25 -level 31 \
        $output
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

sum=$(echo $1 | md5sum | awk '{ print $1 }' | tr '[a-f]' '[A-F]')
sleep_time=$(echo "ibase = 16; $sum % 3C" | bc)
sleep $sleep_time

is_encoding_job_running
if [ $? -eq 0 ];then
    exit
fi

xml=$(find $MC_DIR_ENCODE_RESERVED -type f -name '*.xml' | sort | head -n 1)
if [ -n "$xml" ];then
    time_start=$(awk 'BEGIN { print systime() }')
    base=$(basename $xml .xml)
    title=$(print_title $xml)
    title=${title}_$(echo $base | awk -F '-' '{ printf("%s_%s", $1, $2) }')
    log "start: $title $(hard_ware_info)"
    mv $xml $MC_DIR_ENCODING

    $MC_BIN_USB_MOUNT
    do_encode_ffmpeg $base

    if [ $? -eq 0 ];then
        time_end=$(awk 'BEGIN { print systime() }')
        (( took = (time_end - time_start) / 60 ))
        log "encode time $took min $title"
        mv ${MC_DIR_ENCODING}/${base}.xml $MC_DIR_ENCODE_FINISHED

        thumb_file=${MC_DIR_THUMB}/${base}.mp4
        echo "ffmpeg -y -i ${MC_DIR_ENCODE_HD}/${base}.mp4 -f image2 -pix_fmt yuv420p -vframes 1 -ss 5 -s 320x180 -an -deinterlace ${thumb_file}.png"
        ffmpeg -y -i ${MC_DIR_ENCODE_HD}/${base}.mp4 -f image2 -pix_fmt yuv420p -vframes 1 -ss 5 -s 320x180 -an -deinterlace ${thumb_file}.png > /dev/null 2>&1

        if [ $? -eq 0 ];then
            mv ${thumb_file}.png $thumb_file
        else
            cp $MC_FILE_THUMB $thumb_file
        fi

        mp4tags -c "$title" ${MC_DIR_ENCODE_HD}/${base}.mp4

        ln -f $thumb_file "${MC_DIR_TITLE_ENCODE}/${title}.png"
        touch -t 200001010000 "${MC_DIR_TITLE_ENCODE}/${title}.png"
    else
        mv ${MC_DIR_ENCODING}/${base}.xml $MC_DIR_FAILED
    fi

    log "end: $title $(hard_ware_info)"

    bash $MC_BIN_SAFE_SHUTDOWN
fi
