#!/bin/bash
source $(dirname $0)/00.conf
export DISPLAY=:0

job_file_base=$1
job_file_xml=${job_file_base}.xml
job_file_ts=${job_file_base}.ts
job_file_mkv=${job_file_base}.mkv

if [ ! -f ${MC_DIR_RESERVED}/${job_file_xml} ];then
    log "file not found: $job_file_xml"
    exit
fi

title=$(print_title ${MC_DIR_RESERVED}/${job_file_xml})
start=$(xmlsel -t -m "//epoch[@type='start']" -v '.' ${MC_DIR_RESERVED}/${job_file_xml})
end=$(xmlsel -t -m "//epoch[@type='stop']" -v '.' ${MC_DIR_RESERVED}/${job_file_xml})
rec_channel=$(xmlsel -t -m //rec-channel -v . ${MC_DIR_RESERVED}/${job_file_xml})
rec_time=$(xmlsel -t -m //rec-time -v . ${MC_DIR_RESERVED}/${job_file_xml})
channel=$(xmlsel -t -m //programme -v @channel ${MC_DIR_RESERVED}/${job_file_xml})
broadcasting=$(xmlsel -t -m '//broadcasting' -v '.' ${MC_DIR_RESERVED}/${job_file_xml})
foundby=$(xmlsel -t -m //foundby -v . ${MC_DIR_RESERVED}/${job_file_xml} | sed -e 's/Finder//')
original_file=$(xmlsel -t -m //original-file -v . ${MC_DIR_RESERVED}/${job_file_xml})
encode_width=$(xmlsel -t -m //encode-width   -v . ${MC_DIR_RESERVED}/${job_file_xml})
encode_height=$(xmlsel -t -m //encode-height -v . ${MC_DIR_RESERVED}/${job_file_xml})
encode_bitrate=$(xmlsel -t -m //encode-bitrate -v . ${MC_DIR_RESERVED}/${job_file_xml})
now=$(awk 'BEGIN { print systime() }')
((now = now - 120))

bash $MC_BIN_SMB_JOB &
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

        fifo_dir=/tmp/pt3/fifo
        mkdir -p $fifo_dir
        fifo_recpt1=${fifo_dir}/recpt1_$$
        fifo_ffmpeg=${fifo_dir}/ffmpeg_$$
        fifo_tail=${fifo_dir}/tee_$$
        mkfifo -m 644 $fifo_recpt1
        mkfifo -m 644 $fifo_ffmpeg
        mkfifo -m 644 $fifo_tail

        if [ "$original_file" = "keep" ];then
            gst_input=$fifo_tail
            ffmpeg_output=${MC_DIR_TS}/${job_file_ts}
            job_file_path=${MC_DIR_TS}/${job_file_ts}
        else
            gst_input=$fifo_ffmpeg
            ffmpeg_output=$fifo_ffmpeg
            job_file_path=${MC_DIR_MP4}/${job_file_mkv}
        fi

        nice -n 5 \
        gst-launch-1.0 -q \
         filesrc location=$gst_input ! tsdemux name=demux \
         demux. ! queue \
                ! mpegvideoparse \
                ! vaapidecode \
                ! queue \
                  leaky=upstream \
                ! vaapipostproc \
                  deinterlace-mode=auto \
                  deinterlace-method=bob \
                  height=$encode_height \
                ! vaapiencode_h264 \
                   tune=high-compression \
                   rate-control=cqp \
                   init-qp=34 \
                   min-qp=1 \
                ! mux. \
         demux. ! queue \
                  leaky=upstream \
                  max-size-buffers=0 \
                  max-size-time=0 \
                  max-size-bytes=104857600 \
                ! aacparse \
                ! mux. \
         matroskamux name=mux ! filesink location=${MC_DIR_MP4}/${job_file_mkv} &
        pid_gst=$!

        ffmpeg -y -i $fifo_recpt1 \
        -loglevel quiet \
        -threads 1 \
        -f mpegts \
        -vcodec copy \
        -acodec libfdk_aac -b:a 256k \
        $ffmpeg_output &
        pid_ffmpeg=$!

        if [ "$original_file" = "keep" ];then
            touch ${MC_DIR_TS}/${job_file_ts}
            tail --follow --retry --sleep-interval=0.5 ${MC_DIR_TS}/${job_file_ts} > $fifo_tail &
            pid_tail=$!
        fi

        $MC_BIN_REC --b25 --sid ${ch_array[0]} ${ch_array[1]} $rec_time_adjust $fifo_recpt1 &
        pid_recpt1=$!
        (
            sleep $rec_time_adjust
            sleep 10

            kill -TERM $pid_recpt1
            sleep 1
            kill -KILL $pid_recpt1
        ) &

        wait $pid_recpt1
        mv ${MC_DIR_RECORDING}/${job_file_xml} $MC_DIR_RECORD_FINISHED

        sync
        (
            sleep 10

            if [ "$original_file" = "keep" ];then
                kill -TERM $pid_tail
                sleep 1
                kill -KILL $pid_tail
                sleep 5
            fi

            kill -TERM $pid_ffmpeg
            sleep 1
            kill -KILL $pid_ffmpeg
            sleep 5

            kill -TERM $pid_gst
            sleep 1
            kill -KILL $pid_gst
        ) &

        wait $pid_gst

        rm -f $fifo_recpt1
        rm -f $fifo_ffmpeg
        rm -f $fifo_tail

        if [ "$original_file" = "keep" ];then
            thumb_file=${MC_DIR_THUMB}/${job_file_ts}
        else
            thumb_file=${MC_DIR_THUMB}/${job_file_mkv}
        fi
        ffmpeg -y -i $job_file_path -f image2 -pix_fmt yuv420p -vframes 1 -ss 5 -s 320x180 -an -deinterlace ${thumb_file}.png > /dev/null 2>&1
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

        ffprobe -show_format $job_file_path
        if [ $? -eq 0 ];then
            duration=$(ffprobe -show_format $job_file_path | grep ^duration= | awk -F = '{ printf("%d\n", $2) }')
            integrity=$(($rec_time - $duration))
            if [ "$integrity" -lt 60 ];then
                python ${MC_DIR_DB_RATING}/create.py ${MC_DIR_RECORD_FINISHED}/${job_file_xml} >> ${MC_DIR_DB_RATING}/log 2>&1
            else
                log "failed: $title ts_duration=$duration rec_time=$rec_time"
            fi
        else
            log "failed: $title ts_duration=$duration rec_time=$rec_time"
        fi

        if [ "$original_file" = "keep" ];then
            stat --format=%s ${MC_DIR_TS}/${job_file_ts}  > ${MC_DIR_FILE_SIZE}/${job_file_ts}
        fi
        stat --format=%s ${MC_DIR_MP4}/${job_file_mkv} > ${MC_DIR_FILE_SIZE}/${job_file_mkv}

        mv ${MC_DIR_RECORD_FINISHED}/${job_file_xml} $MC_DIR_JOB_FINISHED
        log "rec end: $title $(hard_ware_info)"

        bash $MC_BIN_SAFE_SHUTDOWN
    else
        log "failed: $job_file_xml"
        log "caused by: not in time now=$now start=$start"
        mv ${MC_DIR_RESERVED}/${job_file_xml} $MC_DIR_FAILED
    fi
fi
