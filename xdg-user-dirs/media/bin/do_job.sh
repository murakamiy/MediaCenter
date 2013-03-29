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

        fifo_dir=/tmp/dvb-pt2/fifo
        mkdir -p $fifo_dir
        fifo_tail=${fifo_dir}/tail_$$
        mkfifo -m 644 $fifo_tail
        fifo_b25=${fifo_dir}/b25_$$
        mkfifo -m 644 $fifo_b25
        fifo_extend=${fifo_dir}/extend_$$
        mkfifo -m 644 $fifo_extend
        echo > $fifo_extend &

        today=$(date +%d)

        echo avconv -y -i $fifo_b25 -f mp4 \
            -s 640x360 \
            -loglevel quiet \
            -vsync 1 \
            -vcodec libx264 -acodec libvo_aacenc \
            -profile:v baseline -crf 30 -level 30 \
            -maxrate:v 10000k -r:a 44100 -b:a 64k \
            "${MC_DIR_MP4}/${today}_${title}.mp4"

        avconv -y -i $fifo_b25 -f mp4 \
            -s 640x360 \
            -loglevel quiet \
            -vsync 1 \
            -vcodec libx264 -acodec libvo_aacenc \
            -profile:v baseline -crf 30 -level 30 \
            -maxrate:v 10000k -r:a 44100 -b:a 64k \
            "${MC_DIR_MP4}/${today}_${title}.mp4" &

        pid_ffmpeg=$!
        b25 -v 0 $fifo_tail $fifo_b25 &
        pid_b25=$!
        touch ${MC_DIR_TS}/${job_file_ts}
        tail --follow --retry --sleep-interval=0.1 ${MC_DIR_TS}/${job_file_ts} > $fifo_tail &
        pid_tail=$!

        (
            sleep 120
            python ${MC_DIR_DB_RATING}/rating.py ${MC_DIR_RECORDING}/${job_file_xml}
            if [ $? -eq 0 ];then

                bs_cs=
                echo $channel | grep -q ^BS_
                if [ $? -eq 0 ];then
                    bs_cs='-b'
                fi
                echo $channel | grep -q ^CS_
                if [ $? -eq 0 ];then
                    bs_cs='-c'
                fi

                mod_time=($(python $MC_BIN_EPGDUMP $bs_cs -p $transport_stream_id:$service_id:$event_id -i ${MC_DIR_TS}/${job_file_ts}))

                if [ -n "${mod_time[1]}" ];then
                    if [ "${mod_time[1]}" -gt $end ];then
                        extend=$((${mod_time[1]} - $end)) 
                        log "rec time extended: $extend $job_file_xml $title"
                        echo $extend > $fifo_extend
                    fi
                fi
            fi
        ) &

        $MC_BIN_REC -e $fifo_extend $rec_channel $rec_time ${MC_DIR_TS}/${job_file_ts}

        mv ${MC_DIR_RECORDING}/${job_file_xml} $MC_DIR_RECORD_FINISHED

        sync
        sleep 20
        kill -TERM $pid_ffmpeg
        kill -TERM $pid_b25
        kill -TERM $pid_tail
        /bin/rm -f $fifo_tail
        /bin/rm -f $fifo_b25
        /bin/rm -f $fifo_extend

        lockfile-create /tmp/b25
        lockfile-touch /tmp/b25 &
        pid_lock=$!

        b25 -v 0 ${MC_DIR_TS}/${job_file_ts} ${MC_DIR_TS}/${job_file_ts}.b25

        kill -TERM $pid_lock
        lockfile-remove /tmp/b25

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
        category_dir="${MC_DIR_TITLE_TS}/${broadcasting}/${category}"
        mkdir -p "$category_dir"
        for i in $(seq -w 1 99);do
            if [ ! -e "${category_dir}/${title}_${i}.png" ];then
                break
            fi
        done
        ln $thumb_file "${category_dir}/${title}_${i}.png"

        (
            cd $MC_DIR_MP4
            echo smbclient -A ~/.smbauth -D contents -c "put ${today}_${title}.mp4" $MC_SMB_SERVER
            smbclient -A ~/.smbauth -D contents -c "put ${today}_${title}.mp4" $MC_SMB_SERVER
        )

        python ${MC_DIR_DB_RATING}/create.py ${MC_DIR_RECORD_FINISHED}/${job_file_xml} >> ${MC_DIR_DB_RATING}/log 2>&1

        mv ${MC_DIR_RECORD_FINISHED}/${job_file_xml} $MC_DIR_JOB_FINISHED
        bash $MC_BIN_SAFE_SHUTDOWN
    else
        log "failed: $job_file_xml"
        log "caused by: not in time now=$now start=$start"
        mv ${MC_DIR_RESERVED}/${job_file_xml} $MC_DIR_FAILED
    fi
fi
