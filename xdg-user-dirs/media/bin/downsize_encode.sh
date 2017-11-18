#!/bin/bash
source $(dirname $0)/00.conf

time_limit=$1
if [ -z "$time_limit" ];then
    echo "$0 TIME_LIMIT_EPOCH"
    exit
fi

log "gpu_encode start"

rectime_max=$((60 * 60 * 6))
count=0
exceed_time_limit=0

for ((r = 0; r < 6; r++));do

    for xml in $(find $MC_DIR_DOWNSIZE_ENCODE_RESERVED -type f -name '*.xml' | sort);do

        job_file_base=$(basename $xml .xml)
        job_file_ts=${job_file_base}.ts
        job_file_xml=${job_file_base}.xml
        job_file_mkv=${job_file_base}.mkv
        input_ts_file=${MC_DIR_TS}/${job_file_ts}
        job_file_mkv_abs=${MC_DIR_ENCODE_DOWNSIZE}/${job_file_mkv}
        title=$(print_title                                         ${MC_DIR_DOWNSIZE_ENCODE_RESERVED}/${job_file_xml})
        original_file=$(xmlsel -t -m //original-file -v .           ${MC_DIR_DOWNSIZE_ENCODE_RESERVED}/${job_file_xml})
        rec_time=$(xmlsel -t -m //rec-time -v .                     ${MC_DIR_DOWNSIZE_ENCODE_RESERVED}/${job_file_xml})
        foundby=$(xmlsel -t -m //foundby -v .                       ${MC_DIR_DOWNSIZE_ENCODE_RESERVED}/${job_file_xml} | sed -e 's/Finder//')
        filename_web=${title}_$(date +%m%d).mkv

        ffprobe -show_format $input_ts_file > /dev/null 2>&1
        if [ $? -eq 0 ];then
            duration=$(ffprobe -show_format $input_ts_file 2> /dev/null | grep ^duration= | awk -F = '{ printf("%d\n", $2) }')
        fi
        if [ -z "$duration" ];then
            /bin/mv ${MC_DIR_DOWNSIZE_ENCODE_RESERVED}/${job_file_xml} $MC_DIR_FAILED
            log "gpu_encode failed duration: $title $(hard_ware_info)"
            /bin/mv $xml $MC_DIR_FAILED
            continue
        fi
        if [ $duration -gt $rectime_max ];then
            duration=$rectime_max
        fi

        time_start=$(awk 'BEGIN { print systime() }')
        estimated_time=$(( duration / 2 + duration / 4 ))
        estimated_time_epoch=$(( time_start + estimated_time ))
        if [ $count -gt 0 -a $estimated_time_epoch -gt $time_limit ];then
            exceed_time_limit=1
            log "gpu_encode exceed time limit"
            break
        fi

        /bin/mv $xml $MC_DIR_ENCODING_GPU

        max_volume=$(ffmpeg -i $input_ts_file -vn -af volumedetect -f null /dev/null 2>&1 |
        grep 'max_volume:' | awk -F 'max_volume:' '{ print $2 }' |
        awk '{ print $1 }' | sort -n | tail -n 1 |
        awk '{ if ($1 < 0) print $1 * -1; else print 0 }')
        vmtouch -q -e $input_ts_file

        fifo=${MC_DIR_FIFO}/vaapi_$$
        mkfifo -m 644 $fifo

        nice ffmpeg -y -loglevel quiet \
        -vaapi_device /dev/dri/renderD128 \
        -i $fifo \
        -vf 'format=nv12,hwupload,deinterlace_vaapi,scale_vaapi=w=640:h=360' \
        -vcodec hevc_vaapi \
        -level 31 -qp 32 \
        -aspect 16:9 \
        -af volume=${max_volume}dB \
        -acodec aac \
        -f matroska \
        $job_file_mkv_abs &
        pid_ffmpeg=$!

        gst-launch-1.0 -q \
          filesrc \
          location=${input_ts_file} \
          blocksize=499712000 \
        ! queue \
          silent=true \
          max-size-buffers=1 \
          max-size-bytes=0 \
          max-size-time=0 \
        ! filesink location=$fifo \
          blocksize=4096000 &
        pid_read=$!

        (
            sleep $estimated_time
            kill -KILL $pid_ffmpeg > /dev/null 2>&1
            sleep 1
            kill -KILL $pid_read > /dev/null 2>&1
        ) &

        wait $pid_read
        wait $pid_ffmpeg
        rm -f $fifo

        duration=0
        ffprobe -show_format $job_file_mkv_abs > /dev/null 2>&1
        if [ $? -eq 0 ];then
            duration=$(ffprobe -show_format $job_file_mkv_abs 2> /dev/null | grep ^duration= | awk -F = '{ printf("%d\n", $2) }')
        fi
        integrity=$(($rec_time - $duration))
        if [ "$integrity" -lt 180 ];then
            if [ "$original_file" = "release" ];then
                /bin/rm $input_ts_file
                mv -f ${MC_DIR_THUMB}/${job_file_ts} ${MC_DIR_THUMB}/${job_file_mkv}
            fi

            mkvpropedit $job_file_mkv_abs --attachment-name record_description --add-attachment ${MC_DIR_ENCODING_GPU}/${job_file_xml}
            mkdir -p ${MC_DIR_WEBDAV_CONTENTS}/${foundby}
            ln $job_file_mkv_abs "${MC_DIR_WEBDAV_CONTENTS}/${foundby}/${filename_web}"

            /bin/rm ${MC_DIR_ENCODING_GPU}/${job_file_xml}

            time_end=$(awk 'BEGIN { print systime() }')
            (( took = (time_end - time_start) ))
            encode_time=$(awk -v epoch=$took 'BEGIN { print strftime("%H:%M:%S", epoch, 1) }')
            ts_time=$(awk -v epoch=$duration 'BEGIN { print strftime("%H:%M:%S", epoch, 1) }')
            encode_rate=$(awk -v ts_time=$duration -v encode_time=$took 'BEGIN { printf("%.2f", ts_time / encode_time) }')
            size=$(ls -sh $job_file_mkv_abs | awk '{ print $1 }')
            log "gpu_encode end: ${encode_rate}x $ts_time $encode_time $size $title $(hard_ware_info)"
        else
            log "gpu_encode failed: $job_file_xml $title $(hard_ware_info)"
            /bin/mv ${MC_DIR_ENCODING_GPU}/${job_file_xml} $MC_DIR_FAILED
        fi

        vmtouch -q -e $job_file_mkv_abs
        vmtouch -q -e $input_ts_file

        ((count++))
    done

    if [ $exceed_time_limit -eq 1 ];then
        break
    fi
    sleep 10

done

log "gpu_encode end"
bash $MC_BIN_SAFE_SHUTDOWN
