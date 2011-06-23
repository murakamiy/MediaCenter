#!/bin/bash
source $(dirname $0)/00.conf

job_file_base=$1
job_file_xml=${job_file_base}.xml
job_file_ts=${job_file_base}.ts

title=$(print_title ${MC_DIR_RESERVED}/${job_file_xml})
rec=$(xmlsel -t -m '//command' -m "rec" -v '.' ${MC_DIR_RESERVED}/${job_file_xml})
sleep_time=$(xmlsel -t -m '//sleep' -v '.' ${MC_DIR_RESERVED}/${job_file_xml})
start=$(xmlsel -t -m "//epoch[@type='start']" -v '.' ${MC_DIR_RESERVED}/${job_file_xml})
end=$(xmlsel -t -m "//epoch[@type='stop']" -v '.' ${MC_DIR_RESERVED}/${job_file_xml})
now=$(awk 'BEGIN { print systime() }')
((now = now - 30))

bash $MC_BIN_ENCODE $sleep_time &
running=$(find $MC_DIR_RECORDING -type f -name '*.xml' | wc -l)
if [ $running -ge 2 ];then
    log "failed: $job_file_xml"
    log "caused by: $(find $MC_DIR_RECORDING -type f -name '*.xml')"
    mv ${MC_DIR_RESERVED}/${job_file_xml} $MC_DIR_FAILED
else
    if [ $now -lt $start ];then
        log "start: $job_file_xml"
        mv ${MC_DIR_RESERVED}/${job_file_xml} $MC_DIR_RECORDING
        sudo lcdprint -s $start -e $end
        $rec
        mv ${MC_DIR_RECORDING}/${job_file_xml} $MC_DIR_RECORD_FINISHED
        b25 -v 0 ${MC_DIR_TS}/${job_file_ts} ${MC_DIR_TS}/${job_file_ts}.temp
        mv -f ${MC_DIR_TS}/${job_file_ts}.temp ${MC_DIR_TS}/${job_file_ts}

        video_id=$(ffmpeg -i ${MC_DIR_TS}/${job_file_ts} 2>&1 | grep 'Video:' | grep mpeg2video | tail -n 1 | awk -F '[' '{ print $1 }' | awk -F '#' '{ print $2 }')
        audio_id=$(ffmpeg -i ${MC_DIR_TS}/${job_file_ts} 2>&1 | grep 'Audio:' | awk -F ',' '{ print $5" "$1 }' | sort -n -k 1 | tail -n 1 | awk -F '[' '{ print $1 }' | awk -F '#' '{ print $2 }')
        if [ -n "$video_id" -a -n "$audio_id" ];then
            map=" -map $video_id:0.0 -map $audio_id:0.1 "
        fi
        for i in 0 5 10;do
            ffmpeg -y -i ${MC_DIR_TS}/${job_file_ts} -ss $i -vcodec copy -acodec copy $map ${MC_DIR_TS}/${job_file_ts}.temp.ts > /dev/null 2>&1
            if [ $? -eq 0 ];then
                mv -f ${MC_DIR_TS}/${job_file_ts}.temp.ts ${MC_DIR_TS}/${job_file_ts}
                break
            fi
        done
        rm -f ${MC_DIR_TS}/${job_file_ts}.temp.ts
        thumb_file=${MC_DIR_THUMB}/$(basename $job_file_ts .ts)
        ffmpeg -i ${MC_DIR_TS}/${job_file_ts} -f image2 -pix_fmt yuv420p -vframes 1 -ss 5 -s 320x180 -an -deinterlace ${thumb_file}.png > /dev/null 2>&1
        mv ${thumb_file}.png $thumb_file
        i=00
        if [ -e ${MC_DIR_TITLE_TS}/${title}${i}.png ];then
            for i in $(seq -w 1 99);do
                if [ ! -e ${MC_DIR_TITLE_TS}/${title}${i}.png ];then
                    break
                fi
            done
        fi
        ln $thumb_file ${MC_DIR_TITLE_TS}/${title}${i}.png
        sleep $sleep_time
        mv ${MC_DIR_RECORD_FINISHED}/${job_file_xml} $MC_DIR_JOB_FINISHED
        bash $MC_BIN_SAFE_SHUTDOWN
    else
        log "failed: $job_file_xml"
        log "caused by: not in time"
        mv ${MC_DIR_RESERVED}/${job_file_xml} $MC_DIR_FAILED
    fi
fi
