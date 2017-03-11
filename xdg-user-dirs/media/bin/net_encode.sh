#!/bin/bash
source $(dirname $0)/00.conf

function gpu_encode() {
    time_limit=$1

    ip_addr_recive=$(nslookup MediaCenter | grep Address: | tail -n 1 | awk '{ print $2 }')
    ip_addr_send=$(nslookup EncodeServer | grep Address: | tail -n 1 | awk '{ print $2 }')
    volume_info_dir=${MC_DIR_TMP}/volume_info
    mkdir -p $volume_info_dir
    find $volume_info_dir -type f -delete

    xml_list=$(mktemp)
    find $MC_DIR_DOWNSIZE_ENCODE_RESERVED -type f -name '*.xml' | sort > $xml_list
    xml_count=$(cat $xml_list | wc -l)
    if [ ! $xml_count -gt 0 ];then
        return
    fi

    (
        for xml in $(cat $xml_list);do

            job_file_base=$(basename $xml .xml)
            job_file_ts=${job_file_base}.ts
            input_ts_file=${MC_DIR_TS}/${job_file_ts}

            max_volume=$(ffmpeg -i $input_ts_file -vn -af volumedetect -f null /dev/null 2>&1 |
            grep 'max_volume:' | awk -F 'max_volume:' '{ print $2 }' |
            awk '{ print $1 }' | sort -n | tail -n 1 |
            awk '{ if ($1 < 0) print $1 * -1; else print 0 }')
            echo $max_volume > ${volume_info_dir}/${job_file_ts}
        done
    ) &
    inotifywait -e create $volume_info_dir

    for xml in $(cat $xml_list);do

        job_file_base=$(basename $xml .xml)
        job_file_xml=${job_file_base}.xml
        job_file_ts=${job_file_base}.ts
        job_file_mkv=${job_file_base}.mkv
        job_file_mkv_abs=${MC_DIR_ENCODE_DOWNSIZE}/${job_file_mkv}
        input_ts_file=${MC_DIR_TS}/${job_file_ts}
        duration=$(ffprobe -show_format $input_ts_file 2> /dev/null | grep ^duration= | awk -F = '{ printf("%d\n", $2) }')
        title=$(print_title                                         ${MC_DIR_DOWNSIZE_ENCODE_RESERVED}/${job_file_xml})
        original_file=$(xmlsel -t -m //original-file -v .           ${MC_DIR_DOWNSIZE_ENCODE_RESERVED}/${job_file_xml})
        rec_time=$(xmlsel -t -m //rec-time -v .                     ${MC_DIR_DOWNSIZE_ENCODE_RESERVED}/${job_file_xml})
        foundby=$(xmlsel -t -m //foundby -v .                       ${MC_DIR_DOWNSIZE_ENCODE_RESERVED}/${job_file_xml} | sed -e 's/Finder//')
        filename_web=${title}_$(date +%m%d).mkv

        if [ -z "$duration" ];then
            /bin/mv ${MC_DIR_DOWNSIZE_ENCODE_RESERVED}/${job_file_xml} $MC_DIR_FAILED
            log "gpu_encode failed: $title $(hard_ware_info)"
            /bin/mv $xml $MC_DIR_FAILED
            continue
        fi

        time_start=$(awk 'BEGIN { print systime() }')
        estimated_time=$(( duration / 5 * 1 ))
        estimated_time_epoch=$(( time_start + estimated_time ))
        if [ $estimated_time_epoch -gt $time_limit ];then
            break
        fi

        /bin/mv $xml $MC_DIR_ENCODING_GPU

        ssh en@EncodeServer "bash ${EN_DIR_BIN}/kill_gpu_encoder.sh"

        ffmpeg -y -loglevel quiet -i async:tcp://${ip_addr_recive}:${MC_PORT_NO_GPU_RECIEVE}?listen -vcodec copy -acodec copy -f matroska $job_file_mkv_abs &
        pid_ffmpeg_recieve=$!

        if [ -f ${volume_info_dir}/${job_file_ts} ];then
            volume_adjust=$(cat ${volume_info_dir}/${job_file_ts})
        else
            volume_adjust=0
        fi

        scp ${MC_DIR_ENCODING_GPU}/${job_file_xml} en@${ip_addr_send}:${EN_DIR_XML}
        ssh en@${ip_addr_send} "echo exec bash ${EN_DIR_BIN}/gpu_encode.sh $job_file_xml $volume_adjust | at -M now"
        sleep 3

        gst-launch-1.0 -q \
          filesrc \
          location=${input_ts_file} \
          blocksize=499712000 \
        ! queue \
          silent=true \
          max-size-buffers=1 \
          max-size-bytes=0 \
          max-size-time=0 \
        ! tcpclientsink \
          host=${ip_addr_send} \
          port=${MC_PORT_NO_GPU_SEND} \
          blocksize=4096000 &
        pid_ffmpeg_send=$!

        (
            sleep $estimated_time
            kill -KILL $pid_ffmpeg_send > /dev/null 2>&1
            kill -KILL $pid_ffmpeg_recieve > /dev/null 2>&1
        ) &

        wait $pid_ffmpeg_send
        wait $pid_ffmpeg_recieve

        duration=0
        ffprobe -show_format $job_file_mkv_abs > /dev/null 2>&1
        if [ $? -eq 0 ];then
            duration=$(ffprobe -show_format $job_file_mkv_abs 2> /dev/null | grep ^duration= | awk -F = '{ printf("%d\n", $2) }')
        fi
        integrity=$(($rec_time - $duration))
        if [ "$integrity" -lt 180 ];then
            if [ "$original_file" = "release" ];then
                /bin/rm $input_ts_file
            fi

            mkvpropedit $job_file_mkv_abs --attachment-name record_description --add-attachment ${MC_DIR_ENCODING_GPU}/${job_file_xml}
            mkdir -p ${MC_DIR_WEBDAV_MC_CONTENTS}/${foundby}
            ln $job_file_mkv_abs "${MC_DIR_WEBDAV_MC_CONTENTS}/${foundby}/${filename_web}"

            /bin/rm ${MC_DIR_ENCODING_GPU}/${job_file_xml}

            time_end=$(awk 'BEGIN { print systime() }')
            (( took = (time_end - time_start) ))
            size=$(ls -sh $job_file_mkv_abs | awk '{ print $1 }')
            log "gpu_encode end: $took sec $size $title $(hard_ware_info)"
        else
            log "gpu_encode failed: $title $(hard_ware_info)"
            /bin/mv ${MC_DIR_ENCODING_GPU}/${job_file_xml} $MC_DIR_FAILED
        fi

    done
}

function cpu_encode() {
    time_limit=$1

    ip_addr_recive=$(nslookup MediaCenter | grep Address: | tail -n 1 | awk '{ print $2 }')
    ip_addr_send=$(nslookup EncodeServer | grep Address: | tail -n 1 | awk '{ print $2 }')

    for xml in $(find $MC_DIR_ENCODE_RESERVED -type f -name '*.xml' | sort);do

        job_file_base=$(basename $xml .xml)
        job_file_xml=${job_file_base}.xml
        job_file_ts=${job_file_base}.ts
        job_file_mkv=${job_file_base}.mkv
        job_file_mkv_abs=${MC_DIR_ENCODE}/${job_file_mkv}
        input_ts_file=${MC_DIR_TS}/${job_file_ts}
        duration=$(ffprobe -show_format $input_ts_file 2> /dev/null | grep ^duration= | awk -F = '{ printf("%d\n", $2) }')
        title=$(print_title                                         ${MC_DIR_ENCODE_RESERVED}/${job_file_xml})
        rec_time=$(xmlsel -t -m //rec-time -v .                     ${MC_DIR_ENCODE_RESERVED}/${job_file_xml})

        if [ -z "$duration" ];then
            /bin/mv ${MC_DIR_ENCODE_RESERVED}/${job_file_xml} $MC_DIR_FAILED
            log "cpu_encode failed: $title $(hard_ware_info)"
            continue
        fi

        time_start=$(awk 'BEGIN { print systime() }')
        estimated_time=$(( duration / 5 * 4 ))
        estimated_time_epoch=$(( time_start + estimated_time ))
        if [ $estimated_time_epoch -gt $time_limit ];then
            break
        fi

        /bin/mv $xml $MC_DIR_ENCODING_CPU

        ssh en@EncodeServer "bash ${EN_DIR_BIN}/kill_cpu_encoder.sh"

        ffmpeg -y -loglevel quiet -i async:tcp://${ip_addr_recive}:${MC_PORT_NO_CPU_RECIEVE}?listen -vcodec copy -acodec copy -f matroska $job_file_mkv_abs &
        pid_ffmpeg_recieve=$!

        ssh en@${ip_addr_send} "echo exec bash ${EN_DIR_BIN}/cpu_encode.sh | at -M now"
        sleep 3

        gst-launch-1.0 -q \
          filesrc \
          location=${input_ts_file} \
          blocksize=98304000 \
        ! queue \
          silent=true \
          max-size-buffers=1 \
          max-size-bytes=0 \
          max-size-time=0 \
        ! tcpclientsink \
          host=${ip_addr_send} \
          port=${MC_PORT_NO_CPU_SEND} \
          blocksize=4096000 &
        pid_ffmpeg_send=$!

        (
            sleep $estimated_time
            kill -KILL $pid_ffmpeg_send > /dev/null 2>&1
            kill -KILL $pid_ffmpeg_recieve > /dev/null 2>&1
        ) &

        wait $pid_ffmpeg_send
        wait $pid_ffmpeg_recieve

        duration=0
        ffprobe -show_format $job_file_mkv_abs > /dev/null 2>&1
        if [ $? -eq 0 ];then
            duration=$(ffprobe -show_format $job_file_mkv_abs 2> /dev/null | grep ^duration= | awk -F = '{ printf("%d\n", $2) }')
        fi
        integrity=$(($rec_time - $duration))
        if [ "$integrity" -lt 180 ];then

            mkvpropedit $job_file_mkv_abs --attachment-name record_description --add-attachment ${MC_DIR_ENCODING_CPU}/${job_file_xml}
            /bin/mv ${MC_DIR_ENCODING_CPU}/${job_file_xml} $MC_DIR_ENCODE_FINISHED

            time_end=$(awk 'BEGIN { print systime() }')
            (( took = (time_end - time_start) ))
            size=$(ls -sh $job_file_mkv_abs | awk '{ print $1 }')
            log "cpu_encode end: $took sec $size $title $(hard_ware_info)"
        else
            log "cpu_encode failed: $title $(hard_ware_info)"
            /bin/mv ${MC_DIR_ENCODING_CPU}/${job_file_xml} $MC_DIR_FAILED
        fi

    done
}

time_limit=$1
if [ -z "$time_limit" ];then
    echo "$0 TIME_LIMIT_EPOCH"
    exit
fi

python $MC_BIN_BLUETOOTH_WAKEUP
sleep 30
wol $(cat ~/.mac_address)
wake=false
for ((i = 0; i < 20; i++));do
    sleep 3
    ssh -o ConnectTimeout=1 en@EncodeServer ls > /dev/null 2>&1
    if [ $? -eq 0 ];then
        wake=true
        break
    fi
done

if [ "$wake" = "false" ];then
    log "encode server wakeup failed"
    exit
fi

ssh en@EncodeServer "bash ${EN_DIR_BIN}/init.sh"

(gpu_encode $time_limit) &
pid_gpu_encode=$!

(cpu_encode $time_limit) &
pid_cpu_encode=$!

wait $pid_gpu_encode
wait $pid_cpu_encode

ssh en@EncodeServer "echo exec bash ${EN_DIR_BIN}/shutdown.sh | at -M now"
bash $MC_BIN_SAFE_SHUTDOWN
