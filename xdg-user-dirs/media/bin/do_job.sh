#!/bin/bash
source $(dirname $0)/00.conf

job_file_base=$1
job_file_xml=${job_file_base}.xml
job_file_ts=${job_file_base}.ts
job_file_mp4=${job_file_base}.mp4

if [ ! -f ${MC_DIR_RESERVED}/${job_file_xml} ];then
    log "file not found: $job_file_xml"
    exit
fi

title=$(print_title ${MC_DIR_RESERVED}/${job_file_xml})
start=$(xmlsel -t -m "//epoch[@type='start']" -v '.' ${MC_DIR_RESERVED}/${job_file_xml})
end=$(xmlsel -t -m "//epoch[@type='stop']" -v '.' ${MC_DIR_RESERVED}/${job_file_xml})
rec_channel=$(xmlsel -t -m //rec-channel -v . ${MC_DIR_RESERVED}/${job_file_xml})
rec_time=$(xmlsel -t -m //rec-time -v . ${MC_DIR_RESERVED}/${job_file_xml})
transport_stream_id=$(xmlsel -t -m //transport-stream-id -v . ${MC_DIR_RESERVED}/${job_file_xml})
service_id=$(xmlsel -t -m //service-id -v . ${MC_DIR_RESERVED}/${job_file_xml})
event_id=$(xmlsel -t -m //event-id -v . ${MC_DIR_RESERVED}/${job_file_xml})
channel=$(xmlsel -t -m //programme -v @channel ${MC_DIR_RESERVED}/${job_file_xml})
broadcasting=$(xmlsel -t -m '//broadcasting' -v '.' ${MC_DIR_RESERVED}/${job_file_xml})
foundby=$(xmlsel -t -m //foundby -v . ${MC_DIR_RESERVED}/${job_file_xml} | sed -e 's/Finder//')
now=$(awk 'BEGIN { print systime() }')
((now = now - 120))
ffmpeg_rec_time_max=10800

bash $MC_BIN_SMB_JOB &
bash $MC_BIN_ENCODE $channel &
bash $MC_BIN_MIGRATE_JOB &

running=$(find $MC_DIR_RECORDING -type f -name '*.xml' | wc -l)
if [ $running -ge 4 ];then
    log "failed: $job_file_xml"
    log "caused by: $(find $MC_DIR_RECORDING -type f -name '*.xml')"
    mv ${MC_DIR_RESERVED}/${job_file_xml} $MC_DIR_FAILED
else
    if [ $now -lt $start ];then
        log "rec start: $title $(hard_ware_info)"
        mv ${MC_DIR_RESERVED}/${job_file_xml} $MC_DIR_RECORDING

        if (($rec_time < $ffmpeg_rec_time_max));then
            fifo_dir=/tmp/pt3/fifo
            mkdir -p $fifo_dir
            fifo_b25=${fifo_dir}/b25_$$
            mkfifo -m 644 $fifo_b25

            nice -n 5 \
            ffmpeg -y -i $fifo_b25 -f mp4 \
                -s 640x360 \
                -loglevel quiet \
                -threads 1 \
                -vsync 1 \
                -r 30000/1001 \
                -filter:v yadif=0 \
                -b:v 500k \
                -vcodec libx264 -acodec libvo_aacenc \
                -ac 2 \
                -preset:v superfast \
                ${MC_DIR_MP4}/${job_file_mp4} &

            pid_ffmpeg=$!

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

        now=$(awk 'BEGIN { print systime() }')
        rec_time_adjust=$(($end - $now - 10))

        $MC_BIN_REC --b25 --strip --sid ${ch_array[0]} ${ch_array[1]} $rec_time_adjust ${MC_DIR_TS}/${job_file_ts}

        mv ${MC_DIR_RECORDING}/${job_file_xml} $MC_DIR_RECORD_FINISHED

        if (($rec_time < $ffmpeg_rec_time_max));then
            sync
            kill -TERM $pid_tail
            ( sleep 60; kill -KILL $pid_ffmpeg ) &
            wait $pid_ffmpeg
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

        ffprobe -show_format ${MC_DIR_TS}/${job_file_ts}
        if [ $? -eq 0 ];then
            duration=$(ffprobe -show_format ${MC_DIR_TS}/${job_file_ts} | grep ^duration= | awk -F = '{ printf("%d\n", $2) }')
            integrity=$(($rec_time - $duration))
            if [ "$integrity" -lt 60 ];then
                python ${MC_DIR_DB_RATING}/create.py ${MC_DIR_RECORD_FINISHED}/${job_file_xml} >> ${MC_DIR_DB_RATING}/log 2>&1
            else
                log "failed: $title ts_duration=$duration rec_time=$rec_time"
            fi
        else
            log "failed: $title ts_duration=$duration rec_time=$rec_time"
        fi

        mv ${MC_DIR_RECORD_FINISHED}/${job_file_xml} $MC_DIR_JOB_FINISHED
        log "rec end: $title $(hard_ware_info)"

        bash $MC_BIN_SAFE_SHUTDOWN
    else
        log "failed: $job_file_xml"
        log "caused by: not in time now=$now start=$start"
        mv ${MC_DIR_RESERVED}/${job_file_xml} $MC_DIR_FAILED
    fi
fi
