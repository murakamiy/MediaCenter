#!/bin/bash
source $(dirname $0)/00.conf

job_file_base=$1
job_file_xml=${job_file_base}.xml
job_file_ts=${job_file_base}.ts

title=$(print_title ${MC_DIR_RESERVED}/${job_file_xml})
category=$(print_category ${MC_DIR_RESERVED}/${job_file_xml})
start=$(xmlsel -t -m "//epoch[@type='start']" -v '.' ${MC_DIR_RESERVED}/${job_file_xml})
end=$(xmlsel -t -m "//epoch[@type='stop']" -v '.' ${MC_DIR_RESERVED}/${job_file_xml})
rec_channel=$(xmlsel -t -m //rec-channel -v . ${MC_DIR_RESERVED}/${job_file_xml})
rec_time=$(xmlsel -t -m //rec-time -v . ${MC_DIR_RESERVED}/${job_file_xml})
transport_stream_id=$(xmlsel -t -m //transport-stream-id -v . ${MC_DIR_RESERVED}/${job_file_xml})
service_id=$(xmlsel -t -m //service-id -v . ${MC_DIR_RESERVED}/${job_file_xml})
event_id=$(xmlsel -t -m //event-id -v . ${MC_DIR_RESERVED}/${job_file_xml})
channel=$(xmlsel -t -m //programme -v @channel ${MC_DIR_RESERVED}/${job_file_xml})
broadcasting=$(xmlsel -t -m '//broadcasting' -v '.' ${MC_DIR_RESERVED}/${job_file_xml})
now=$(awk 'BEGIN { print systime() }')
((now = now - 120))
avconv_rec_time_max=3600

bash $MC_BIN_ENCODE $channel &
running=$(find $MC_DIR_RECORDING -type f -name '*.xml' | wc -l)
if [ $running -ge 4 ];then
    log "failed: $job_file_xml"
    log "caused by: $(find $MC_DIR_RECORDING -type f -name '*.xml')"
    mv ${MC_DIR_RESERVED}/${job_file_xml} $MC_DIR_FAILED
else
    if [ $now -lt $start ];then
        temp=$(sensors | grep 'Physical id 0:' | awk -F : '{ print $2 }' | awk '{ print $1 }')
        log "start : $title $temp"
        mv ${MC_DIR_RESERVED}/${job_file_xml} $MC_DIR_RECORDING

        if (($rec_time < $avconv_rec_time_max));then
            log "start mp4 : $title"
            fifo_dir=/tmp/pt3/fifo
            mkdir -p $fifo_dir
            fifo_b25=${fifo_dir}/b25_$$
            mkfifo -m 644 $fifo_b25

            today=$(date +%d)
            avconv -y -i $fifo_b25 -f mp4 \
                -s 640x360 \
                -loglevel quiet \
                -threads 1 \
                -vsync 1 \
                -vcodec libx264 -acodec libvo_aacenc \
                -profile:v baseline -crf 30 -level 30 \
                -maxrate:v 10000k -r:a 44100 -b:a 64k \
                "${MC_DIR_MP4}/${title}_${today}.mp4" &
            pid_avconv=$!

            touch ${MC_DIR_TS}/${job_file_ts}
            tail --follow --retry --sleep-interval=0.5 ${MC_DIR_TS}/${job_file_ts} > $fifo_b25 &
            pid_tail=$!
        fi

        if [ "$broadcasting" = "BS" ];then
            channel_file=$MC_FILE_CHANNEL_BS
        elif [ "$broadcasting" = "CS" ];then
            channel_file=$MC_FILE_CHANNEL_CS
        elif [ "$broadcasting" = "Digital" ];then
            channel_file=$MC_FILE_CHANNEL_DIGITAL
        fi
        ch_array=($(awk -F '\t' -v channel=$rec_channel '{ if ($1 == channel) printf("%s %s", $2, $4) }' $channel_file))

        $MC_BIN_REC --b25 --strip --sid ${ch_array[0]} ${ch_array[1]} $rec_time ${MC_DIR_TS}/${job_file_ts}

        mv ${MC_DIR_RECORDING}/${job_file_xml} $MC_DIR_RECORD_FINISHED

        if (($rec_time < $avconv_rec_time_max));then
            log "end mp4 : $title"
            sync
            kill -TERM $pid_tail
            wait $pid_avconv
            rm -f $fifo_b25
        fi

        thumb_file=${MC_DIR_THUMB}/${job_file_ts}
        echo "ffmpeg -y -i ${MC_DIR_TS}/${job_file_ts} -f image2 -pix_fmt yuv420p -vframes 1 -ss 5 -s 320x180 -an -deinterlace ${thumb_file}.png"
        ffmpeg -y -i ${MC_DIR_TS}/${job_file_ts} -f image2 -pix_fmt yuv420p -vframes 1 -ss 5 -s 320x180 -an -deinterlace ${thumb_file}.png > /dev/null 2>&1
        if [ $? -eq 0 ];then
            mv ${thumb_file}.png $thumb_file
        else
            cp $MC_FILE_THUMB $thumb_file
        fi
        category_dir="${MC_DIR_TITLE_TS}/${broadcasting}/${category}"
        mkdir -p "$category_dir"
        for i in $(seq -w 1 99);do
            if [ ! -e "${category_dir}/${title}_${i}.png" ];then
                break
            fi
        done
        ln $thumb_file "${category_dir}/${title}_${i}.png"

        python ${MC_DIR_DB_RATING}/create.py ${MC_DIR_RECORD_FINISHED}/${job_file_xml} >> ${MC_DIR_DB_RATING}/log 2>&1

        mv ${MC_DIR_RECORD_FINISHED}/${job_file_xml} $MC_DIR_JOB_FINISHED
        temp=$(sensors | grep 'Physical id 0:' | awk -F : '{ print $2 }' | awk '{ print $1 }')
        log "end : $title $temp"

        bash $MC_BIN_SAFE_SHUTDOWN
    else
        log "failed: $job_file_xml"
        log "caused by: not in time now=$now start=$start"
        mv ${MC_DIR_RESERVED}/${job_file_xml} $MC_DIR_FAILED
    fi
fi
