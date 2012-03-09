#!/bin/bash
source $(dirname $0)/00.conf

job_file_base=$1
job_file_xml=${job_file_base}.xml
job_file_ts=${job_file_base}.ts

title=$(print_title ${MC_DIR_RESERVED}/${job_file_xml})
category=$(print_category ${MC_DIR_RESERVED}/${job_file_xml})
rec=$(xmlsel -t -m '//command' -m "rec" -v '.' ${MC_DIR_RESERVED}/${job_file_xml})
start=$(xmlsel -t -m "//epoch[@type='start']" -v '.' ${MC_DIR_RESERVED}/${job_file_xml})
end=$(xmlsel -t -m "//epoch[@type='stop']" -v '.' ${MC_DIR_RESERVED}/${job_file_xml})
now=$(awk 'BEGIN { print systime() }')
((now = now - 120))

bash $MC_BIN_ENCODE &
running=$(find $MC_DIR_RECORDING -type f -name '*.xml' | wc -l)
if [ $running -ge 4 ];then
    log "failed: $job_file_xml"
    log "caused by: $(find $MC_DIR_RECORDING -type f -name '*.xml')"
    mv ${MC_DIR_RESERVED}/${job_file_xml} $MC_DIR_FAILED
else
    if [ $now -lt $start ];then
        log "start: $job_file_xml"
        mv ${MC_DIR_RESERVED}/${job_file_xml} $MC_DIR_RECORDING
        sudo lcdprint -s $start -e $end

        fifo_dir=/tmp/dvb-pt2/fifo
        mkdir -p $fifo_dir
        fifo_tail=${fifo_dir}/tail_$$
        mkfifo -m 644 $fifo_tail
        fifo_b25=${fifo_dir}/b25_$$
        mkfifo -m 644 $fifo_b25

        today=$(date +%d)

        echo "ffmpeg -y -i $fifo_b25 -f mp4 -vsync 1 -vcodec libx264 -acodec libfaac -s 360x240 -fpre /home/mc/work/encode/libx264-normal.ffpreset -vpre ipod320 ${MC_DIR_MP4}/${today}_${title}.mp4"
        ffmpeg -y -i $fifo_b25 -f mp4 -vsync 1 -vcodec libx264 -acodec libfaac -s 360x240 -fpre /home/mc/work/encode/libx264-normal.ffpreset -vpre ipod320 "${MC_DIR_MP4}/${today}_${title}.mp4" > /dev/null 2>&1 &
        pid_ffmpeg=$!
        b25 -v 0 $fifo_tail $fifo_b25 &
        pid_b25=$!
        touch ${MC_DIR_TS}/${job_file_ts}
        tail --follow --retry --sleep-interval=0.1 ${MC_DIR_TS}/${job_file_ts} > $fifo_tail &
        pid_tail=$!

        $rec

        mv ${MC_DIR_RECORDING}/${job_file_xml} $MC_DIR_RECORD_FINISHED

        sync
        sleep 20
        kill -TERM $pid_ffmpeg
        kill -TERM $pid_b25
        kill -TERM $pid_tail
        /bin/rm -f $fifo_tail
        /bin/rm -f $fifo_b25

        b25 -v 0 ${MC_DIR_TS}/${job_file_ts} ${MC_DIR_TS}/${job_file_ts}.b25

        ts_orig=$(stat --format=%s ${MC_DIR_TS}/${job_file_ts})
        ts_b25=$(stat --format=%s ${MC_DIR_TS}/${job_file_ts}.b25)
        ts_valid=$(( $ts_orig / 188 * 188 ))
        if [ $ts_b25 -eq $ts_valid ];then
            /bin/mv -f ${MC_DIR_TS}/${job_file_ts}.b25 ${MC_DIR_TS}/${job_file_ts}
        else
            /bin/rm -f ${MC_DIR_TS}/${job_file_ts}.b25
        fi

        thumb_file=${MC_DIR_THUMB}/${job_file_ts}
        echo "ffmpeg -y -i ${MC_DIR_TS}/${job_file_ts} -f image2 -pix_fmt yuv420p -vframes 1 -ss 5 -s 320x180 -an -deinterlace ${thumb_file}.png"
        ffmpeg -y -i ${MC_DIR_TS}/${job_file_ts} -f image2 -pix_fmt yuv420p -vframes 1 -ss 5 -s 320x180 -an -deinterlace ${thumb_file}.png > /dev/null 2>&1
        if [ $? -eq 0 ];then
            mv ${thumb_file}.png $thumb_file
        else
            cp $MC_FILE_THUMB $thumb_file
        fi
        category_dir="${MC_DIR_TITLE_TS}/${category}"
        mkdir -p "$category_dir"
        for i in $(seq -w 1 99);do
            if [ ! -e "${category_dir}/${title}${i}.png" ];then
                break
            fi
        done
        ln $thumb_file "${category_dir}/${title}${i}.png"

        python ${MC_DIR_DB_RATING}/create.py ${MC_DIR_RECORD_FINISHED}/${job_file_xml} >> ${MC_DIR_DB_RATING}/log 2>&1

        mv ${MC_DIR_RECORD_FINISHED}/${job_file_xml} $MC_DIR_JOB_FINISHED
        bash $MC_BIN_SAFE_SHUTDOWN
    else
        log "failed: $job_file_xml"
        log "caused by: not in time now=$now start=$start"
        mv ${MC_DIR_RESERVED}/${job_file_xml} $MC_DIR_FAILED
    fi
fi
