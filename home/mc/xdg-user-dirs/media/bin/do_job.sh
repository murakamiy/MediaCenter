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
mp4_time=$(( ($end - $start) / 3 ))
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

        mp4_tmp=${MC_DIR_MP4}/${job_file_base}_tmp.mp4
        fifo_rec=/tmp/fifo_rec$$
        mkfifo -m 644 $fifo_rec
        echo "ffmpeg -y -i $fifo_rec -f mp4 -t $mp4_time -vsync 1 -vcodec libx264 -acodec libfaac -s 360x240 -fpre /home/mc/work/encode/libx264-normal.ffpreset -vpre ipod320 $mp4_tmp"
        ffmpeg -y -i $fifo_rec -f mp4 -t $mp4_time -vsync 1 -vcodec libx264 -acodec libfaac -s 360x240 -fpre /home/mc/work/encode/libx264-normal.ffpreset -vpre ipod320 $mp4_tmp > /dev/null 2>&1 &
        pid_ffmpeg=$!

        $rec $fifo_rec

        kill -TERM $pid_ffmpeg
        /bin/rm -f $fifo_rec
        /bin/mv -f $mp4_tmp "${MC_DIR_MP4}/${title}.mp4" 

        mv ${MC_DIR_RECORDING}/${job_file_xml} $MC_DIR_RECORD_FINISHED

        thumb_file=${MC_DIR_THUMB}/$(basename $job_file_ts .ts)
        echo ffmpeg -i ${MC_DIR_TS}/${job_file_ts} -f image2 -pix_fmt yuv420p -vframes 1 -ss 5 -s 320x180 -an -deinterlace ${thumb_file}.png
        ffmpeg -i ${MC_DIR_TS}/${job_file_ts} -f image2 -pix_fmt yuv420p -vframes 1 -ss 5 -s 320x180 -an -deinterlace ${thumb_file}.png > /dev/null 2>&1
        if [ $? -eq 0 ];then
            mv ${thumb_file}.png $thumb_file
        else
            cp $MC_FILE_THUMB $thumb_file
        fi
        category_dir="${MC_DIR_TITLE_TS}/${category}"
        mkdir -p "$category_dir"
        i=00
        if [ -e "${category_dir}/${title}${i}.png" ];then
            for i in $(seq -w 1 99);do
                if [ ! -e "${category_dir}/${title}${i}.png" ];then
                    break
                fi
            done
        fi
        ln $thumb_file "${category_dir}/${title}${i}.png"

        mv ${MC_DIR_RECORD_FINISHED}/${job_file_xml} $MC_DIR_JOB_FINISHED
        bash $MC_BIN_SAFE_SHUTDOWN
    else
        log "failed: $job_file_xml"
        log "caused by: not in time now=$now start=$start"
        mv ${MC_DIR_RESERVED}/${job_file_xml} $MC_DIR_FAILED
    fi
fi
