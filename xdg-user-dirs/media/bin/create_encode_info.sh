#!/bin/bash
source $(dirname $0)/00.conf

find $MC_DIR_VOLUME_INFO -type f -ctime +7 -delete
find $MC_DIR_FRAME_INFO  -type f -ctime +7 -delete

for xml in $(find $MC_DIR_DOWNSIZE_ENCODE_RESERVED -type f -name '*.xml' | sort);do

    job_file_base=$(basename $xml .xml)
    job_file_ts=${job_file_base}.ts
    input_ts_file=${MC_DIR_TS}/${job_file_ts}

    if [ ! -f ${MC_DIR_FRAME_INFO}/${job_file_ts} ];then

        ffmpeg -y \
            -t 10 \
            -i $input_ts_file \
            -f matroska \
            -pass 1 \
            -passlogfile ${MC_DIR_TMP}/ffmpeg-passlog \
            -threads 1 \
            -s 160x90 \
            -r 30000/1001 \
            -c:v h264 \
            -profile:v baseline \
            -preset:v ultrafast \
            -level 3.0 \
            -an \
            /dev/null

            mv ${MC_DIR_TMP}/ffmpeg-passlog-0.log ${MC_DIR_FRAME_INFO}/${job_file_ts}
    fi

    if [ ! -f ${MC_DIR_VOLUME_INFO}/${job_file_ts} ];then

        max_volume=$(ffmpeg -i $input_ts_file -vn -af volumedetect -f null /dev/null 2>&1 |
        grep 'max_volume:' | awk -F 'max_volume:' '{ print $2 }' |
        awk '{ print $1 }' | sort -n | tail -n 1 |
        awk '{ if ($1 < 0) print $1 * -1; else print 0 }')

        echo $max_volume > ${MC_DIR_VOLUME_INFO}/${job_file_ts}
        vmtouch -q -e $input_ts_file
    fi

done
