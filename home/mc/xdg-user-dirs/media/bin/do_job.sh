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
        $rec
        mv ${MC_DIR_RECORDING}/${job_file_xml} $MC_DIR_RECORD_FINISHED
        echo b25 -v 0 ${MC_DIR_TS}/${job_file_ts} ${MC_DIR_TS}/${job_file_ts}.temp
        b25 -v 0 ${MC_DIR_TS}/${job_file_ts} ${MC_DIR_TS}/${job_file_ts}.temp
        mv -f ${MC_DIR_TS}/${job_file_ts}.temp ${MC_DIR_TS}/${job_file_ts}

        video_id=$(ffmpeg -i ${MC_DIR_TS}/${job_file_ts} 2>&1 | grep 'Video:' | grep h264 | tail -n 1 | awk -F '[' '{ print $1 }' | awk -F '#' '{ print $2 }')
        audio_id=$(ffmpeg -i ${MC_DIR_TS}/${job_file_ts} 2>&1 | grep 'Audio:' | awk -F ',' '{ print $5" "$1 }' | sort -n -k 1 | head -n 1 | awk -F '[' '{ print $1 }' | awk -F '#' '{ print $2 }')
        if [ -n "$video_id" -a -n "$audio_id" ];then
            map=" -map $video_id:0.0 -map $audio_id:0.1 "
            tmp1=${MC_DIR_MP4}/${job_file_base}_tmp_1.mp4
            tmp2=${MC_DIR_MP4}/${job_file_base}_tmp_2.mp4
            for i in 10 20 30;do
                echo ffmpeg -y -i ${MC_DIR_TS}/${job_file_ts} -f mp4 -copyts -ss $i -vcodec copy -acodec copy $map $tmp1
                ffmpeg -y -i ${MC_DIR_TS}/${job_file_ts} -f mp4 -copyts -ss $i -vcodec copy -acodec copy $map $tmp1 > /dev/null 2>&1
                if [ -s $tmp1 ];then
                    echo ffmpeg -y -i $tmp1 -f mp4 -vcodec copy -acodec libfaac $tmp2
                    ffmpeg -y -i $tmp1 -f mp4 -vcodec copy -acodec libfaac $tmp2 > /dev/null 2>&1
                    mv $tmp2 "${MC_DIR_MP4}/${title}.mp4"
                    break
                fi
            done
            rm -f $tmp1
            rm -f $tmp2
        fi

#         video_id=$(ffmpeg -i ${MC_DIR_TS}/${job_file_ts} 2>&1 | grep 'Video:' | grep mpeg2video | tail -n 1 | awk -F '[' '{ print $1 }' | awk -F '#' '{ print $2 }')
#         audio_id=$(ffmpeg -i ${MC_DIR_TS}/${job_file_ts} 2>&1 | grep 'Audio:' | awk -F ',' '{ print $5" "$1 }' | sort -n -k 1 | tail -n 1 | awk -F '[' '{ print $1 }' | awk -F '#' '{ print $2 }')
#         if [ -n "$video_id" -a -n "$audio_id" ];then
#             map=" -map $video_id:0.0 -map $audio_id:0.1 "
#             for i in 0 5 10;do
#                 ffmpeg -y -i ${MC_DIR_TS}/${job_file_ts} -copyts -ss $i -vcodec copy -acodec copy $map ${MC_DIR_TS}/${job_file_ts}.temp.ts > /dev/null 2>&1
#                 if [ $? -eq 0 ];then
#                     mv -f ${MC_DIR_TS}/${job_file_ts}.temp.ts ${MC_DIR_TS}/${job_file_ts}
#                     break
#                 fi
#             done
#             rm -f ${MC_DIR_TS}/${job_file_ts}.temp.ts
#         fi

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
